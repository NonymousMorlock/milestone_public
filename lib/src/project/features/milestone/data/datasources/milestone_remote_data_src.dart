import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/services/firebase_path_provider.dart';
import 'package:milestone/core/utils/network_utils.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';

abstract class MilestoneRemoteDataSrc {
  Future<void> addMilestone(Milestone milestone);

  Future<void> editMilestone({
    required String projectId,
    required String milestoneId,
    required DataMap updatedMilestone,
  });

  Future<List<MilestoneModel>> getMilestones(String projectId);

  Future<void> deleteMilestone({
    required String projectId,
    required String milestoneId,
  });

  Future<MilestoneModel> getMilestoneById({
    required String projectId,
    required String milestoneId,
  });
}

class MilestoneRemoteDataSrcImpl implements MilestoneRemoteDataSrc {
  const MilestoneRemoteDataSrcImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebasePathProvider firebasePathProvider,
  })  : _firestore = firestore,
        _auth = auth,
        _firebasePathProvider = firebasePathProvider;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebasePathProvider _firebasePathProvider;

  @override
  Future<void> addMilestone(Milestone milestone) async {
    try {
      await NetworkUtils.authorizeUser(_auth);

      final projectRef = _firebasePathProvider.projectRef(milestone.projectId);
      final projectData = await projectRef.get();

      final clientId = projectData['clientId'] as String;
      final clientRef = _firebasePathProvider.clientRef(clientId);
      final userRef = _firebasePathProvider.userRef;

      final milestoneDoc = projectRef.collection('milestones').doc();
      final milestoneToUpload =
          (milestone as MilestoneModel).copyWith(id: milestoneDoc.id);

      final lastMilestoneByIndex = await projectRef
          .collection('milestones')
          .orderBy('index', descending: true)
          .limit(1)
          .get();

      final index = lastMilestoneByIndex.docs.isEmpty
          ? 0
          : ((lastMilestoneByIndex.docs.first.data()['index'] as num).toInt()) +
              300;

      await _firestore.runTransaction((transaction) async {
        transaction
          ..set(
            milestoneDoc,
            milestoneToUpload.copyWith(index: index).toMap()
              ..update('dateCreated', (_) => FieldValue.serverTimestamp())
              ..update('lastUpdated', (_) => FieldValue.serverTimestamp()),
          )
          ..update(projectRef, {
            if (milestone.amountPaid != null)
              'totalPaid': FieldValue.increment(milestone.amountPaid!),
            'numberOfMilestonesSoFar': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

        if (milestone.amountPaid != null) {
          transaction
            ..update(clientRef, {
              'totalSpent': FieldValue.increment(milestone.amountPaid!),
              'lastUpdated': FieldValue.serverTimestamp(),
            })
            ..update(userRef, {
              'totalEarned': FieldValue.increment(milestone.amountPaid!),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
        }
      });
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'addMilestone',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'addMilestone',
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> editMilestone({
    required String projectId,
    required String milestoneId,
    required DataMap updatedMilestone,
  }) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      updatedMilestone
        ..remove('lastUpdated')
        ..remove('id');
      final milestoneDoc = _firebasePathProvider.milestoneRef(
        projectId: projectId,
        milestoneId: milestoneId,
      );

      final projectRef = _firebasePathProvider.projectRef(projectId);
      final projectData = await projectRef.get();
      final clientRef = _firebasePathProvider.clientRef(
        projectData['clientId'] as String,
      );
      final userRef = _firebasePathProvider.userRef;

      await _firestore.runTransaction((transaction) async {
        final milestoneData = await transaction.get(milestoneDoc);
        final oldAmountPaid =
            (milestoneData.data()?['amountPaid'] as num?)?.toDouble() ?? 0.0;

        if (updatedMilestone
            case {
              'index': {
                'head': final String headId,
                'tail': final String tailId
              }
            }) {
          final headMilestoneDoc = _firebasePathProvider.milestoneRef(
            projectId: projectId,
            milestoneId: headId,
          );

          final tailMilestoneDoc = _firebasePathProvider.milestoneRef(
            projectId: projectId,
            milestoneId: tailId,
          );

          final headMilestoneData = await transaction.get(headMilestoneDoc);
          final tailMilestoneData = await transaction.get(tailMilestoneDoc);

          final headIndex = headMilestoneData.data()?['index'] as int;
          final tailIndex = tailMilestoneData.data()?['index'] as int;

          final newIndex = (headIndex + tailIndex) / 2;

          transaction.update(milestoneDoc, {
            'index': newIndex,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        if (updatedMilestone case {'notes': final List<String> notes}) {
          transaction
              .update(milestoneDoc, {'notes': FieldValue.arrayUnion(notes)});
          updatedMilestone.remove('notes');
        }

        if (updatedMilestone case {'amountPaid': final num amountPaid}) {
          final difference = amountPaid - oldAmountPaid;

          transaction
            ..update(projectRef, {
              'totalPaid': FieldValue.increment(difference),
              'lastUpdated': FieldValue.serverTimestamp(),
            })
            ..update(clientRef, {
              'totalSpent': FieldValue.increment(difference),
              'lastUpdated': FieldValue.serverTimestamp(),
            })
            ..update(userRef, {
              'totalEarned': FieldValue.increment(difference),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
        }

        if (updatedMilestone case {'startDate': final DateTime date}) {
          updatedMilestone['startDate'] = Timestamp.fromDate(date);
        }
        if (updatedMilestone case {'endDate': final DateTime date}) {
          updatedMilestone['endDate'] = Timestamp.fromDate(date);
        }

        transaction.update(milestoneDoc, {
          ...updatedMilestone,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'editMilestone',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'editMilestone',
        stackTrace: s,
      );
    }
  }

  @override
  Future<List<MilestoneModel>> getMilestones(String projectId) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final milestones = await _firebasePathProvider
          .projectRef(projectId)
          .collection('milestones')
          .orderBy('index')
          .get();
      return milestones.docs
          .map((milestoneDoc) => MilestoneModel.fromMap(milestoneDoc.data()))
          .toList();
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<List<MilestoneModel>>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'addMilestone',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<List<MilestoneModel>>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'addMilestone',
        stackTrace: s,
        statusCode: 'PROJECT_MILESTONES_UNKNOWN',
      );
    }
  }

  @override
  Future<void> deleteMilestone({
    required String projectId,
    required String milestoneId,
  }) async {
    try {
      await NetworkUtils.authorizeUser(_auth);

      final milestoneDoc = _firebasePathProvider.milestoneRef(
        projectId: projectId,
        milestoneId: milestoneId,
      );

      final projectRef = _firebasePathProvider.projectRef(projectId);
      final projectData = await projectRef.get();
      final clientRef = _firebasePathProvider.clientRef(
        projectData['clientId'] as String,
      );
      final userRef = _firebasePathProvider.userRef;

      await _firestore.runTransaction((transaction) async {
        final milestoneData = await transaction.get(milestoneDoc);
        final amountPaid =
            (milestoneData.data()?['amountPaid'] as num?)?.toDouble() ?? 0.0;

        transaction
          ..delete(milestoneDoc)
          ..update(projectRef, {
            'totalPaid': FieldValue.increment(-amountPaid),
            'numberOfMilestonesSoFar': FieldValue.increment(-1),
            'lastUpdated': FieldValue.serverTimestamp(),
          })
          ..update(clientRef, {
            'totalSpent': FieldValue.increment(-amountPaid),
            'lastUpdated': FieldValue.serverTimestamp(),
          })
          ..update(userRef, {
            'totalEarned': FieldValue.increment(-amountPaid),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      });
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'deleteMilestone',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'deleteMilestone',
        stackTrace: s,
      );
    }
  }

  @override
  Future<MilestoneModel> getMilestoneById({
    required String projectId,
    required String milestoneId,
  }) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final milestoneDoc = await _firebasePathProvider
          .milestoneRef(projectId: projectId, milestoneId: milestoneId)
          .get();
      return MilestoneModel.fromMap(milestoneDoc.data()!);
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<MilestoneModel>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'getMilestoneById',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<MilestoneModel>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'getMilestoneById',
        stackTrace: s,
        statusCode: 'MILESTONE_DETAILS_UNKNOWN',
      );
    }
  }
}
