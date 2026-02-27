import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/services/firebase_path_provider.dart';
import 'package:milestone/src/project/features/milestone/data/datasources/milestone_remote_data_src.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  late MockFirebase firebase;
  late MilestoneRemoteDataSrc remoteDataSrc;
  late FirebasePathProvider pathProvider;
  final tMilestone = MilestoneModel.empty();
  const tClientId = 'testClientId';
  late User tCurrentUser;

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
    await firebase.firestore.collection('users').doc(tCurrentUser.uid).set({
      'totalEarned': 0.0,
    });
    await firebase.firestore
        .collection('users')
        .doc(tCurrentUser.uid)
        .collection('projects')
        .doc(tMilestone.projectId)
        .set({'clientId': tClientId});
    await firebase.firestore
        .collection('users')
        .doc(tCurrentUser.uid)
        .collection('clients')
        .doc(tClientId)
        .set({});
  });

  tearDown(() async {
    await firebase.tearDown(deleteStorage: false);
  });

  group('addMilestone', () {
    test(
      'should add the milestone to the correct path',
      () async {
        await remoteDataSrc.addMilestone(tMilestone);

        final milestoneDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .collection('milestones')
            .get();

        expect(milestoneDoc.docs.length, 1);
        expect(milestoneDoc.docs.first.data()['id'], isNot(tMilestone.id));
      },
    );
    test(
      'should update [totalPaid, numberOfMilestonesSoFar and lastUpdated] '
      "fields on the milestone's project",
      () async {
        await remoteDataSrc.addMilestone(tMilestone);

        final projectDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .get();

        expect(projectDoc.data()!['totalPaid'], tMilestone.amountPaid);
        expect(projectDoc.data()!['numberOfMilestonesSoFar'], 1);
        expect(projectDoc.data()!['lastUpdated'], isA<Timestamp>());
      },
    );
    test(
      "should update the client's [totalSpent and lastUpdated] fields",
      () async {
        await remoteDataSrc.addMilestone(tMilestone);

        final clientDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('clients')
            .doc(tClientId)
            .get();

        expect(clientDoc.data()!['totalSpent'], tMilestone.amountPaid);
        expect(clientDoc.data()!['lastUpdated'], isA<Timestamp>());
      },
    );

    test(
        "should update totalEarned for the currentUser's document when "
        'adding a milestone', () async {
      // ARRANGE
      final tMilestone = MilestoneModel.empty();
      final initialTotalEarned = (await firebase.firestore
              .collection('users')
              .doc(tCurrentUser.uid)
              .get())
          .data()!['totalEarned'] as double;

      // ACT
      await remoteDataSrc.addMilestone(tMilestone);

      // ASSERT
      final updatedTotalEarned = (await firebase.firestore
              .collection('users')
              .doc(tCurrentUser.uid)
              .get())
          .data()!['totalEarned'];
      expect(updatedTotalEarned, greaterThan(initialTotalEarned));
    });
  });

  group('editMilestone', () {
    test(
      'should update the milestone at the correct path',
      () async {
        await remoteDataSrc.addMilestone(tMilestone);
        await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .update({'totalPaid': 10});

        final milestoneId = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .collection('milestones')
            .get()
            .then((value) => value.docs.first.id);

        await remoteDataSrc.editMilestone(
          projectId: tMilestone.projectId,
          milestoneId: milestoneId,
          updatedMilestone: {
            'title': 'New Title',
            'shortDescription': 'New Desc',
            'notes': ['New Note'],
            'amountPaid': 5,
          },
        );

        final milestoneDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .collection('milestones')
            .doc(milestoneId)
            .get();
        expect(milestoneDoc.data()!['title'], 'New Title');
        expect(milestoneDoc.data()!['shortDescription'], 'New Desc');
        expect(milestoneDoc.data()!['notes'], ['New Note']);
        expect(milestoneDoc.data()!['amountPaid'], 5);

        final projectDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .get();

        expect(projectDoc.data()!['lastUpdated'], isA<Timestamp>());
        expect(
          projectDoc.data()!['totalPaid'],
          equals(10 + (5 - tMilestone.amountPaid!)),
        );
      },
    );
    test(
      'should append notes instead of over-writing them',
      () async {
        await remoteDataSrc.addMilestone(
          tMilestone.copyWith(
            notes: ['Old Note'],
          ),
        );

        final milestones = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .collection('milestones')
            .get();
        final milestoneDoc = milestones.docs.first;

        await remoteDataSrc.editMilestone(
          projectId: tMilestone.projectId,
          milestoneId: milestoneDoc.id,
          updatedMilestone: {
            'notes': ['New Note'],
          },
        );

        final updatedMilestoneDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .collection('milestones')
            .doc(milestoneDoc.id)
            .get();

        expect(updatedMilestoneDoc.data()!['notes'], ['Old Note', 'New Note']);
      },
    );

    test(
        "should update totalEarned for the currentUser's document when "
        'editing a milestone', () async {
      // ARRANGE
      final tMilestone = MilestoneModel.empty();
      await remoteDataSrc.addMilestone(tMilestone);
      final initialTotalEarned = (await firebase.firestore
              .collection('users')
              .doc(tCurrentUser.uid)
              .get())
          .data()!['totalEarned'] as double;

      final milestoneDoc = await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('projects')
          .doc(tMilestone.projectId)
          .collection('milestones')
          .get()
          .then((value) => value.docs.first);

      // ACT
      await remoteDataSrc.editMilestone(
        projectId: tMilestone.projectId,
        milestoneId: milestoneDoc.id,
        updatedMilestone: {'amountPaid': 5},
      );

      // ASSERT
      final updatedTotalEarned = (await firebase.firestore
              .collection('users')
              .doc(tCurrentUser.uid)
              .get())
          .data()!['totalEarned'];
      expect(updatedTotalEarned, greaterThan(initialTotalEarned));
    });
  });

  group('getMilestones', () {
    test(
      'should return all milestones for the given project id',
      () async {
        for (var i = 0; i < 3; i++) {
          await remoteDataSrc.addMilestone(
            tMilestone.copyWith(id: '$i', title: 'Milestone $i'),
          );
        }

        final milestones = await remoteDataSrc.getMilestones(
          tMilestone.projectId,
        );
        expect(milestones.length, 3);
        expect(milestones.first.title, 'Milestone 0');

        expect(milestones.last.title, 'Milestone 2');
      },
    );
  });

  group('deleteMilestone', () {
    test(
      'should delete the milestone at the correct path',
      () async {
        await remoteDataSrc.addMilestone(tMilestone);
        final milestoneId = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .collection('milestones')
            .get()
            .then((value) => value.docs.first.id);

        await remoteDataSrc.deleteMilestone(
          projectId: tMilestone.projectId,
          milestoneId: milestoneId,
        );

        final milestoneDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .collection('milestones')
            .get();

        expect(milestoneDoc.docs.length, 0);
      },
    );
    test(
      'should update [totalPaid, numberOfMilestonesSoFar and lastUpdated] '
      "fields on the milestone's project",
      () async {
        await remoteDataSrc.addMilestone(tMilestone.copyWith(amountPaid: 10));
        var projectDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .get();

        expect(projectDoc.data()!['totalPaid'], 10);

        final milestoneId = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .collection('milestones')
            .get()
            .then((value) => value.docs.first.id);

        await remoteDataSrc.deleteMilestone(
          projectId: tMilestone.projectId,
          milestoneId: milestoneId,
        );

        projectDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .get();

        expect(projectDoc.data()!['totalPaid'], 0);
        expect(projectDoc.data()!['numberOfMilestonesSoFar'], 0);
        expect(projectDoc.data()!['lastUpdated'], isA<Timestamp>());
      },
    );
    test(
      "should update the client's [totalSpent and lastUpdated] fields",
      () async {
        await remoteDataSrc.addMilestone(tMilestone.copyWith(amountPaid: 10));
        var clientDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('clients')
            .doc(tClientId)
            .get();

        expect(clientDoc.data()!['totalSpent'], 10);

        final milestoneId = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .collection('milestones')
            .get()
            .then((value) => value.docs.first.id);

        await remoteDataSrc.deleteMilestone(
          projectId: tMilestone.projectId,
          milestoneId: milestoneId,
        );

        clientDoc = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('clients')
            .doc(tClientId)
            .get();

        expect(clientDoc.data()!['totalSpent'], 0);
        expect(clientDoc.data()!['lastUpdated'], isA<Timestamp>());
      },
    );

    test(
        "should update totalEarned for the currentUser's document when "
        'deleting a milestone', () async {
      // ARRANGE
      final tMilestone = MilestoneModel.empty();
      await remoteDataSrc.addMilestone(tMilestone.copyWith(amountPaid: 10));
      final initialTotalEarned = (await firebase.firestore
              .collection('users')
              .doc(tCurrentUser.uid)
              .get())
          .data()!['totalEarned'] as double;

      final milestoneDoc = await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('projects')
          .doc(tMilestone.projectId)
          .collection('milestones')
          .get()
          .then((value) => value.docs.first);

      // ACT
      await remoteDataSrc.deleteMilestone(
        projectId: tMilestone.projectId,
        milestoneId: milestoneDoc.id,
      );

      // ASSERT
      final updatedTotalEarned = (await firebase.firestore
              .collection('users')
              .doc(tCurrentUser.uid)
              .get())
          .data()!['totalEarned'];
      expect(updatedTotalEarned, lessThan(initialTotalEarned));
    });
  });

  group('getMilestoneById', () {
    test(
      'should return the milestone with the given id',
      () async {
        await remoteDataSrc.addMilestone(tMilestone);
        final milestoneId = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('projects')
            .doc(tMilestone.projectId)
            .collection('milestones')
            .get()
            .then((value) => value.docs.first.id);

        final milestone = await remoteDataSrc.getMilestoneById(
          projectId: tMilestone.projectId,
          milestoneId: milestoneId,
        );

        expect(milestone.id, milestoneId);
      },
    );
  });
}
