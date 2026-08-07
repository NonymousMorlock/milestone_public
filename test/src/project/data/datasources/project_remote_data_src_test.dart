import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/src/project/data/datasources/project_remote_data_src.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_firebase.dart';

class MockProjectDeleteCallable extends Mock implements ProjectDeleteCallable {}

void main() {
  late ProjectRemoteDataSrc remoteDataSrc;
  late MockFirebase firebase;
  late MockProjectDeleteCallable projectDeleteCallable;
  late User tCurrentUser;

  setUp(() async {
    firebase = MockFirebase();
    await firebase.initAuth();
    await firebase.initFirestore();
    await firebase.initStorage();
    projectDeleteCallable = MockProjectDeleteCallable();
    remoteDataSrc = ProjectRemoteDataSrcImpl(
      firestore: firebase.firestore,
      storage: firebase.storage,
      auth: firebase.auth,
      projectDeleteCallable: projectDeleteCallable,
    );
    tCurrentUser = firebase.auth.currentUser!;
  });

  const tFileImage =
      '/home/akundadababalei/StudioProjects/milestone/test'
      '/fixtures/project.png';

  Future<ProjectModel> createStoredProject({
    ProjectModel? project,
  }) async {
    await remoteDataSrc.addProject(project ?? ProjectModel.empty());
    final snapshot = await firebase.firestore
        .collection('users')
        .doc(tCurrentUser.uid)
        .collection('projects')
        .get();
    return ProjectModel.fromMap(snapshot.docs.single.data());
  }

  group('addProject', () {
    test(
      'persists deletion state and storage manifests on new projects',
      () async {
        final storedProject = await createStoredProject(
          project: ProjectModel.empty().copyWith(
            imageIsFile: true,
            image: tFileImage,
            images: const [tFileImage],
            imagesModeRegistry: const [true],
          ),
        );

        final projectDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(storedProject.id)
            .get();
        final data = projectDoc.data()!;

        expect(data.containsKey('deletionRequestedAt'), isTrue);
        expect(storedProject.featureImageStoragePath, isNotNull);
        expect(storedProject.ownedStoragePaths, hasLength(2));
      },
    );
  });

  group('editProjectDetails', () {
    test('rejects stale edits when the project is pending deletion', () async {
      final storedProject = await createStoredProject();
      await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('projects')
          .doc(storedProject.id)
          .update({'deletionRequestedAt': Timestamp.now()});

      expect(
        () => remoteDataSrc.editProjectDetails(
          projectId: storedProject.id,
          updateData: const {'projectName': 'Updated'},
        ),
        throwsA(
          isA<ServerException>().having(
            (exception) => exception.statusCode,
            'statusCode',
            'project-delete-pending',
          ),
        ),
      );
    });

    test('maintains monotonic owned storage paths on update', () async {
      final storedProject = await createStoredProject(
        project: ProjectModel.empty().copyWith(
          imageIsFile: true,
          image: tFileImage,
        ),
      );

      await remoteDataSrc.editProjectDetails(
        projectId: storedProject.id,
        updateData: const {
          'projectName': 'Updated name',
          'image': 'https://example.com/external.png',
        },
      );

      final updated = await remoteDataSrc.getProjectById(storedProject.id);
      expect(updated.projectName, 'Updated name');
      expect(updated.featureImageStoragePath, isNull);
      expect(
        updated.ownedStoragePaths,
        contains(storedProject.featureImageStoragePath),
      );
    });
  });

  group('getProjects', () {
    test('supports bounded active-only project reads', () async {
      await createStoredProject(
        project: ProjectModel.empty().copyWith(projectName: 'Active'),
      );
      final pendingProjectRef = firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('projects')
          .doc('pending-project');
      await pendingProjectRef.set({
        ...ProjectModel.empty()
            .copyWith(
              id: 'pending-project',
              projectName: 'Pending',
              deletionRequestedAt: DateTime(2024, 1, 2),
            )
            .toMap(),
        'deletionRequestedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      });

      final result = await remoteDataSrc
          .getProjects(
            detailed: true,
            limit: 5,
            excludePendingDeletion: true,
          )
          .first;

      expect(result, hasLength(1));
      expect(result.single.projectName, 'Active');
    });
  });

  group('getProjectById', () {
    test('surfaces machine-readable not found identity', () async {
      expect(
        () => remoteDataSrc.getProjectById('missing-project'),
        throwsA(
          isA<ServerException>().having(
            (exception) => exception.statusCode,
            'statusCode',
            'PROJECT_NOT_FOUND',
          ),
        ),
      );
    });
  });

  group('deleteProject', () {
    test('treats completed callable handoff as success', () async {
      final storedProject = await createStoredProject();
      when(
        () => projectDeleteCallable.requestProjectDeletion(storedProject.id),
      ).thenAnswer(
        (_) async => const ProjectDeletionCallResult(status: 'completed'),
      );

      await remoteDataSrc.deleteProject(storedProject.id);

      verify(
        () => projectDeleteCallable.requestProjectDeletion(storedProject.id),
      ).called(1);
    });

    test(
      'surfaces pending-delete identity when callable returns pending',
      () async {
        final storedProject = await createStoredProject();
        when(
          () => projectDeleteCallable.requestProjectDeletion(storedProject.id),
        ).thenAnswer(
          (_) async => const ProjectDeletionCallResult(status: 'pending'),
        );

        expect(
          () => remoteDataSrc.deleteProject(storedProject.id),
          throwsA(
            isA<ServerException>().having(
              (exception) => exception.statusCode,
              'statusCode',
              'project-delete-pending',
            ),
          ),
        );
      },
    );

    test('probes live project state after callable failure', () async {
      final storedProject = await createStoredProject();
      await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('projects')
          .doc(storedProject.id)
          .update({'deletionRequestedAt': Timestamp.now()});
      when(
        () => projectDeleteCallable.requestProjectDeletion(storedProject.id),
      ).thenThrow(
        FirebaseFunctionsException(
          code: 'unavailable',
          message: 'temporary issue',
        ),
      );

      expect(
        () => remoteDataSrc.deleteProject(storedProject.id),
        throwsA(
          isA<ServerException>().having(
            (exception) => exception.statusCode,
            'statusCode',
            'project-delete-pending',
          ),
        ),
      );
    });
  });
}
