import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/utils/network_utils.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/data/models/u_r_l_model.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/entities/u_r_l.dart';
import 'package:uuid/uuid.dart';

const _kRequestProjectDeletionCallable = 'requestProjectDeletion';
const _kProjectDeletePendingCode = 'project-delete-pending';
const _kProjectNotFoundCode = 'PROJECT_NOT_FOUND';

typedef _UploadedFeatureImage = ({String downloadUrl, String storagePath});
typedef _UploadedGalleryImages = ({
  List<String> resolvedImages,
  List<String> uploadedStoragePaths,
});

class ProjectDeletionCallResult {
  const ProjectDeletionCallResult({required this.status});

  factory ProjectDeletionCallResult.fromMap(DataMap map) {
    return ProjectDeletionCallResult(
      status: (map['status'] as String?) ?? 'pending',
    );
  }

  final String status;

  bool get isCompleted => status == 'completed';
}

// This interface is intentionally kept at the domain boundary even with one method so the data layer can remain replaceable/testable
// ignore: one_member_abstracts
abstract interface class ProjectDeleteCallable {
  Future<ProjectDeletionCallResult> requestProjectDeletion(String projectId);
}

class FirebaseProjectDeleteCallable implements ProjectDeleteCallable {
  FirebaseProjectDeleteCallable({required FirebaseFunctions functions})
    : _callable = functions.httpsCallable(_kRequestProjectDeletionCallable);

  final HttpsCallable _callable;

  @override
  Future<ProjectDeletionCallResult> requestProjectDeletion(
    String projectId,
  ) async {
    final result = await _callable.call<DataMap>({
      'projectId': projectId,
    });
    final data = result.data;
    return ProjectDeletionCallResult.fromMap(data);
  }
}

abstract interface class ProjectRemoteDataSrc {
  Future<void> addProject(Project project);

  Future<void> deleteProject(String projectId);

  Future<void> editProjectDetails({
    required String projectId,
    required DataMap updateData,
  });

  Future<ProjectModel> getProjectById(String projectId);

  Stream<List<ProjectModel>> getProjects({
    required bool detailed,
    int? limit,
    bool excludePendingDeletion = false,
  });

  Future<List<String>> getUserTools();

  Future<void> removeUserTool(String toolName);
}

class ProjectRemoteDataSrcImpl implements ProjectRemoteDataSrc {
  const ProjectRemoteDataSrcImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
    required ProjectDeleteCallable projectDeleteCallable,
  }) : _firestore = firestore,
       _storage = storage,
       _auth = auth,
       _projectDeleteCallable = projectDeleteCallable;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final ProjectDeleteCallable _projectDeleteCallable;

  CollectionReference<DataMap> _userProjectsCollection() {
    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('projects');
  }

  DocumentReference<DataMap> _projectDoc(String projectId) {
    return _userProjectsCollection().doc(projectId);
  }

  DocumentReference<DataMap> _userDoc() {
    return _firestore.collection('users').doc(_auth.currentUser!.uid);
  }

  CollectionReference<DataMap> _userClientsCollection() {
    return _userDoc().collection('clients');
  }

  @override
  Future<void> addProject(Project project) async {
    final batch = _firestore.batch();
    final uploadedGalleryStoragePaths = <String>[];
    String? uploadedFeatureStoragePath;
    DocumentReference<DataMap>? projectRef;
    try {
      await NetworkUtils.authorizeUser(_auth);
      final user = _auth.currentUser!;
      final userDocRef = _userDoc();
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        batch.set(userDocRef, {
          if (user.displayName != null) 'userName': user.displayName,
          'email': user.email,
          'id': user.uid,
          if (user.photoURL != null) 'photoURL': user.photoURL,
          if (project.tools.isNotEmpty) 'tools': project.tools,
        });
      }

      projectRef = _userProjectsCollection().doc();
      final uploadedFeature = project.image != null && project.imageIsFile
          ? await _uploadProjectFeatureImage(
              filePath: project.image!,
              projectId: projectRef.id,
            )
          : null;
      final uploadedGallery = project.images.isNotEmpty
          ? await _uploadProjectImages(
              filePaths: project.images,
              imagesModeRegistry: project.imagesModeRegistry,
              projectId: projectRef.id,
            )
          : null;

      uploadedFeatureStoragePath = uploadedFeature?.storagePath;
      uploadedGalleryStoragePaths.addAll(
        uploadedGallery?.uploadedStoragePaths ?? const <String>[],
      );

      var projectModel = (project as ProjectModel).copyWith(id: projectRef.id);
      if (uploadedFeature case final feature?) {
        projectModel = projectModel.copyWith(
          image: feature.downloadUrl,
          featureImageStoragePath: feature.storagePath,
        );
      }
      if (uploadedGallery case final gallery?) {
        projectModel = projectModel.copyWith(
          images: gallery.resolvedImages,
          ownedStoragePaths: [
            ?uploadedFeature?.storagePath,
            ...gallery.uploadedStoragePaths,
          ],
        );
      } else {
        projectModel = projectModel.copyWith(
          ownedStoragePaths: [
            ?uploadedFeature?.storagePath,
          ],
        );
      }

      if (project.tools.isNotEmpty && userDoc.exists) {
        final existingTools =
            (userDoc.data()?['tools'] as List<dynamic>?)
                ?.whereType<String>()
                .map((tool) => tool.toLowerCase())
                .toSet() ??
            <String>{};
        final newTools = project.tools
            .where((tool) => !existingTools.contains(tool.toLowerCase()))
            .toList();
        if (newTools.isNotEmpty) {
          batch.update(userDocRef, {
            'tools': FieldValue.arrayUnion(newTools),
          });
        }
      }

      batch.set(projectRef, {
        ...projectModel.toMap(),
        'milestoneOrderVersion': 0,
        'deletionRequestedAt': null,
        'featureImageStoragePath': uploadedFeature?.storagePath,
        'ownedStoragePaths': projectModel.ownedStoragePaths,
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      await _deleteStorageObjectsByPath([
        ?uploadedFeatureStoragePath,
        ...uploadedGalleryStoragePaths,
      ]);
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'addProject',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      await _deleteStorageObjectsByPath([
        ?uploadedFeatureStoragePath,
        ...uploadedGalleryStoragePaths,
      ]);
      rethrow;
    } on Exception catch (e, s) {
      await _deleteStorageObjectsByPath([
        ?uploadedFeatureStoragePath,
        ...uploadedGalleryStoragePaths,
      ]);
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'addProject',
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final result = await _projectDeleteCallable.requestProjectDeletion(
        projectId,
      );
      if (result.isCompleted) {
        return;
      }
      throw const ServerException(
        message: 'Project deletion is pending. Retry to finish cleanup.',
        statusCode: _kProjectDeletePendingCode,
      );
    } on FirebaseFunctionsException catch (error) {
      DocumentSnapshot<DataMap>? projectSnapshot;
      try {
        projectSnapshot = await _safeReadCurrentProject(projectId);
      } on ServerException {
        rethrow;
      } on Exception {
        throw ServerException(
          message: error.message ?? 'Project deletion failed.',
          statusCode: error.code,
        );
      }
      if (projectSnapshot == null) {
        return;
      }
      throw ServerException(
        message: error.message ?? 'Project deletion failed.',
        statusCode: error.code,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'deleteProject',
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> editProjectDetails({
    required String projectId,
    required DataMap updateData,
  }) async {
    final mutableUpdateData = Map<String, dynamic>.from(updateData);
    final uploadedGalleryStoragePaths = <String>[];
    String? uploadedFeatureStoragePath;
    try {
      await NetworkUtils.authorizeUser(_auth);

      mutableUpdateData
        ..remove('totalPaid')
        ..remove('numberOfMilestonesSoFar')
        ..remove('id')
        ..remove('userId')
        ..remove('lastUpdated');

      final projectDoc = _projectDoc(projectId);
      final initialSnapshot = await projectDoc.get();
      if (!initialSnapshot.exists) {
        throw const ServerException(
          message: 'Project not found',
          statusCode: _kProjectNotFoundCode,
        );
      }
      final initialData = initialSnapshot.data()!;
      if (initialData['deletionRequestedAt'] != null) {
        throw const ServerException(
          message: 'This project is pending deletion.',
          statusCode: _kProjectDeletePendingCode,
        );
      }

      if (mutableUpdateData['images'] != null) {
        if (mutableUpdateData case {
          'imagesModeRegistry': final List<bool> registry,
        }) {
          final filePaths = mutableUpdateData['images'] as List<String>;
          final uploadedGallery = await _uploadProjectImages(
            filePaths: filePaths,
            imagesModeRegistry: registry,
            projectId: projectId,
          );
          uploadedGalleryStoragePaths.addAll(
            uploadedGallery.uploadedStoragePaths,
          );
          mutableUpdateData['images'] = uploadedGallery.resolvedImages;
          mutableUpdateData.remove('imagesModeRegistry');
        } else {
          throw const ServerException(
            message: 'No registry detected for images\nReport this error.',
            statusCode: 'ServerError',
          );
        }
      }

      if (mutableUpdateData case {
        'image': final String filePath,
        'imageIsFile': true,
      }) {
        final uploadedFeature = await _uploadReplacementProjectFeatureImage(
          filePath: filePath,
          projectId: projectId,
        );
        uploadedFeatureStoragePath = uploadedFeature.storagePath;
        mutableUpdateData['image'] = uploadedFeature.downloadUrl;
        mutableUpdateData['featureImageStoragePath'] =
            uploadedFeature.storagePath;
        mutableUpdateData.remove('imageIsFile');
      } else if (mutableUpdateData.containsKey('image')) {
        mutableUpdateData['featureImageStoragePath'] = _storagePathFromUrl(
          mutableUpdateData['image'] as String?,
        );
        mutableUpdateData.remove('imageIsFile');
      }

      if (mutableUpdateData['urls'] != null) {
        final urls = (mutableUpdateData['urls'] as List<dynamic>).map((url) {
          if (url is URL) return (url as URLModel).toMap();
          if (url is Map<String, dynamic>) return url;
          throw const ServerException(
            message:
                'Url being uploaded as a String. Expect type Map or URL'
                '\nReport this Error',
            statusCode: 'ServerError',
          );
        }).toList();
        mutableUpdateData['urls'] = urls;
      }

      if (mutableUpdateData['tools'] != null) {
        mutableUpdateData['tools'] =
            (mutableUpdateData['tools'] as List<dynamic>)
                .whereType<String>()
                .toList();
      }

      if (mutableUpdateData case {'startDate': final startDate}) {
        if (startDate is! DateTime) {
          throw const ServerException(
            message: 'startDate must be a DateTime in edit mode',
            statusCode: 'ServerError',
          );
        }
        mutableUpdateData['startDate'] = Timestamp.fromDate(startDate);
      }
      if (mutableUpdateData case {'endDate': final endDate}) {
        if (endDate is DateTime) {
          mutableUpdateData['endDate'] = Timestamp.fromDate(endDate);
        }
      }
      if (mutableUpdateData case {'deadline': final deadline}) {
        if (deadline is DateTime) {
          mutableUpdateData['deadline'] = Timestamp.fromDate(deadline);
        }
      }

      await _firestore.runTransaction((transaction) async {
        final liveProjectSnapshot = await transaction.get(projectDoc);
        if (!liveProjectSnapshot.exists) {
          throw const ServerException(
            message: 'Project not found',
            statusCode: _kProjectNotFoundCode,
          );
        }

        final liveProjectData = liveProjectSnapshot.data()!;
        if (liveProjectData['deletionRequestedAt'] != null) {
          throw const ServerException(
            message: 'This project is pending deletion.',
            statusCode: _kProjectDeletePendingCode,
          );
        }

        final previousClientId = liveProjectData['clientId'] as String;
        final previousTotalPaid =
            (liveProjectData['totalPaid'] as num?)?.toDouble() ?? 0.0;

        if (mutableUpdateData case {
          'clientId': final String newClientId,
          'clientName': final String _,
        }) {
          if (newClientId != previousClientId && previousTotalPaid != 0) {
            transaction
              ..update(_userClientsCollection().doc(previousClientId), {
                'totalSpent': FieldValue.increment(-previousTotalPaid),
                'lastUpdated': FieldValue.serverTimestamp(),
              })
              ..update(_userClientsCollection().doc(newClientId), {
                'totalSpent': FieldValue.increment(previousTotalPaid),
                'lastUpdated': FieldValue.serverTimestamp(),
              });
          }
        }

        if (mutableUpdateData['tools'] case final List<String> tools) {
          final userDocRef = _userDoc();
          final userDoc = await transaction.get(userDocRef);
          final existingTools =
              (userDoc.data()?['tools'] as List<dynamic>?)
                  ?.whereType<String>()
                  .map((tool) => tool.toLowerCase())
                  .toSet() ??
              <String>{};
          final newTools = tools
              .where((tool) => !existingTools.contains(tool.toLowerCase()))
              .toList();
          if (newTools.isNotEmpty) {
            transaction.update(userDocRef, {
              'tools': FieldValue.arrayUnion(newTools),
            });
          }
        }

        final liveOwnedStoragePaths =
            (liveProjectData['ownedStoragePaths'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const <String>[];
        final liveImage = liveProjectData['image'] as String?;
        final liveImages =
            (liveProjectData['images'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const <String>[];
        final nextImages = mutableUpdateData.containsKey('images')
            ? (mutableUpdateData['images'] as List<dynamic>)
                  .whereType<String>()
                  .toList()
            : liveImages;
        final liveFeatureImageStoragePath =
            liveProjectData['featureImageStoragePath'] as String? ??
            _storagePathFromUrl(liveImage);
        final nextFeatureImageStoragePath =
            mutableUpdateData.containsKey('featureImageStoragePath')
            ? mutableUpdateData['featureImageStoragePath'] as String?
            : liveFeatureImageStoragePath;

        final ownedStoragePaths = _mergeOwnedStoragePaths(
          liveOwnedStoragePaths: liveOwnedStoragePaths,
          liveFeatureImageStoragePath: liveFeatureImageStoragePath,
          liveImages: liveImages,
          nextFeatureImageStoragePath: nextFeatureImageStoragePath,
          nextImages: nextImages,
          uploadedFeatureStoragePath: uploadedFeatureStoragePath,
          uploadedGalleryStoragePaths: uploadedGalleryStoragePaths,
        );

        transaction.update(projectDoc, {
          ...mutableUpdateData,
          'featureImageStoragePath': nextFeatureImageStoragePath,
          'ownedStoragePaths': ownedStoragePaths,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      await _deleteStorageObjectsByPath([
        ?uploadedFeatureStoragePath,
        ...uploadedGalleryStoragePaths,
      ]);
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'editProjectDetails',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      await _deleteStorageObjectsByPath([
        ?uploadedFeatureStoragePath,
        ...uploadedGalleryStoragePaths,
      ]);
      rethrow;
    } on Exception catch (e, s) {
      await _deleteStorageObjectsByPath([
        ?uploadedFeatureStoragePath,
        ...uploadedGalleryStoragePaths,
      ]);
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'editProjectDetails',
        stackTrace: s,
      );
    }
  }

  @override
  Future<ProjectModel> getProjectById(String projectId) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final snapshot = await _projectDoc(projectId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const ServerException(
          message: 'Project not found.',
          statusCode: _kProjectNotFoundCode,
        );
      }
      return ProjectModel.fromMap(snapshot.data()!);
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<ProjectModel>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'getProjectById',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<ProjectModel>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'getProjectById',
        stackTrace: s,
      );
    }
  }

  @override
  Stream<List<ProjectModel>> getProjects({
    required bool detailed,
    int? limit,
    bool excludePendingDeletion = false,
  }) async* {
    try {
      await NetworkUtils.authorizeUser(_auth);
      var query = _userProjectsCollection().orderBy(
        'startDate',
        descending: true,
      );
      if (excludePendingDeletion) {
        query = query.where('deletionRequestedAt', isNull: true);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      yield* query
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => ProjectModel.fromMap(doc.data()))
                .toList();
          })
          .handleError((Object error, StackTrace stackTrace) {
            if (error is FirebaseException) {
              return NetworkUtils.handleRemoteSourceException<
                List<ProjectModel>
              >(
                error,
                repositoryName: 'ProjectRemoteDataSrcImpl',
                methodName: 'getProjects',
                stackTrace: error.stackTrace,
                statusCode: error.code,
                errorMessage: error.message,
              );
            }
            return NetworkUtils.handleRemoteSourceException<List<ProjectModel>>(
              error,
              repositoryName: 'ProjectRemoteDataSrcImpl',
              methodName: 'getProjects',
              stackTrace: stackTrace,
            );
          });
    } on FirebaseException catch (e) {
      yield* Stream.error(
        NetworkUtils.handleRemoteSourceException<List<ProjectModel>>(
          e,
          repositoryName: 'ProjectRemoteDataSrcImpl',
          methodName: 'getProjects',
          stackTrace: e.stackTrace,
          statusCode: e.code,
          errorMessage: e.message,
        ),
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      yield* Stream.error(
        NetworkUtils.handleRemoteSourceException<List<ProjectModel>>(
          e,
          repositoryName: 'ProjectRemoteDataSrcImpl',
          methodName: 'getProjects',
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<List<String>> getUserTools() async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final userDoc = await _userDoc().get();
      if (!userDoc.exists || userDoc.data() == null) {
        return const <String>[];
      }
      final data = userDoc.data()!;
      final tools =
          (data['tools'] as List<dynamic>?)?.whereType<String>().toList() ??
          const <String>[];
      return tools;
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<List<String>>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'getUserTools',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<List<String>>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'getUserTools',
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> removeUserTool(String toolName) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      await _userDoc().update({
        'tools': FieldValue.arrayRemove([toolName]),
      });
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'removeUserTool',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'removeUserTool',
        stackTrace: s,
      );
    }
  }

  Future<_UploadedGalleryImages> _uploadProjectImages({
    required List<String> filePaths,
    required List<bool> imagesModeRegistry,
    required String projectId,
  }) async {
    final resolvedImages = <String>[];
    final uploadedStoragePaths = <String>[];
    for (final (index, image) in filePaths.indexed) {
      if (imagesModeRegistry[index]) {
        final contentType = image.split('.').last;
        final imageFileRef = _storage.ref().child(
          'projects/${_auth.currentUser!.uid}/$projectId/'
          'images/${const Uuid().v1()}',
        );
        final task = await imageFileRef.putFile(
          File(image),
          SettableMetadata(contentType: 'image/$contentType'),
        );
        resolvedImages.add(await task.ref.getDownloadURL());
        uploadedStoragePaths.add(task.ref.fullPath);
      } else {
        resolvedImages.add(image);
      }
    }
    return (
      resolvedImages: resolvedImages,
      uploadedStoragePaths: uploadedStoragePaths,
    );
  }

  Future<_UploadedFeatureImage> _uploadProjectFeatureImage({
    required String filePath,
    required String projectId,
  }) async {
    final contentType = filePath.split('.').last;
    final featureImageFileRef = _storage.ref().child(
      'projects/${_auth.currentUser!.uid}/$projectId/feature_image',
    );
    final task = await featureImageFileRef.putFile(
      File(filePath),
      SettableMetadata(contentType: 'image/$contentType'),
    );
    return (
      downloadUrl: await task.ref.getDownloadURL(),
      storagePath: task.ref.fullPath,
    );
  }

  Future<_UploadedFeatureImage> _uploadReplacementProjectFeatureImage({
    required String filePath,
    required String projectId,
  }) async {
    final contentType = filePath.split('.').last;
    final featureImageFileRef = _storage.ref().child(
      'projects/${_auth.currentUser!.uid}/$projectId/'
      'feature_image/${const Uuid().v1()}',
    );
    final task = await featureImageFileRef.putFile(
      File(filePath),
      SettableMetadata(contentType: 'image/$contentType'),
    );
    return (
      downloadUrl: await task.ref.getDownloadURL(),
      storagePath: task.ref.fullPath,
    );
  }

  List<String> _mergeOwnedStoragePaths({
    required List<String> liveOwnedStoragePaths,
    required String? liveFeatureImageStoragePath,
    required List<String> liveImages,
    required String? nextFeatureImageStoragePath,
    required List<String> nextImages,
    required String? uploadedFeatureStoragePath,
    required List<String> uploadedGalleryStoragePaths,
  }) {
    return <String>{
      ...liveOwnedStoragePaths,
      ?liveFeatureImageStoragePath,
      ..._storagePathsFromUrls(liveImages),
      ?nextFeatureImageStoragePath,
      ..._storagePathsFromUrls(nextImages),
      ?uploadedFeatureStoragePath,
      ...uploadedGalleryStoragePaths,
    }.toList()..sort();
  }

  List<String> _storagePathsFromUrls(List<String> urls) {
    return urls.map(_storagePathFromUrl).whereType<String>().toSet().toList();
  }

  Future<void> _deleteStorageObjectsByPath(List<String> paths) async {
    for (final path in paths.toSet()) {
      await _deleteStorageObjectByPath(path);
    }
  }

  Future<void> _deleteStorageObjectByPath(String path) async {
    try {
      final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
      await _storage.ref().child(normalizedPath).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  Future<DocumentSnapshot<DataMap>?> _safeReadCurrentProject(
    String projectId,
  ) async {
    final snapshot = await _projectDoc(projectId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    final data = snapshot.data()!;
    if (data['deletionRequestedAt'] != null) {
      throw const ServerException(
        message: 'Project deletion is pending. Retry to finish cleanup.',
        statusCode: _kProjectDeletePendingCode,
      );
    }
    return snapshot;
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

  String? _storagePathFromUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    final parsed = _parseStorageUrl(url);
    if (parsed.bucket != _storage.bucket || parsed.path == null) {
      return null;
    }
    return parsed.path!.startsWith('/')
        ? parsed.path!.substring(1)
        : parsed.path!;
  }
}
