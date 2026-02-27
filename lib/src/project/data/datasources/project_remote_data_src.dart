import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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

abstract class ProjectRemoteDataSrc {
  Future<void> addProject(Project project);

  Future<void> editProjectDetails({
    required String projectId,
    required DataMap updatedProject,
  });

  Future<void> deleteProject(String projectId);

  Stream<List<ProjectModel>> getProjects({required bool detailed, int? limit});

  Future<ProjectModel> getProjectById(String projectId);
}

class ProjectRemoteDataSrcImpl implements ProjectRemoteDataSrc {
  const ProjectRemoteDataSrcImpl({
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
  Future<void> addProject(Project project) async {
    final batch = _firestore.batch();
    var images = <String>[];
    String? image;
    DocumentReference<Map<String, dynamic>>? projectRef;
    try {
      await NetworkUtils.authorizeUser(_auth);
      final user = _auth.currentUser!;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        // we add user collection here because this is the first function that
        // will apparently run, after user opens app for the first time, if
        // they try to add a project, a client will have to be specified, and
        // in that scenario, we will save the client
        final userDocRef = _firestore.collection('users').doc(user.uid);
        batch.set(userDocRef, {
          if (user.displayName != null) 'userName': user.displayName,
          'email': user.email,
          'id': user.uid,
          if (user.photoURL != null) 'photoURL': user.photoURL,
          if (project.tools.isNotEmpty) 'tools': project.tools,
        });
      }
      projectRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc();

      var projectModel = (project as ProjectModel).copyWith(id: projectRef.id);
      if (project.image != null && project.imageIsFile) {
        image = await _uploadProjectFeatureImage(
          filePath: project.image!,
          projectId: projectRef.id,
        );
        projectModel = projectModel.copyWith(image: image);
      }
      if (project.images.isNotEmpty) {
        images = await _uploadProjectImages(
          filePaths: project.images,
          imagesModeRegistry: project.imagesModeRegistry,
          projectId: projectRef.id,
        );
        projectModel = projectModel.copyWith(images: images);
      }

      if (project.tools.isNotEmpty && userDoc.exists) {
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();
        final tools = project.tools;
        var userTools = userDoc.data()?['tools'] as List<String>? ?? [];
        userTools = userTools.map((tools) => tools.toLowerCase()).toList();
        final newTools = tools.where(
          (tool) => !userTools.contains(tool.toLowerCase()),
        );
        if (newTools.isNotEmpty) {
          batch.update(userDocRef, {
            'tools': FieldValue.arrayUnion(newTools.toList()),
          });
        }
      }

      batch.set(projectRef, projectModel.toMap());
      await batch.commit();
    } on FirebaseException catch (e) {
      if (projectRef != null) {
        await rollbackStorageUploads(
          images: images,
          projectId: projectRef.id,
          image: image,
        );
      }
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'addProject',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      if (projectRef != null) {
        await rollbackStorageUploads(
          images: images,
          projectId: projectRef.id,
          image: image,
        );
      }
      rethrow;
    } on Exception catch (e, s) {
      if (projectRef != null) {
        await rollbackStorageUploads(
          images: images,
          projectId: projectRef.id,
          image: image,
        );
      }
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'addProject',
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> editProjectDetails({
    required String projectId,
    required DataMap updatedProject,
  }) async {
    final batch = _firestore.batch();
    var images = <String>[];
    String? image;
    try {
      await NetworkUtils.authorizeUser(_auth);

      updatedProject
        ..remove('totalPaid')
        ..remove('lastUpdated');
      final projectDoc = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('projects')
          .doc(projectId);
      if (updatedProject['images'] != null) {
        if (updatedProject
            case {'imagesModeRegistry': final List<bool> registry}) {
          final filePaths = updatedProject['images'] as List<String>;
          images = await _uploadProjectImages(
            filePaths: filePaths,
            imagesModeRegistry: registry,
            projectId: projectId,
          );
          updatedProject['images'] = images;
          updatedProject.remove('imagesModeRegistry');
        } else {
          throw const ServerException(
            message: 'No registry detected for images\nReport this error.',
            statusCode: 'ServerError',
          );
        }
      }
      if (updatedProject
          case {
            'image': final String filePath,
            'imageIsFile': true,
          }) {
        image = await _uploadProjectFeatureImage(
          filePath: filePath,
          projectId: projectId,
        );
        updatedProject['image'] = image;
        updatedProject.remove('imageIsFile');
      }
      if (updatedProject['urls'] != null) {
        final urls = (updatedProject['urls'] as List).map((url) {
          if (url is URL) return (url as URLModel).toMap();
          if (url is Map) return url;
          throw const ServerException(
            message: 'Url being uploaded as a String. Expect type Map or URL'
                '\nReport this Error',
            statusCode: 'ServerError',
          );
        }).toList();
        batch.update(projectDoc, {'urls': FieldValue.arrayUnion(urls)});
        updatedProject.remove('urls');
      }
      if (updatedProject['tools'] != null) {
        final tools = updatedProject['tools'] as List<String>;
        final userDocRef =
            _firestore.collection('users').doc(_auth.currentUser!.uid);
        final userDoc = await userDocRef.get();
        var userTools = userDoc.data()?['tools'] as List<String>? ?? [];
        userTools = userTools.map((tools) => tools.toLowerCase()).toList();
        final newTools = tools.where(
          (tool) => !userTools.contains(tool.toLowerCase()),
        );
        if (newTools.isNotEmpty) {
          batch.update(userDocRef, {
            'tools': FieldValue.arrayUnion(newTools.toList()),
          });
        }
      }
      if (updatedProject case {'startDate': final startDate}) {
        if (startDate is DateTime) {
          updatedProject['startDate'] = Timestamp.fromDate(startDate);
        }
      }
      if (updatedProject case {'endDate': final endDate}) {
        if (endDate is DateTime) {
          updatedProject['endDate'] = Timestamp.fromDate(endDate);
        }
      }
      if (updatedProject case {'deadline': final deadline}) {
        if (deadline is DateTime) {
          updatedProject['deadline'] = Timestamp.fromDate(deadline);
        }
      }
      batch.update(projectDoc, {
        ...updatedProject,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      await rollbackStorageUploads(
        images: images,
        projectId: projectId,
        image: image,
      );
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'editProjectDetails',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      await rollbackStorageUploads(
        images: images,
        projectId: projectId,
        image: image,
      );
      rethrow;
    } on Exception catch (e, s) {
      await rollbackStorageUploads(
        images: images,
        projectId: projectId,
        image: image,
      );
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'editProjectDetails',
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final milestones = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .get();
      if (milestones.docs.length > 500) {
        for (var i = 0; i < milestones.docs.length; i += 500) {
          final batch = _firestore.batch();
          final end = i + 500;
          final milestonesBatch = milestones.docs.sublist(
            i,
            end > milestones.docs.length ? milestones.docs.length : end,
          );
          for (final milestone in milestonesBatch) {
            batch.delete(milestone.reference);
          }
          await batch.commit();
        }
      } else {
        final batch = _firestore.batch();
        for (final milestone in milestones.docs) {
          batch.delete(milestone.reference);
        }
        await batch.commit();
      }

      await _storage
          .ref()
          .child('projects/${_auth.currentUser!.uid}/$projectId/feature_image')
          .delete();

      await _storage
          .ref()
          .child('projects/${_auth.currentUser!.uid}/$projectId/images')
          .listAll()
          .then((result) async {
        for (final imageRef in result.items) {
          final imageName = imageRef.name;
          final fullPath =
              'projects/${_auth.currentUser!.uid}/$projectId/images/$imageName';
          await _storage.ref().child(fullPath).delete();
        }
      });

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('projects')
          .doc(projectId)
          .delete();
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'ProjectRemoteDataSrcImpl',
        methodName: 'deleteProject',
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
        methodName: 'deleteProject',
        stackTrace: s,
      );
    }
  }

  @override
  Stream<List<ProjectModel>> getProjects({required bool detailed, int? limit}) {
    try {
      NetworkUtils.authorizeUser(_auth);
      final projectsStream = limit == null
          ? _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('projects')
              .orderBy('startDate', descending: true)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs.map((doc) {
                  return ProjectModel.fromMap(doc.data());
                }).toList(),
              )
          : _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('projects')
              .orderBy('startDate', descending: true)
              .limit(limit)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs.map((doc) {
                  return ProjectModel.fromMap(doc.data());
                }).toList(),
              );
      return projectsStream.handleError((
        Object error,
        StackTrace stackTrace,
      ) {
        if (error is FirebaseException) {
          return NetworkUtils.handleRemoteSourceException<List<ProjectModel>>(
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
      return Stream.error(
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
      return Stream.error(
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
  Future<ProjectModel> getProjectById(String projectId) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final projectDocument = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('projects')
          .doc(projectId)
          .get();
      return ProjectModel.fromMap(projectDocument.data()!);
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

  Future<List<String>> _uploadProjectImages({
    required List<String> filePaths,
    required List<bool> imagesModeRegistry,
    required String projectId,
  }) async {
    final images = <String>[];
    for (final (index, image) in filePaths.indexed) {
      if (imagesModeRegistry[index]) {
        final contentType = image.split('.').last;
        final imageFileRef = _storage.ref().child(
              'projects/${_auth.currentUser!.uid}/$projectId/'
              'images/${const Uuid().v1()}',
            );
        await imageFileRef
            .putFile(
          File(image),
          SettableMetadata(contentType: 'image/$contentType'),
        )
            .then((value) async {
          final url = await value.ref.getDownloadURL();
          images.add(url);
        });
      } else {
        images.add(image);
      }
    }
    return images;
  }

  Future<String> _uploadProjectFeatureImage({
    required String filePath,
    required String projectId,
  }) async {
    final contentType = filePath.split('.').last;
    final featureImageFileRef = _storage.ref().child(
          'projects/${_auth.currentUser!.uid}/$projectId/feature_image',
        );
    return featureImageFileRef
        .putFile(
      File(filePath),
      SettableMetadata(contentType: 'image/$contentType'),
    )
        .then((value) async {
      return value.ref.getDownloadURL();
    });
  }

  Future<void> rollbackStorageUploads({
    required List<String> images,
    required String projectId,
    String? image,
  }) async {
    if (image != null) {
      await _storage
          .ref()
          .child(
            'projects/${_auth.currentUser!.uid}/$projectId/feature_image',
          )
          .delete();
    }
    if (images.isNotEmpty) {
      await _storage
          .ref()
          .child('projects/${_auth.currentUser!.uid}/$projectId/images')
          .listAll()
          .then((result) async {
        for (final imageRef in result.items) {
          final imageName = imageRef.name;
          final fullPath =
              'projects/${_auth.currentUser!.uid}/$projectId/images/$imageName';
          await _storage.ref().child(fullPath).delete();
        }
      });
    }
  }
}
