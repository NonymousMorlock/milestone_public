import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/services/firebase_path_provider.dart';
import 'package:milestone/src/project/features/milestone/data/datasources/milestone_remote_data_src.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  late MockFirebase firebase;
  late MilestoneRemoteDataSrc remoteDataSrc;
  late FirebasePathProvider pathProvider;
  late User tCurrentUser;
  const tClientId = 'testClientId';
  final tMilestone = MilestoneModel.empty().copyWith(
    projectId: 'project-1',
    title: 'Discovery',
  );

  CollectionReference<Map<String, dynamic>> milestonesCollection() {
    return firebase.firestore
        .collection('users')
        .doc(tCurrentUser.uid)
        .collection('projects')
        .doc(tMilestone.projectId)
        .collection('milestones');
  }

  DocumentReference<Map<String, dynamic>> projectDoc() {
    return firebase.firestore
        .collection('users')
        .doc(tCurrentUser.uid)
        .collection('projects')
        .doc(tMilestone.projectId);
  }

  DocumentReference<Map<String, dynamic>> clientDoc() {
    return firebase.firestore
        .collection('users')
        .doc(tCurrentUser.uid)
        .collection('clients')
        .doc(tClientId);
  }

  DocumentReference<Map<String, dynamic>> userDoc() {
    return firebase.firestore.collection('users').doc(tCurrentUser.uid);
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>> firstMilestoneDoc() {
    return milestonesCollection().get().then((value) => value.docs.first);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  orderedMilestones() {
    return milestonesCollection()
        .orderBy('rank')
        .get()
        .then((value) => value.docs);
  }

  setUp(() async {
    firebase = MockFirebase();
    await Future.wait([firebase.initFirestore(), firebase.initAuth()]);
    tCurrentUser = firebase.auth.currentUser!;
    pathProvider = FirebasePathProvider(
      firestore: firebase.firestore,
      auth: firebase.auth,
    );
    remoteDataSrc = MilestoneRemoteDataSrcImpl(
      firestore: firebase.firestore,
      auth: firebase.auth,
      firebasePathProvider: pathProvider,
    );
    await userDoc().set({'totalEarned': 0.0});
    await projectDoc().set({
      'clientId': tClientId,
      'totalPaid': 0.0,
      'numberOfMilestonesSoFar': 0,
      'milestoneOrderVersion': 0,
    });
    await clientDoc().set({'totalSpent': 0.0});
  });

  tearDown(() async {
    await firebase.tearDown(deleteStorage: false);
  });

  group('addMilestone', () {
    test('should add the milestone to the correct path', () async {
      await remoteDataSrc.addMilestone(tMilestone);

      final milestoneDocs = await milestonesCollection().get();

      expect(milestoneDocs.docs, hasLength(1));
      expect(milestoneDocs.docs.first.data()['id'], isNot(tMilestone.id));
    });

    test(
      'should allocate sparse ranks and increment the order version',
      () async {
        await remoteDataSrc.addMilestone(
          tMilestone.copyWith(title: 'Discovery'),
        );
        await remoteDataSrc.addMilestone(tMilestone.copyWith(title: 'Build'));

        final orderedDocs = await orderedMilestones();
        final projectSnapshot = await projectDoc().get();

        expect(orderedDocs.map((doc) => doc.data()['rank']), [0.0, 1024.0]);
        expect(projectSnapshot.data()!['milestoneOrderVersion'], 2);
      },
    );

    test('should update rollups when a paid milestone is added', () async {
      await remoteDataSrc.addMilestone(tMilestone.copyWith(amountPaid: 250));

      final projectSnapshot = await projectDoc().get();
      final clientSnapshot = await clientDoc().get();
      final userSnapshot = await userDoc().get();

      expect(projectSnapshot.data()!['totalPaid'], 250);
      expect(projectSnapshot.data()!['numberOfMilestonesSoFar'], 1);
      expect(clientSnapshot.data()!['totalSpent'], 250);
      expect(userSnapshot.data()!['totalEarned'], 250);
    });

    test(
      'blocks milestone creation when the project is pending deletion',
      () async {
        await projectDoc().update({'deletionRequestedAt': Timestamp.now()});

        expect(
          () => remoteDataSrc.addMilestone(tMilestone),
          throwsA(
            isA<ServerException>().having(
              (exception) => exception.statusCode,
              'statusCode',
              'project-pending-delete',
            ),
          ),
        );
      },
    );
  });

  group('editMilestone', () {
    test('should replace notes instead of appending them', () async {
      await remoteDataSrc.addMilestone(
        tMilestone.copyWith(notes: const ['Old Note']),
      );

      final milestoneDoc = await firstMilestoneDoc();

      await remoteDataSrc.editMilestone(
        projectId: tMilestone.projectId,
        milestoneId: milestoneDoc.id,
        updatedMilestone: {
          'notes': ['New Note'],
        },
      );

      final updatedSnapshot = await milestonesCollection()
          .doc(milestoneDoc.id)
          .get();

      expect(updatedSnapshot.data()!['notes'], ['New Note']);
    });

    test('should clear amountPaid and decrement rollups', () async {
      await remoteDataSrc.addMilestone(
        tMilestone.copyWith(amountPaid: 200),
      );

      final milestoneDoc = await firstMilestoneDoc();

      await remoteDataSrc.editMilestone(
        projectId: tMilestone.projectId,
        milestoneId: milestoneDoc.id,
        updatedMilestone: {'amountPaid': null},
      );

      final milestoneSnapshot = await milestonesCollection()
          .doc(milestoneDoc.id)
          .get();
      final projectSnapshot = await projectDoc().get();
      final clientSnapshot = await clientDoc().get();
      final userSnapshot = await userDoc().get();

      expect(milestoneSnapshot.data()!['amountPaid'], isNull);
      expect(projectSnapshot.data()!['totalPaid'], 0);
      expect(clientSnapshot.data()!['totalSpent'], 0);
      expect(userSnapshot.data()!['totalEarned'], 0);
    });
  });

  group('getMilestones', () {
    test('should return the ordered collection snapshot and version', () async {
      for (var i = 0; i < 3; i++) {
        await remoteDataSrc.addMilestone(
          tMilestone.copyWith(title: 'Milestone $i'),
        );
      }

      final snapshot = await remoteDataSrc.getMilestones(tMilestone.projectId);

      expect(snapshot.milestones, hasLength(3));
      expect(snapshot.milestones.first.title, 'Milestone 0');
      expect(snapshot.milestones.last.title, 'Milestone 2');
      expect(snapshot.orderVersion, 3);
    });
  });

  group('reorderMilestone', () {
    test(
      'should write a midpoint rank and increment the order version',
      () async {
        await remoteDataSrc.addMilestone(
          tMilestone.copyWith(title: 'Discovery'),
        );
        await remoteDataSrc.addMilestone(tMilestone.copyWith(title: 'Build'));
        await remoteDataSrc.addMilestone(tMilestone.copyWith(title: 'Launch'));

        final originalDocs = await orderedMilestones();
        final discoveryDoc = originalDocs[0];
        final buildDoc = originalDocs[1];
        final launchDoc = originalDocs[2];

        await remoteDataSrc.reorderMilestone(
          projectId: tMilestone.projectId,
          milestoneId: launchDoc.id,
          previousMilestoneId: discoveryDoc.id,
          nextMilestoneId: buildDoc.id,
          expectedOrderVersion: 3,
        );

        final reorderedDocs = await orderedMilestones();
        final projectSnapshot = await projectDoc().get();

        expect(
          reorderedDocs.map((doc) => doc.data()['title'] as String).toList(),
          ['Discovery', 'Launch', 'Build'],
        );
        expect(reorderedDocs[1].data()['rank'], 512.0);
        expect(projectSnapshot.data()!['milestoneOrderVersion'], 4);
      },
    );

    test(
      'should rebalance deterministically when direct placement is unsafe',
      () async {
        await milestonesCollection().doc('milestone-1').set({
          ...tMilestone
              .copyWith(id: 'milestone-1', title: 'Alpha', rank: 0)
              .toMap(),
          'dateCreated': Timestamp.fromDate(DateTime(2024)),
          'lastUpdated': Timestamp.fromDate(DateTime(2024)),
        });
        await milestonesCollection().doc('milestone-2').set({
          ...tMilestone
              .copyWith(id: 'milestone-2', title: 'Beta', rank: 0.5)
              .toMap(),
          'dateCreated': Timestamp.fromDate(DateTime(2024, 1, 2)),
          'lastUpdated': Timestamp.fromDate(DateTime(2024, 1, 2)),
        });
        await milestonesCollection().doc('milestone-3').set({
          ...tMilestone
              .copyWith(id: 'milestone-3', title: 'Gamma', rank: 1)
              .toMap(),
          'dateCreated': Timestamp.fromDate(DateTime(2024, 1, 3)),
          'lastUpdated': Timestamp.fromDate(DateTime(2024, 1, 3)),
        });

        await remoteDataSrc.reorderMilestone(
          projectId: tMilestone.projectId,
          milestoneId: 'milestone-3',
          previousMilestoneId: 'milestone-1',
          nextMilestoneId: 'milestone-2',
          expectedOrderVersion: 0,
        );

        final reorderedDocs = await orderedMilestones();
        final projectSnapshot = await projectDoc().get();

        expect(
          reorderedDocs.map((doc) => doc.data()['title'] as String).toList(),
          ['Alpha', 'Gamma', 'Beta'],
        );
        expect(
          reorderedDocs.map((doc) => doc.data()['rank']).toList(),
          [0.0, 1024.0, 2048.0],
        );
        expect(projectSnapshot.data()!['milestoneOrderVersion'], 1);
        expect(
          projectSnapshot.data()!['milestoneOrderLastRebalancedAt'],
          isNotNull,
        );
      },
    );

    test('should reject stale expectedOrderVersion', () async {
      await remoteDataSrc.addMilestone(tMilestone.copyWith(title: 'Discovery'));
      await remoteDataSrc.addMilestone(tMilestone.copyWith(title: 'Build'));

      final docs = await orderedMilestones();

      expect(
        () => remoteDataSrc.reorderMilestone(
          projectId: tMilestone.projectId,
          milestoneId: docs[1].id,
          previousMilestoneId: null,
          nextMilestoneId: docs[0].id,
          expectedOrderVersion: 1,
        ),
        throwsA(
          isA<ServerException>().having(
            (exception) => exception.statusCode,
            'statusCode',
            'milestone-order-stale',
          ),
        ),
      );
    });

    test('should reject reversed anchors as invalid targets', () async {
      await remoteDataSrc.addMilestone(tMilestone.copyWith(title: 'Discovery'));
      await remoteDataSrc.addMilestone(tMilestone.copyWith(title: 'Build'));
      await remoteDataSrc.addMilestone(tMilestone.copyWith(title: 'Launch'));

      final docs = await orderedMilestones();

      expect(
        () => remoteDataSrc.reorderMilestone(
          projectId: tMilestone.projectId,
          milestoneId: docs[1].id,
          previousMilestoneId: docs[2].id,
          nextMilestoneId: docs[0].id,
          expectedOrderVersion: 3,
        ),
        throwsA(
          isA<ServerException>().having(
            (exception) => exception.statusCode,
            'statusCode',
            'milestone-order-invalid-target',
          ),
        ),
      );
    });

    test(
      'should never persist transient anchor metadata on milestone docs',
      () async {
        await remoteDataSrc.addMilestone(
          tMilestone.copyWith(title: 'Discovery'),
        );
        await remoteDataSrc.addMilestone(tMilestone.copyWith(title: 'Build'));
        await remoteDataSrc.addMilestone(tMilestone.copyWith(title: 'Launch'));

        final originalDocs = await orderedMilestones();

        await remoteDataSrc.reorderMilestone(
          projectId: tMilestone.projectId,
          milestoneId: originalDocs[2].id,
          previousMilestoneId: originalDocs[0].id,
          nextMilestoneId: originalDocs[1].id,
          expectedOrderVersion: 3,
        );

        final reorderedDocs = await orderedMilestones();

        expect(
          reorderedDocs.every(
            (doc) =>
                !doc.data().containsKey('previousMilestoneId') &&
                !doc.data().containsKey('nextMilestoneId'),
          ),
          isTrue,
        );
      },
    );
  });

  group('deleteMilestone', () {
    test(
      'should delete the milestone, decrement rollups, and bump order version',
      () async {
        await remoteDataSrc.addMilestone(
          tMilestone.copyWith(amountPaid: 10),
        );
        final milestoneDoc = await firstMilestoneDoc();

        await remoteDataSrc.deleteMilestone(
          projectId: tMilestone.projectId,
          milestoneId: milestoneDoc.id,
        );

        final milestoneDocs = await milestonesCollection().get();
        final projectSnapshot = await projectDoc().get();
        final clientSnapshot = await clientDoc().get();
        final userSnapshot = await userDoc().get();

        expect(milestoneDocs.docs, isEmpty);
        expect(projectSnapshot.data()!['totalPaid'], 0);
        expect(projectSnapshot.data()!['numberOfMilestonesSoFar'], 0);
        expect(projectSnapshot.data()!['milestoneOrderVersion'], 2);
        expect(clientSnapshot.data()!['totalSpent'], 0);
        expect(userSnapshot.data()!['totalEarned'], 0);
      },
    );
  });
}
