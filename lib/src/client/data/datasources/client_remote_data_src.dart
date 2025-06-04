import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/utils/constants/network_contants.dart';
import 'package:milestone/core/utils/network_utils.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/project/data/models/project_model.dart';

abstract class ClientRemoteDataSrc {
  Future<ClientModel> addClient(Client client);

  Future<void> editClient({
    required String clientId,
    required DataMap updatedClient,
  });

  // DELETE-CLIENT: Only work if client has no activity yet
  Future<void> deleteClient(String clientId);

  Future<ClientModel> getClientById(String clientId);

  Future<List<ClientModel>> getClients();

  Future<List<ProjectModel>> getClientProjects({
    required String clientId,
    required bool detailed,
  });
}

class ClientRemoteDataSrcImpl implements ClientRemoteDataSrc {
  const ClientRemoteDataSrcImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _storage = storage,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  @override
  Future<ClientModel> addClient(Client client) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final user = _auth.currentUser!;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        // we add user collection here because this is the first function that
        // will apparently run, after user opens app for the first time, if
        // they try to add a project, a client will have to be specified, and
        // in that scenario, we will save the client
        await _firestore.collection('users').doc(user.uid).set({
          if (user.displayName != null) 'userName': user.displayName,
          'email': user.email,
          'id': user.uid,
        });
      }
      final clientDoc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('clients')
          .doc();
      var clientModel = (client as ClientModel).copyWith(
        image: NetworkConstants.defaultAvatar,
        id: clientDoc.id,
      );

      if (client.image != null && client.imageIsFile) {
        final contentType = client.image!.split('.').last;
        final imageRef = _storage.ref().child(
              'profile_avatars/clients/${_auth.currentUser!.uid}/${clientDoc.id}',
            );
        await imageRef.putFile(
          File(client.image!),
          SettableMetadata(
            contentType: 'image/$contentType',
          ),
        );
        final imageUrl = await imageRef.getDownloadURL();
        clientModel = clientModel.copyWith(image: imageUrl);
      }

      await clientDoc.set(clientModel.toMap());
      // if the client already had a "totalSpent" set then we will add
      // that to the user's data
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDocData = (await userDocRef.get()).data();
      final totalSpent = (userDocData?['totalSpent'] as double?) ?? 0.0;
      await userDocRef.update({
        'totalEarned': totalSpent + (client.totalSpent),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return clientModel;
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<ClientModel>(
        e,
        repositoryName: 'ClientRemoteDataSrcImpl',
        methodName: 'addClient',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<ClientModel>(
        e,
        repositoryName: 'ClientRemoteDataSrcImpl',
        methodName: 'addClient',
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> editClient({
    required String clientId,
    required DataMap updatedClient,
  }) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      updatedClient
        ..remove('totalSpent')
        ..remove('dateCreated')
        ..remove('lastUpdated');
      if (updatedClient
          case {
            'image': final String image,
            'imageIsFile': true,
          }) {
        final contentType = image.split('.').last;
        final imageRef = _storage.ref().child(
              'profile_avatars/clients/${_auth.currentUser!.uid}/$clientId',
            );
        await imageRef.putFile(
          File(image),
          SettableMetadata(
            contentType: 'image/$contentType',
          ),
        );
        final imageUrl = await imageRef.getDownloadURL();
        updatedClient['image'] = imageUrl;
        updatedClient.remove('imageIsFile');
      }
      if (updatedClient case {'name': final String name}) {
        final clientProjects = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('projects')
            .where('clientId', isEqualTo: clientId)
            .get();

        final batch = _firestore.batch();
        for (final project in clientProjects.docs) {
          batch.update(project.reference, {
            'clientName': name,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('clients')
          .doc(clientId)
          .update({
        ...updatedClient,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      debugPrintStack(stackTrace: e.stackTrace);
      throw ServerException(
        message: e.message ?? 'Unknown Error Occurred',
        statusCode: e.code,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const ServerException(
        message: 'Something went wrong',
        statusCode: 'EDIT_CLIENT_UNK',
      );
    }
  }

  @override
  Future<void> deleteClient(String clientId) async {
    try {
      await NetworkUtils.authorizeUser(_auth);

      final clientProjects = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('projects')
          .where('clientId', isEqualTo: clientId)
          .get();
      if (clientProjects.docs.isNotEmpty) {
        throw const ServerException(
          message: 'There are projects connected to this client',
          statusCode: 'Conflict',
        );
      }
      await _storage
          .ref()
          .child('profile_avatars/clients/${_auth.currentUser!.uid}/$clientId')
          .delete();

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('clients')
          .doc(clientId)
          .delete();

      final userDocRef =
          _firestore.collection('users').doc(_auth.currentUser!.uid);
      final userDocData = (await userDocRef.get()).data();
      final totalSpent = (userDocData?['totalSpent'] as double?) ?? 0.0;
      await userDocRef.update({
        'totalEarned':
            totalSpent - (userDocData?['totalSpent'] as double? ?? 0.0),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      debugPrintStack(stackTrace: e.stackTrace);
      throw ServerException(
        message: e.message ?? 'Unknown Error Occurred',
        statusCode: e.code,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const ServerException(
        message: 'Something went wrong',
        statusCode: 'DELETE_CLIENT_UNK',
      );
    }
  }

  @override
  Future<ClientModel> getClientById(String clientId) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final clientDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('clients')
          .doc(clientId)
          .get();
      return ClientModel.fromMap(clientDoc.data()!);
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      debugPrintStack(stackTrace: e.stackTrace);
      throw ServerException(
        message: e.message ?? 'Unknown Error Occurred',
        statusCode: e.code,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const ServerException(
        message: 'Something went wrong',
        statusCode: 'CLIENT_DETAILS_UNK',
      );
    }
  }

  @override
  Future<List<ClientModel>> getClients() async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final clientsDocs = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('clients')
          .get();
      return clientsDocs.docs
          .map((doc) => ClientModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      debugPrintStack(stackTrace: e.stackTrace);
      throw ServerException(
        message: e.message ?? 'Unknown Error Occurred',
        statusCode: e.code,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const ServerException(
        message: 'Something went wrong',
        statusCode: 'CLIENTS_UNK',
      );
    }
  }

  @override
  Future<List<ProjectModel>> getClientProjects({
    required String clientId,
    required bool detailed,
  }) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final clientProjects = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('projects')
          .where('clientId', isEqualTo: clientId)
          .get();

      return clientProjects.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      debugPrintStack(stackTrace: e.stackTrace);
      throw ServerException(
        message: e.message ?? 'Unknown Error Occurred',
        statusCode: e.code,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const ServerException(
        message: 'Something went wrong',
        statusCode: 'CLIENT_PROJECTS_UNK',
      );
    }
  }
}
