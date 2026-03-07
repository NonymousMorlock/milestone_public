import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/src/project/data/datasources/project_remote_data_src.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/data/models/u_r_l_model.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';

import '../../../../helpers/mock_firebase.dart';

void main() {
  late ProjectRemoteDataSrc remoteDataSrc;
  late MockFirebase firebase;

  late User tCurrentUser;

  setUp(() async {
    firebase = MockFirebase();
    await firebase.initAuth();
    await firebase.initFirestore();
    await firebase.initStorage();
    remoteDataSrc = ProjectRemoteDataSrcImpl(
      firestore: firebase.firestore,
      storage: firebase.storage,
      auth: firebase.auth,
    );
    await firebase.firestore.collection('users').add({});
    tCurrentUser = firebase.auth.currentUser!;
  });

  const tFileImage = '/home/akundadababalei/StudioProjects/milestone/test'
      '/fixtures/project.png';

  group('addProject', () {
    test(
      'should create the user doc in the firestore if it does not '
      'already exist',
      () async {
        var user = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .get();
        expect(user.exists, false);

        await remoteDataSrc.addProject(ProjectModel.empty());

        user = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .get();
        expect(user.exists, true);
      },
    );
    test(
      'should add project to the firestore and add the image if it is not null',
      () async {
        final tProject = ProjectModel.empty().copyWith(
          imageIsFile: true,
          image: tFileImage,
        );

        await remoteDataSrc.addProject(tProject);

        final projects = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .get();
        expect(projects.docs.isNotEmpty, true);
        final project = ProjectModel.fromMap(projects.docs.first.data());
        expect(project.clientId, equals(tProject.clientId));
        expect(project.id, isNot(tProject.id));
        expect(project.image, isNot(tProject.image));
        expect(project.images.isEmpty, true);
      },
    );
    test(
      'should add project to the firestore and add the images if it is not '
      'empty, and only upload images that are not already urls',
      () async {
        final tProject = ProjectModel.empty().copyWith(
          imagesModeRegistry: [true, false],
          images: [tFileImage, 'https://foo/image_url_test.png'],
        );

        await remoteDataSrc.addProject(tProject);

        final projects = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .get();
        expect(projects.docs.isNotEmpty, true);
        final project = ProjectModel.fromMap(projects.docs.first.data());
        expect(project.image, equals(tProject.image));
        expect(project.images.isNotEmpty, true);
        expect(project.images.first, isNot(tProject.images.first));
        expect(project.images.last, equals(tProject.images.last));
      },
    );
    test('should upload to the correct storage paths', () async {
      final tProject = ProjectModel.empty().copyWith(
        imageIsFile: true,
        image: tFileImage,
        imagesModeRegistry: [true],
        images: [tFileImage],
      );

      await remoteDataSrc.addProject(tProject);

      final projects = await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('projects')
          .get();
      expect(projects.docs.isNotEmpty, true);
      final project = ProjectModel.fromMap(projects.docs.first.data());
      expect(
        project.image,
        contains('projects/${tCurrentUser.uid}/${project.id}/'),
      );
      expect(
        project.images.first,
        contains(
          'projects/${tCurrentUser.uid}/${project.id}/images/',
        ),
      );
    });
  });

  group('editProjectDetails', () {
    test('should update the [Project] with the correct data', () async {
      await remoteDataSrc.addProject(
        ProjectModel.empty().copyWith(
          tools: ['Tool 1'],
          notes: ['Note 1'],
          imagesModeRegistry: [false],
          image: 'https://foo/image1.png',
          images: ['https://foo/image.png'],
        ),
      );
      final projects = await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('projects')
          .get();

      final project = ProjectModel.fromMap(projects.docs.first.data());

      const newProjectName = 'New project';
      const newClientName = 'New client name';
      const newShortDescription = 'New short description';
      const newBudget = 20.88;
      const newProjectType = 'Full-Stack';
      const newTotalPaid = 18.89;
      const newNumberOfMilestonesSoFar = 2;
      final newStartDate = DateTime.now();
      const newLongDescription = 'New long description';
      const newIsFixed = false;
      const newIsOneTime = false;
      final newDeadline = Timestamp.fromDate(DateTime.now());
      final newEndDate = Timestamp.fromDate(DateTime.now());

      await remoteDataSrc.editProjectDetails(
        projectId: project.id,
        updatedProject: {
          'tools': ['Tool 2', 'Tool 3'],
          'urls': const [
            URLModel(url: 'https://foo/url_1', title: 'First URL'),
            URLModel(url: 'https://foo/url_2', title: 'Second URL'),
          ],
          'image': 'https://foo/new_image.jpg',
          'images': [
            tFileImage,
          ],
          'imagesModeRegistry': [true],
          'projectName': newProjectName,
          'clientName': newClientName,
          'shortDescription': newShortDescription,
          'budget': newBudget,
          'projectType': newProjectType,
          'totalPaid': newTotalPaid,
          'numberOfMilestonesSoFar': newNumberOfMilestonesSoFar,
          'startDate': newStartDate,
          'longDescription': newLongDescription,
          'isFixed': newIsFixed,
          'isOneTime': newIsOneTime,
          'deadline': newDeadline,
          'endDate': newEndDate,
        },
      );

      final projectData = await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('projects')
          .doc(project.id)
          .get();

      final newProject = ProjectModel.fromMap(projectData.data()!);

      expect(project.image, isNot(newProject.image));
      expect(newProject.tools.length, equals(3));
      expect(newProject.urls.length, equals(2));
      expect(newProject.images.length, equals(2));
      expect(newProject.projectName, equals(newProjectName));
      expect(newProject.clientName, equals(newClientName));
      expect(newProject.shortDescription, equals(newShortDescription));
      expect(newProject.budget, equals(newBudget));
      expect(newProject.projectType, equals(newProjectType));
      // Here we expect the totalPaid to not change because we don't allow
      // direct editing of the totalPaid field, it can only be edited
      // programmatically when the right sources change
      expect(newProject.totalPaid, equals(project.totalPaid));
      expect(
        newProject.numberOfMilestonesSoFar,
        equals(newNumberOfMilestonesSoFar),
      );
      expect(newProject.startDate, equals(newStartDate));
      expect(newProject.longDescription, equals(newLongDescription));
      expect(newProject.isFixed, equals(newIsFixed));
      expect(newProject.isOneTime, equals(newIsOneTime));
      expect(newProject.deadline, equals(newDeadline.toDate()));
      expect(newProject.endDate, equals(newEndDate.toDate()));
    });
    test('should throw [ServerException] when error occurs', () async {
      final call = remoteDataSrc.editProjectDetails;
      expect(
        () => call(projectId: 'FailingId', updatedProject: {}),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getProjects', () {
    test("should get all projects in the current user's collection", () async {
      await remoteDataSrc.addProject(
        ProjectModel.empty().copyWith(projectName: 'Project 1'),
      );
      await remoteDataSrc.addProject(
        ProjectModel.empty().copyWith(projectName: 'Project 2'),
      );

      final projects = await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('projects')
          .get();

      expect(projects.docs, isNotEmpty);
      expect(projects.docs, hasLength(2));
      expect(
        projects.docs.where(
          (project) => project.data()['projectName'] == 'Project 1',
        ),
        isNotEmpty,
      );
      expect(
        projects.docs.where(
          (project) => project.data()['projectName'] == 'Project 2',
        ),
        isNotEmpty,
      );
    });
  });

  group('getProjectById', () {
    test('should get the right project', () async {
      await remoteDataSrc.addProject(
        ProjectModel.empty().copyWith(projectName: 'Project 1'),
      );
      await remoteDataSrc.addProject(ProjectModel.empty());

      final projects = await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('projects')
          .get()
          .then((snapshot) {
        return snapshot.docs
            .map(
              (projectDoc) => ProjectModel.fromMap(
                projectDoc.data(),
              ),
            )
            .toList();
      });

      expect(projects, hasLength(2));
      final tFilteredProject = projects.where(
        (project) => project.projectName == 'Project 1',
      );
      expect(tFilteredProject, hasLength(1));

      final tProject = tFilteredProject.first;

      // ACT
      final result = await remoteDataSrc.getProjectById(tProject.id);

      expect(result, equals(tProject));
    });
  });

  group('deleteProject', () {
    test(
      'should do a proper wipe of all relevant attached data to the project',
      () async {
        // check that all milestones were deleted
        // check that storage bucket @ projects/$currentUserId/$projectId
        // is clear

        // Arrange
        await remoteDataSrc.addProject(
          ProjectModel.empty().copyWith(
            imageIsFile: true,
            image: tFileImage,
            images: [tFileImage],
            imagesModeRegistry: [true],
          ),
        );

        final projectDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .get()
            .then((projectDocs) => projectDocs.docs.first);

        final project = ProjectModel.fromMap(projectDoc.data());

        var featureImageStore = await firebase.storage
            .ref()
            .child('projects/${tCurrentUser.uid}/${project.id}')
            .listAll();
        // print(await featureImageStore.items.first.getDownloadURL());
        expect(featureImageStore.items, isNotEmpty);

        var imagesStore = await firebase.storage
            .ref()
            .child('projects/${tCurrentUser.uid}/${project.id}/images')
            .listAll();
        // print(await imagesStore.items.first.getDownloadURL());
        expect(imagesStore.items, isNotEmpty);

        // ADD MILESTONE
        await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(project.id)
            .collection('milestones')
            .add(MilestoneModel.empty().toMap());

        var milestones = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(project.id)
            .collection('milestones')
            .get();

        expect(milestones.docs, isNotEmpty);

        // Act
        await remoteDataSrc.deleteProject(project.id);

        milestones = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(project.id)
            .collection('milestones')
            .get();

        expect(milestones.docs, isEmpty);

        featureImageStore = await firebase.storage
            .ref()
            .child('projects/${tCurrentUser.uid}/${project.id}')
            .listAll();
        // print(await featureImageStore.items.first.getDownloadURL());
        expect(featureImageStore.items, isEmpty);

        imagesStore = await firebase.storage
            .ref()
            .child('projects/${tCurrentUser.uid}/${project.id}/images')
            .listAll();
        // print(await imagesStore.items.first.getDownloadURL());
        expect(imagesStore.items, isEmpty);
      },
    );
  });
}
