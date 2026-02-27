import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/client/data/datasources/client_remote_data_src.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/project/data/models/project_model.dart';

import '../../../../helpers/helpers.dart';

void main() {
  late ClientRemoteDataSrc remoteDataSrc;
  late MockFirebase firebase;

  late User tCurrentUser;

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
    await firebase.firestore.collection('users').add({});
    tCurrentUser = firebase.auth.currentUser!;
  });

  const tFileImage = '/home/akundadababalei/StudioProjects/milestone/test'
      '/fixtures/project.png';

  group('addClient', () {
    test(
      'should create the user doc in the firestore if it does not '
      'already exist',
      () async {
        var user = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .get();
        expect(user.exists, false);

        await remoteDataSrc.addClient(ClientModel.empty());

        user = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .get();
        expect(user.exists, true);
      },
    );

    test(
      'should add client to the firestore and add the image if it is not null',
      () async {
        final tClient = ClientModel.empty().copyWith(
          imageIsFile: true,
          image: tFileImage,
        );

        await remoteDataSrc.addClient(tClient);

        final clients = await firebase.firestore
            .collection('users')
            .doc(tCurrentUser.uid)
            .collection('clients')
            .get();
        expect(clients.docs.isNotEmpty, true);
        final client = ClientModel.fromMap(clients.docs.first.data());
        expect(client.id, isNot(tClient.id));
        expect(client.image, isNot(tClient.image));
      },
    );
    test('should upload to the correct storage paths', () async {
      final tClient = ClientModel.empty().copyWith(
        imageIsFile: true,
        image: tFileImage,
      );

      await remoteDataSrc.addClient(tClient);

      final clients = await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('clients')
          .get();
      expect(clients.docs.isNotEmpty, true);
      final client = ClientModel.fromMap(clients.docs.first.data());
      expect(
        client.image,
        contains('profile_avatars/clients/${tCurrentUser.uid}/${client.id}'),
      );
    });

    test(
        "should update totalEarned for the currentUser's document "
        'when adding a client', () async {
      // ARRANGE
      final tClient = ClientModel.empty();

      // ACT
      await remoteDataSrc.addClient(tClient);

      // ASSERT
      final updatedTotalEarned = (await firebase.firestore
              .collection('users')
              .doc(tCurrentUser.uid)
              .get())
          .data()!['totalEarned'];
      expect(updatedTotalEarned, equals(tClient.totalSpent));
    });
  });

  group('getClientById', () {
    test('should get the right client', () async {
      await remoteDataSrc.addClient(ClientModel.empty());
      final clientId = (await remoteDataSrc.addClient(ClientModel.empty())).id;

      final result = await remoteDataSrc.getClientById(clientId);
      expect(result.id, equals(clientId));
    });
  });

  group('editClient', () {
    // totalSpent, dateCreated and lastUpdated should never be updated
    // make sure the image is replaced
    // make sure the name is updated in every project if the name is being
    // changed
    // make sure lastUpdated has also been updated

    test(
      'should not update [totalSpent], [lastUpdated] and [dateCreated]',
      () async {
        final tClient = ClientModel.empty();
        final clientId = (await remoteDataSrc.addClient(tClient)).id;

        final originalClient = await remoteDataSrc.getClientById(clientId);
        final updatedDate = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 1)),
        );
        await remoteDataSrc.editClient(
          clientId: clientId,
          updatedClient: {
            'totalSpent': 200,
            'lastUpdated': updatedDate,
            'dateCreated': updatedDate,
            'image': tFileImage,
            'imageIsFile': true,
          },
        );

        final client = await remoteDataSrc.getClientById(clientId);
        expect(client.dateCreated, isNot(updatedDate));
        expect(client.totalSpent, isNot(200));
        expect(client.lastUpdated, isNot(updatedDate));

        expect(client.image, isNot(originalClient.image));
      },
    );
  });

  group('getClients', () {
    test('should get all clients added to the firestore', () async {
      final tClient = ClientModel.empty();
      for (var i = 0; i < 5; i++) {
        await remoteDataSrc.addClient(tClient.copyWith(name: i.toString()));
      }

      final clients = await remoteDataSrc.getClients();

      expect(clients, hasLength(5));
      expect(clients.last.name, equals('4'));
    });
  });

  Future<void> addProject(ProjectModel project) async {
    await firebase.firestore
        .collection('users')
        .doc(tCurrentUser.uid)
        .collection('projects')
        .add(project.toMap());
  }

  group('getClientProjects', () {
    setUpAll(() async {
      await firebase.firestore.collection('users').doc(tCurrentUser.uid).set({
        if (tCurrentUser.displayName != null)
          'userName': tCurrentUser.displayName,
        'email': tCurrentUser.email,
        'id': tCurrentUser.uid,
      });
    });
    test("should get all the client's projects", () async {
      // ARRANGE
      await remoteDataSrc.addClient(ClientModel.empty().copyWith(name: '1'));
      await remoteDataSrc.addClient(ClientModel.empty().copyWith(name: '2'));

      final clients = await remoteDataSrc.getClients();
      final firstClient = clients.firstWhere((client) => client.name == '1');
      final secondClient = clients.firstWhere((client) => client.name == '2');

      for (var i = 0; i < 2; i++) {
        await addProject(
          ProjectModel.empty().copyWith(
            clientId: firstClient.id,
            projectName: 'Client 1 Project ${i + 1}',
          ),
        );
      }
      for (var i = 0; i < 2; i++) {
        await addProject(
          ProjectModel.empty().copyWith(
            clientId: secondClient.id,
            projectName: 'Client 2 Project ${i + 1}',
          ),
        );
      }

      // ACT
      final result = await remoteDataSrc.getClientProjects(
        clientId: firstClient.id,
        detailed: true,
      );

      // ASSERT
      expect(result.length, equals(2));
      expect(
        result.every((project) => project.projectName.startsWith('Client 1')),
        isTrue,
      );
    });
  });

  group('deleteClient', () {
    test('should delete the [Client] from the firestore', () async {
      final clientId = (await remoteDataSrc.addClient(ClientModel.empty())).id;
      var clientDoc = await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('clients')
          .doc(clientId)
          .get();

      expect(clientDoc.exists, isTrue);

      await remoteDataSrc.deleteClient(clientId);

      clientDoc = await firebase.firestore
          .collection('users')
          .doc(tCurrentUser.uid)
          .collection('clients')
          .doc(clientId)
          .get();

      expect(clientDoc.exists, isFalse);
    });
    test(
      "should delete the client's image from the storage bucket if"
      ' one exists',
      () async {
        final tClient = ClientModel.empty().copyWith(
          imageIsFile: true,
          image: tFileImage,
        );

        final clientId = (await remoteDataSrc.addClient(tClient)).id;
        final client = await remoteDataSrc.getClientById(clientId);

        expect(client.image, isNot(tFileImage));
        var clientsProfileAvatars = await firebase.storage
            .ref()
            .child('profile_avatars/clients/${tCurrentUser.uid}')
            .listAll();

        expect(clientsProfileAvatars.items, isNotEmpty);

        await remoteDataSrc.deleteClient(clientId);

        clientsProfileAvatars = await firebase.storage
            .ref()
            .child('profile_avatars/clients/')
            .listAll();

        expect(clientsProfileAvatars.items, isEmpty);
      },
    );

    test(
        "should update totalEarned for the currentUser's document when "
        'deleting a client', () async {
      // ARRANGE
      final tClient = ClientModel.empty();
      final client = await remoteDataSrc.addClient(tClient);
      final initialTotalEarned = (await firebase.firestore
              .collection('users')
              .doc(tCurrentUser.uid)
              .get())
          .data()!['totalEarned'] as double;

      // ACT
      await remoteDataSrc.deleteClient(client.id);

      // ASSERT
      final updatedTotalEarned = (await firebase.firestore
              .collection('users')
              .doc(tCurrentUser.uid)
              .get())
          .data()!['totalEarned'];
      expect(updatedTotalEarned, lessThan(initialTotalEarned));
    });
  });
}
