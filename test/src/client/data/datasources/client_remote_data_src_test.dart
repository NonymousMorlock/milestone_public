import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/src/client/data/datasources/client_remote_data_src.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/project/data/models/project_model.dart';

import '../../../../helpers/helpers.dart';

void main() {
  late ClientRemoteDataSrc remoteDataSrc;
  late MockFirebase firebase;
  late User currentUser;

  const fileImage =
      '/home/akundadababalei/StudioProjects/milestone/test'
      '/fixtures/project.png';

  setUp(() async {
    firebase = MockFirebase();
    await firebase.initStorage();
    await firebase.initAuth();
    await firebase.initFirestore();

    remoteDataSrc = ClientRemoteDataSrcImpl(
      firestore: firebase.firestore,
      storage: firebase.storage,
      auth: firebase.auth,
    );
    currentUser = firebase.auth.currentUser!;
  });

  Future<void> addProject(ProjectModel project) async {
    await firebase.firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('projects')
        .add(project.toMap());
  }

  Future<void> addProjectDoc({
    required String clientId,
    required String clientName,
    required String projectName,
  }) async {
    await firebase.firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('projects')
        .add({
          ...ProjectModel.empty().toMap(),
          'clientId': clientId,
          'clientName': clientName,
          'projectName': projectName,
        });
  }

  group('addClient', () {
    test('creates the user doc if it does not already exist', () async {
      var user = await firebase.firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      expect(user.exists, isFalse);

      await remoteDataSrc.addClient(ClientModel.empty());

      user = await firebase.firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      expect(user.exists, isTrue);
    });

    test('stores imageStoragePath for managed custom uploads', () async {
      final client = ClientModel.empty().copyWith(
        imageIsFile: true,
        image: fileImage,
      );

      final result = await remoteDataSrc.addClient(client);

      expect(result.imageStoragePath, isNotNull);
      expect(result.image, isNot(client.image));
    });

    test('reuses the reserved client id on repeated create attempts', () async {
      final client = ClientModel.empty().copyWith(id: 'reserved-client-id');

      final first = await remoteDataSrc.addClient(client);
      final second = await remoteDataSrc.addClient(client);

      final clients = await firebase.firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('clients')
          .get();

      expect(first.id, 'reserved-client-id');
      expect(second.id, 'reserved-client-id');
      expect(clients.docs, hasLength(1));
    });

    test('does not mutate users.totalEarned when creating a client', () async {
      await remoteDataSrc.addClient(
        ClientModel.empty().copyWith(totalSpent: 200),
      );

      final userData =
          (await firebase.firestore
                  .collection('users')
                  .doc(currentUser.uid)
                  .get())
              .data()!;

      expect(userData.containsKey('totalEarned'), isFalse);
    });
  });

  group('getClientById', () {
    test('returns the requested client when it exists', () async {
      final clientId = (await remoteDataSrc.addClient(ClientModel.empty())).id;

      final result = await remoteDataSrc.getClientById(clientId);

      expect(result.id, clientId);
    });

    test('throws a stable CLIENT_NOT_FOUND code for missing docs', () async {
      expect(
        () => remoteDataSrc.getClientById('missing-client'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.statusCode,
            'statusCode',
            'CLIENT_NOT_FOUND',
          ),
        ),
      );
    });
  });

  group('getClientProjectCounts', () {
    test('derives grouped counts from the current project set', () async {
      final firstClient = await remoteDataSrc.addClient(
        ClientModel.empty().copyWith(id: '', name: 'Acme'),
      );
      final secondClient = await remoteDataSrc.addClient(
        ClientModel.empty().copyWith(id: '', name: 'Studio'),
      );

      await addProjectDoc(
        clientId: firstClient.id,
        clientName: firstClient.name,
        projectName: 'Acme Website',
      );
      await addProjectDoc(
        clientId: firstClient.id,
        clientName: firstClient.name,
        projectName: 'Acme App',
      );
      await addProjectDoc(
        clientId: secondClient.id,
        clientName: secondClient.name,
        projectName: 'Studio Site',
      );

      final counts = await remoteDataSrc.getClientProjectCounts();

      expect(counts[firstClient.id], 2);
      expect(counts[secondClient.id], 1);
    });
  });

  group('editClient', () {
    test('does not rewrite totalSpent or dateCreated on edit', () async {
      final clientId = (await remoteDataSrc.addClient(ClientModel.empty())).id;
      final originalClient = await remoteDataSrc.getClientById(clientId);

      await remoteDataSrc.editClient(
        clientId: clientId,
        updatedClient: {
          'totalSpent': 999,
          'dateCreated': Timestamp.fromDate(DateTime.now()),
          'name': 'Renamed Client',
        },
      );

      final editedClient = await remoteDataSrc.getClientById(clientId);

      expect(editedClient.totalSpent, originalClient.totalSpent);
      expect(editedClient.dateCreated, originalClient.dateCreated);
      expect(editedClient.name, 'Renamed Client');
    });

    test('updates linked project clientName values during rename', () async {
      final client = await remoteDataSrc.addClient(
        ClientModel.empty().copyWith(name: 'Acme'),
      );
      await addProject(
        ProjectModel.empty().copyWith(
          clientId: client.id,
          clientName: client.name,
          projectName: 'Website',
        ),
      );

      await remoteDataSrc.editClient(
        clientId: client.id,
        updatedClient: {'name': 'Acme Studio'},
      );

      final projects = await firebase.firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('projects')
          .get();

      expect(projects.docs.single.data()['clientName'], 'Acme Studio');
    });
  });

  group('deleteClient', () {
    test('deletes the client doc when no linked projects exist', () async {
      final clientId = (await remoteDataSrc.addClient(ClientModel.empty())).id;

      await remoteDataSrc.deleteClient(clientId);

      final snapshot = await firebase.firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('clients')
          .doc(clientId)
          .get();
      expect(snapshot.exists, isFalse);
    });

    test('throws a stable linked-project conflict code', () async {
      final client = await remoteDataSrc.addClient(ClientModel.empty());
      await addProject(
        ProjectModel.empty().copyWith(
          clientId: client.id,
          clientName: client.name,
        ),
      );

      expect(
        () => remoteDataSrc.deleteClient(client.id),
        throwsA(
          isA<ServerException>().having(
            (e) => e.statusCode,
            'statusCode',
            'client-linked-projects-conflict',
          ),
        ),
      );
    });

    test(
      'delete still succeeds when avatar cleanup becomes best effort',
      () async {
        final client = await remoteDataSrc.addClient(
          ClientModel.empty().copyWith(
            image: 'https://example.com/avatar.png',
            imageIsFile: false,
          ),
        );

        await firebase.firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('clients')
            .doc(client.id)
            .update({
              'imageStoragePath':
                  'profile_avatars/clients/${currentUser.uid}/missing/avatar',
            });

        await remoteDataSrc.deleteClient(client.id);

        final snapshot = await firebase.firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('clients')
            .doc(client.id)
            .get();
        expect(snapshot.exists, isFalse);
      },
    );

    test('does not mutate users.totalEarned when deleting a client', () async {
      final client = await remoteDataSrc.addClient(
        ClientModel.empty().copyWith(totalSpent: 200),
      );

      await remoteDataSrc.deleteClient(client.id);

      final userData =
          (await firebase.firestore
                  .collection('users')
                  .doc(currentUser.uid)
                  .get())
              .data()!;

      expect(userData.containsKey('totalEarned'), isFalse);
    });
  });
}
