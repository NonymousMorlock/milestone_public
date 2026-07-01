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
import 'package:uuid/uuid.dart';

abstract interface class ClientRemoteDataSrc {
  Future<ClientModel> addClient(Client client);

  Future<void> editClient({
    required String clientId,
    required DataMap updatedClient,
  });

  // DELETE-CLIENT: Only work if client has no activity yet
  Future<void> deleteClient(String clientId);

  Future<ClientModel> getClientById(String clientId);

  Future<List<ClientModel>> getClients();

  Future<Map<String, int>> getClientProjectCounts();

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
  }) : _firestore = firestore,
       _storage = storage,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  static const _uuid = Uuid();

  @override
  Future<ClientModel> addClient(Client client) async {
    String? uploadedAvatarPath;
    try {
      await NetworkUtils.authorizeUser(_auth);
      await _ensureUserDocExists();

      final incomingClient = client as ClientModel;
      final clientId = incomingClient.id.isEmpty
          ? _userClientsCollection().doc().id
          : incomingClient.id;
      final clientDoc = _userClientsCollection().doc(clientId);
      final existingSnapshot = await clientDoc.get();
      if (existingSnapshot.exists && existingSnapshot.data() != null) {
        return ClientModel.fromMap(existingSnapshot.data()!);
      }

      var clientModel = incomingClient.copyWith(
        id: clientId,
        image: incomingClient.image ?? NetworkConstants.defaultAvatar,
      );

      if (client.image != null && client.imageIsFile) {
        final upload = await _uploadClientAvatarVersion(
          clientId: clientId,
          localFilePath: client.image!,
        );
        uploadedAvatarPath = upload.storagePath;
        clientModel = clientModel.copyWith(
          image: upload.downloadUrl,
          imageStoragePath: upload.storagePath,
        );
      }

      await clientDoc.set(clientModel.toMap());
      return clientModel;
    } on FirebaseException catch (e) {
      await _cleanupClientAvatarBestEffort(uploadedAvatarPath);
      return NetworkUtils.handleRemoteSourceException<ClientModel>(
        e,
        repositoryName: 'ClientRemoteDataSrcImpl',
        methodName: 'addClient',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      await _cleanupClientAvatarBestEffort(uploadedAvatarPath);
      rethrow;
    } on Exception catch (e, s) {
      await _cleanupClientAvatarBestEffort(uploadedAvatarPath);
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
    final mutableUpdateData = Map<String, dynamic>.from(updatedClient);
    String? uploadedAvatarPath;
    try {
      await NetworkUtils.authorizeUser(_auth);
      mutableUpdateData
        ..remove('totalSpent')
        ..remove('dateCreated')
        ..remove('lastUpdated')
        ..remove('id');

      final clientRef = _userClientsCollection().doc(clientId);
      final currentSnapshot = await clientRef.get();
      if (!currentSnapshot.exists || currentSnapshot.data() == null) {
        throw const ServerException(
          message: 'Client not found',
          statusCode: _kClientNotFoundCode,
        );
      }

      final currentClient = ClientModel.fromMap(currentSnapshot.data()!);
      QuerySnapshot<DataMap>? linkedProjects;
      if (mutableUpdateData case {'name': final String _}) {
        linkedProjects = await _userProjectsCollection()
            .where('clientId', isEqualTo: clientId)
            .get();
        if (linkedProjects.docs.length > _kMaxRenamePropagationProjects) {
          throw const ServerException(
            message:
                'This client is linked to too many projects to rename safely '
                'from this device.',
            statusCode: _kClientRenameFanoutTooLargeCode,
          );
        }
      }

      if (mutableUpdateData case {
        'image': final String image,
        'imageIsFile': true,
      }) {
        final upload = await _uploadClientAvatarVersion(
          clientId: clientId,
          localFilePath: image,
        );
        uploadedAvatarPath = upload.storagePath;
        mutableUpdateData['image'] = upload.downloadUrl;
        mutableUpdateData['imageStoragePath'] = upload.storagePath;
        mutableUpdateData.remove('imageIsFile');
      } else if (mutableUpdateData case {'image': final String image}) {
        mutableUpdateData['imageStoragePath'] =
            _legacyClientAvatarStoragePathFromUrl(image);
        mutableUpdateData.remove('imageIsFile');
      } else if (mutableUpdateData.containsKey('image')) {
        mutableUpdateData['imageStoragePath'] = null;
        mutableUpdateData.remove('imageIsFile');
      }

      final batch = _firestore.batch()
        ..update(clientRef, {
          ...mutableUpdateData,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

      if (linkedProjects != null) {
        final name = mutableUpdateData['name'];
        if (name is String) {
          for (final project in linkedProjects.docs) {
            batch.update(project.reference, {
              'clientName': name,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      await batch.commit();

      final previousAvatarPath =
          currentClient.imageStoragePath ??
          _legacyClientAvatarStoragePathFromUrl(currentClient.image);
      final nextAvatarPath = mutableUpdateData.containsKey('imageStoragePath')
          ? mutableUpdateData['imageStoragePath'] as String?
          : previousAvatarPath;
      if (previousAvatarPath != null && previousAvatarPath != nextAvatarPath) {
        await _cleanupClientAvatarBestEffort(previousAvatarPath);
      }
    } on FirebaseException catch (e) {
      await _cleanupClientAvatarBestEffort(uploadedAvatarPath);
      debugPrint(e.message);
      debugPrintStack(stackTrace: e.stackTrace);
      throw ServerException(
        message: e.message ?? 'Unknown Error Occurred',
        statusCode: e.code,
      );
    } on ServerException {
      await _cleanupClientAvatarBestEffort(uploadedAvatarPath);
      rethrow;
    } on Exception catch (e, s) {
      await _cleanupClientAvatarBestEffort(uploadedAvatarPath);
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

      final clientRef = _userClientsCollection().doc(clientId);
      final clientSnapshot = await clientRef.get();
      if (!clientSnapshot.exists || clientSnapshot.data() == null) {
        throw const ServerException(
          message: 'Client not found',
          statusCode: _kClientNotFoundCode,
        );
      }

      final clientProjects = await _userProjectsCollection()
          .where('clientId', isEqualTo: clientId)
          .get();
      if (clientProjects.docs.isNotEmpty) {
        throw const ServerException(
          message:
              'Move or delete linked projects before deleting this client.',
          statusCode: _kClientLinkedProjectsConflictCode,
        );
      }

      final client = ClientModel.fromMap(clientSnapshot.data()!);
      final avatarPath =
          client.imageStoragePath ??
          _legacyClientAvatarStoragePathFromUrl(client.image);

      await clientRef.delete();
      await _cleanupClientAvatarBestEffort(avatarPath);
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
      final clientDoc = await _userClientsCollection().doc(clientId).get();
      if (!clientDoc.exists || clientDoc.data() == null) {
        throw const ServerException(
          message: 'Client not found',
          statusCode: _kClientNotFoundCode,
        );
      }
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
      final clientsDocs = await _userClientsCollection().get();
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
  Future<Map<String, int>> getClientProjectCounts() async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final projects = await _userProjectsCollection().get();
      final counts = <String, int>{};
      for (final doc in projects.docs) {
        final clientId = doc.data()['clientId'] as String?;
        if (clientId == null || clientId.isEmpty) {
          continue;
        }
        counts[clientId] = (counts[clientId] ?? 0) + 1;
      }
      return counts;
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
        statusCode: 'CLIENT_PROJECT_COUNTS_UNK',
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
      final clientProjects = await _userProjectsCollection()
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

  CollectionReference<DataMap> _userClientsCollection() {
    return _userDoc().collection('clients');
  }

  DocumentReference<DataMap> _userDoc() {
    return _firestore.collection('users').doc(_auth.currentUser!.uid);
  }

  CollectionReference<DataMap> _userProjectsCollection() {
    return _userDoc().collection('projects');
  }

  Future<void> _ensureUserDocExists() async {
    final user = _auth.currentUser!;
    final userDoc = await _userDoc().get();
    if (userDoc.exists) {
      return;
    }

    await _userDoc().set({
      if (user.displayName != null) 'userName': user.displayName,
      'email': user.email,
      'id': user.uid,
    });
  }

  Future<({String downloadUrl, String storagePath})>
  _uploadClientAvatarVersion({
    required String clientId,
    required String localFilePath,
  }) async {
    final contentType = localFilePath.split('.').last;
    final imageRef = _storage.ref().child(
      'profile_avatars/clients/${_auth.currentUser!.uid}/$clientId/'
      '${_uuid.v1()}',
    );
    final task = await imageRef.putFile(
      File(localFilePath),
      SettableMetadata(contentType: 'image/$contentType'),
    );
    return (
      downloadUrl: await task.ref.getDownloadURL(),
      storagePath: task.ref.fullPath,
    );
  }

  Future<void> _cleanupClientAvatarBestEffort(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) {
      return;
    }

    try {
      final normalizedPath = storagePath.startsWith('/')
          ? storagePath.substring(1)
          : storagePath;
      await _storage.ref().child(normalizedPath).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return;
      }
      debugPrint(e.message);
      debugPrintStack(stackTrace: e.stackTrace);
    } on Exception catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
    }
  }

  ({String? bucket, String? path}) _parseStorageUrl(String url) {
    if (url.startsWith('gs://')) {
      final withoutScheme = url.substring(5);
      final slashIndex = withoutScheme.indexOf('/');
      if (slashIndex == -1) {
        return (bucket: withoutScheme, path: null);
      }
      return (
        bucket: withoutScheme.substring(0, slashIndex),
        path: withoutScheme.substring(slashIndex + 1),
      );
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return (bucket: null, path: null);
    }

    if (uri.host.contains('firebasestorage.googleapis.com')) {
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('b');
      final objectIndex = segments.indexOf('o');
      if (bucketIndex == -1 || objectIndex == -1) {
        return (bucket: null, path: null);
      }
      if (bucketIndex + 1 >= segments.length ||
          objectIndex + 1 >= segments.length) {
        return (bucket: null, path: null);
      }
      final bucket = segments[bucketIndex + 1];
      final encodedPath = segments.sublist(objectIndex + 1).join('/');
      return (bucket: bucket, path: Uri.decodeFull(encodedPath));
    }

    if (uri.host.contains('storage.googleapis.com') ||
        uri.host.contains('storage.cloud.google.com')) {
      final segments = uri.pathSegments;
      if (segments.isEmpty) {
        return (bucket: null, path: null);
      }

      final bucket = segments.first;
      final path = segments.length > 1
          ? Uri.decodeFull(segments.sublist(1).join('/'))
          : null;
      return (bucket: bucket, path: path);
    }

    return (bucket: null, path: null);
  }

  String? _legacyClientAvatarStoragePathFromUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    final parsed = _parseStorageUrl(imageUrl);
    final path = parsed.path;
    final prefix = 'profile_avatars/clients/${_auth.currentUser!.uid}/';
    if (parsed.bucket != _storage.bucket || path == null) {
      return null;
    }

    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    if (!normalizedPath.startsWith(prefix)) {
      return null;
    }
    return normalizedPath;
  }
}

const _kClientNotFoundCode = 'CLIENT_NOT_FOUND';
const _kClientLinkedProjectsConflictCode = 'client-linked-projects-conflict';
const _kClientRenameFanoutTooLargeCode = 'client-rename-fanout-too-large';
const _kMaxRenamePropagationProjects = 400;
