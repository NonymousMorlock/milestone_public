import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/services/firebase_path_provider.dart';
import 'package:milestone/core/utils/network_utils.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone_collection_snapshot.dart';

const _kRankGap = 1024.0;
const _kMinDirectGap = 1.0;
const _kMaxAbsRank = 9e12;
const _kMaxRebalanceMilestones = 400;
const _kAppendRankRetryLimit = 2;
const _kMilestoneOrderStaleCode = 'milestone-order-stale';
const _kMilestoneOrderInvalidTargetCode = 'milestone-order-invalid-target';
const _kMilestoneOrderRebalanceLimitCode = 'milestone-order-rebalance-limit';
const _kMilestoneDetailsNotFoundCode = 'MILESTONE_DETAILS_NOT_FOUND';
const _kProjectPendingDeleteCode = 'project-pending-delete';

class _RebalanceRequired implements Exception {
  const _RebalanceRequired();
}

class _StaleOrderVersion implements Exception {
  const _StaleOrderVersion();
}

abstract interface class MilestoneRemoteDataSrc {
  Future<void> addMilestone(Milestone milestone);

  Future<void> editMilestone({
    required String projectId,
    required String milestoneId,
    required DataMap updatedMilestone,
  });

  Future<MilestoneCollectionSnapshot> getMilestones(String projectId);

  Future<void> reorderMilestone({
    required String projectId,
    required String milestoneId,
    required String? previousMilestoneId,
    required String? nextMilestoneId,
    required int expectedOrderVersion,
  });

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
  }) : _firestore = firestore,
       _auth = auth,
       _firebasePathProvider = firebasePathProvider;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebasePathProvider _firebasePathProvider;

  List<String> _normalizeNotes(List<dynamic> notes) {
    return notes
        .map((note) => note.toString().trim())
        .where((note) => note.isNotEmpty)
        .toList();
  }

  void _replaceDateFieldsWithTimestamps(DataMap patch) {
    if (patch['startDate'] case final DateTime startDate) {
      patch['startDate'] = Timestamp.fromDate(startDate);
    }
    if (patch['endDate'] case final DateTime endDate) {
      patch['endDate'] = Timestamp.fromDate(endDate);
    }
  }

  int _projectOrderVersion(DataMap? projectData) {
    return (projectData?['milestoneOrderVersion'] as num?)?.toInt() ?? 0;
  }

  double _buildAppendRank(double? tailRank) {
    if (tailRank == null) {
      return 0;
    }
    final nextRank = tailRank + _kRankGap;
    if (!nextRank.isFinite || nextRank.abs() > _kMaxAbsRank) {
      throw const _RebalanceRequired();
    }
    return nextRank;
  }

  double _computeDirectRank({
    required double? previousRank,
    required double? nextRank,
  }) {
    if (previousRank != null && nextRank != null) {
      final gap = nextRank - previousRank;
      final midpoint = previousRank + (gap / 2.0);
      if (gap < _kMinDirectGap ||
          !midpoint.isFinite ||
          midpoint <= previousRank ||
          midpoint >= nextRank) {
        throw const _RebalanceRequired();
      }
      return midpoint;
    }

    if (previousRank != null) {
      final candidate = previousRank + _kRankGap;
      if (!candidate.isFinite || candidate.abs() > _kMaxAbsRank) {
        throw const _RebalanceRequired();
      }
      return candidate;
    }

    if (nextRank != null) {
      final candidate = nextRank - _kRankGap;
      if (!candidate.isFinite || candidate.abs() > _kMaxAbsRank) {
        throw const _RebalanceRequired();
      }
      return candidate;
    }

    throw _invalidTargetException();
  }

  double _rebalancedRankForPosition(int position) => position * _kRankGap;

  CollectionReference<DataMap> _milestonesCollection(String projectId) {
    return _firebasePathProvider.projectRef(projectId).collection('milestones');
  }

  ServerException _invalidTargetException() {
    return const ServerException(
      message: 'Milestone reorder target is invalid.',
      statusCode: _kMilestoneOrderInvalidTargetCode,
    );
  }

  ServerException _staleOrderException() {
    return const ServerException(
      message: 'Milestone order changed. Refresh and try again.',
      statusCode: _kMilestoneOrderStaleCode,
    );
  }

  ServerException _rebalanceLimitException() {
    return const ServerException(
      message: 'Milestone order requires too many rewrites to rebalance.',
      statusCode: _kMilestoneOrderRebalanceLimitCode,
    );
  }

  ServerException _milestoneNotFoundException() {
    return const ServerException(
      message: 'Milestone not found',
      statusCode: _kMilestoneDetailsNotFoundCode,
    );
  }

  void _assertProjectNotPendingDeletion(DocumentSnapshot<DataMap> projectDoc) {
    if (projectDoc.data()?['deletionRequestedAt'] != null) {
      throw const ServerException(
        message: 'This project is pending deletion.',
        statusCode: _kProjectPendingDeleteCode,
      );
    }
  }

  double _rankFromData(DataMap? data) {
    final rank = data?['rank'];
    if (rank is num) {
      return rank.toDouble();
    }
    throw _invalidTargetException();
  }

  List<QueryDocumentSnapshot<DataMap>> _applyReorderPlan({
    required List<QueryDocumentSnapshot<DataMap>> orderedDocs,
    required String milestoneId,
    required String? previousMilestoneId,
    required String? nextMilestoneId,
  }) {
    if (previousMilestoneId == milestoneId ||
        nextMilestoneId == milestoneId ||
        (previousMilestoneId != null &&
            previousMilestoneId == nextMilestoneId)) {
      throw _invalidTargetException();
    }

    final plannedOrder = List<QueryDocumentSnapshot<DataMap>>.of(orderedDocs);
    final movedIndex = plannedOrder.indexWhere((doc) => doc.id == milestoneId);
    if (movedIndex == -1) {
      throw _milestoneNotFoundException();
    }

    final movedDoc = plannedOrder.removeAt(movedIndex);
    if (plannedOrder.isEmpty) {
      if (previousMilestoneId == null && nextMilestoneId == null) {
        return [movedDoc];
      }
      throw _invalidTargetException();
    }

    if (previousMilestoneId == null && nextMilestoneId == null) {
      throw _invalidTargetException();
    }

    final previousIndex = previousMilestoneId == null
        ? null
        : plannedOrder.indexWhere((doc) => doc.id == previousMilestoneId);
    final nextIndex = nextMilestoneId == null
        ? null
        : plannedOrder.indexWhere((doc) => doc.id == nextMilestoneId);

    if (previousMilestoneId != null && previousIndex == -1) {
      throw _invalidTargetException();
    }
    if (nextMilestoneId != null && nextIndex == -1) {
      throw _invalidTargetException();
    }
    if (previousIndex != null &&
        nextIndex != null &&
        previousIndex >= nextIndex) {
      throw _invalidTargetException();
    }

    final insertionIndex = switch ((previousMilestoneId, nextMilestoneId)) {
      (null, String _) => nextIndex!,
      (String _, null) => previousIndex! + 1,
      (String _, String _) => previousIndex! + 1,
      (null, null) => throw _invalidTargetException(),
    };

    plannedOrder.insert(insertionIndex, movedDoc);
    return plannedOrder;
  }

  @override
  Future<void> addMilestone(Milestone milestone) async {
    try {
      await NetworkUtils.authorizeUser(_auth);

      final projectRef = _firebasePathProvider.projectRef(milestone.projectId);
      for (var attempt = 0; attempt < _kAppendRankRetryLimit; attempt++) {
        final projectSnapshot = await projectRef.get();
        final orderVersion = _projectOrderVersion(projectSnapshot.data());
        final tailSnapshot = await _milestonesCollection(
          milestone.projectId,
        ).orderBy('rank', descending: true).limit(1).get();

        final tailRank = tailSnapshot.docs.isEmpty
            ? null
            : _rankFromData(tailSnapshot.docs.first.data());

        try {
          await _firestore.runTransaction((transaction) async {
            final projectDoc = await transaction.get(projectRef);
            if (!projectDoc.exists) {
              throw _milestoneNotFoundException();
            }
            _assertProjectNotPendingDeletion(projectDoc);

            final projectData = projectDoc.data();
            final currentVersion = _projectOrderVersion(projectData);
            if (currentVersion != orderVersion) {
              throw const _StaleOrderVersion();
            }

            final clientId = projectData?['clientId'] as String?;
            if (clientId == null || clientId.isEmpty) {
              throw const ServerException(
                message: 'Project client not found',
                statusCode: 'PROJECT_CLIENT_NOT_FOUND',
              );
            }

            final milestoneDoc = _milestonesCollection(
              milestone.projectId,
            ).doc();
            final rank = _buildAppendRank(tailRank);
            final milestoneToUpload =
                (milestone as MilestoneModel)
                    .copyWith(id: milestoneDoc.id, rank: rank)
                    .toMap()
                  ..['dateCreated'] = FieldValue.serverTimestamp()
                  ..['lastUpdated'] = FieldValue.serverTimestamp();

            transaction
              ..set(milestoneDoc, milestoneToUpload)
              ..update(projectRef, {
                'milestoneOrderVersion': currentVersion + 1,
                'numberOfMilestonesSoFar': FieldValue.increment(1),
                'lastUpdated': FieldValue.serverTimestamp(),
                if (milestone.amountPaid != null)
                  'totalPaid': FieldValue.increment(milestone.amountPaid!),
              });

            if (milestone.amountPaid != null) {
              transaction
                ..update(_firebasePathProvider.clientRef(clientId), {
                  'totalSpent': FieldValue.increment(milestone.amountPaid!),
                  'lastUpdated': FieldValue.serverTimestamp(),
                })
                ..update(_firebasePathProvider.userRef, {
                  'totalEarned': FieldValue.increment(milestone.amountPaid!),
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
            }
          });
          return;
        } on _StaleOrderVersion {
          if (attempt == _kAppendRankRetryLimit - 1) {
            throw _staleOrderException();
          }
        } on _RebalanceRequired {
          throw _rebalanceLimitException();
        }
      }
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
      final patch = Map<String, dynamic>.from(updatedMilestone)
        ..remove('lastUpdated')
        ..remove('dateCreated')
        ..remove('projectId')
        ..remove('id')
        ..remove('rank')
        ..remove('index')
        ..remove('milestoneOrderVersion')
        ..remove('previousMilestoneId')
        ..remove('nextMilestoneId');

      final milestoneDoc = _firebasePathProvider.milestoneRef(
        projectId: projectId,
        milestoneId: milestoneId,
      );

      final projectRef = _firebasePathProvider.projectRef(projectId);
      await _firestore.runTransaction((transaction) async {
        final projectDoc = await transaction.get(projectRef);
        if (!projectDoc.exists) {
          throw _milestoneNotFoundException();
        }
        _assertProjectNotPendingDeletion(projectDoc);

        final projectData = projectDoc.data();
        final clientId = projectData?['clientId'] as String?;
        if (clientId == null || clientId.isEmpty) {
          throw const ServerException(
            message: 'Project client not found',
            statusCode: 'PROJECT_CLIENT_NOT_FOUND',
          );
        }
        final milestoneData = await transaction.get(milestoneDoc);
        final oldAmountPaid =
            (milestoneData.data()?['amountPaid'] as num?)?.toDouble() ?? 0.0;

        if (patch case {'notes': final List<dynamic> notes}) {
          patch['notes'] = _normalizeNotes(notes);
        }

        if (patch.containsKey('amountPaid')) {
          final rawAmountPaid = patch['amountPaid'];
          final newAmountPaid = (rawAmountPaid as num?)?.toDouble();
          final difference = (newAmountPaid ?? 0.0) - oldAmountPaid;

          if (difference != 0) {
            transaction
              ..update(projectRef, {
                'totalPaid': FieldValue.increment(difference),
                'lastUpdated': FieldValue.serverTimestamp(),
              })
              ..update(_firebasePathProvider.clientRef(clientId), {
                'totalSpent': FieldValue.increment(difference),
                'lastUpdated': FieldValue.serverTimestamp(),
              })
              ..update(_firebasePathProvider.userRef, {
                'totalEarned': FieldValue.increment(difference),
                'lastUpdated': FieldValue.serverTimestamp(),
              });
          }
        }

        _replaceDateFieldsWithTimestamps(patch);

        if (patch.isNotEmpty) {
          transaction.update(milestoneDoc, {
            ...patch,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
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
  Future<MilestoneCollectionSnapshot> getMilestones(String projectId) async {
    try {
      await NetworkUtils.authorizeUser(_auth);
      final projectRef = _firebasePathProvider.projectRef(projectId);
      for (var attempt = 0; attempt < 2; attempt++) {
        final projectBefore = await projectRef.get();
        final orderVersionBefore = _projectOrderVersion(projectBefore.data());
        final milestoneSnapshot = await _milestonesCollection(
          projectId,
        ).orderBy('rank').get();
        final projectAfter = await projectRef.get();
        final orderVersionAfter = _projectOrderVersion(projectAfter.data());

        if (orderVersionBefore == orderVersionAfter) {
          return MilestoneCollectionSnapshot(
            milestones: milestoneSnapshot.docs
                .map(
                  (milestoneDoc) => MilestoneModel.fromMap(milestoneDoc.data()),
                )
                .toList(),
            orderVersion: orderVersionAfter,
          );
        }
      }

      throw _staleOrderException();
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<
        MilestoneCollectionSnapshot
      >(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'getMilestones',
        stackTrace: e.stackTrace,
        statusCode: e.code,
        errorMessage: e.message,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      return NetworkUtils.handleRemoteSourceException<
        MilestoneCollectionSnapshot
      >(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'getMilestones',
        stackTrace: s,
        statusCode: 'PROJECT_MILESTONES_UNKNOWN',
      );
    }
  }

  @override
  Future<void> reorderMilestone({
    required String projectId,
    required String milestoneId,
    required String? previousMilestoneId,
    required String? nextMilestoneId,
    required int expectedOrderVersion,
  }) async {
    try {
      await NetworkUtils.authorizeUser(_auth);

      final projectRef = _firebasePathProvider.projectRef(projectId);
      final movedRef = _firebasePathProvider.milestoneRef(
        projectId: projectId,
        milestoneId: milestoneId,
      );
      final previousRef = previousMilestoneId == null
          ? null
          : _firebasePathProvider.milestoneRef(
              projectId: projectId,
              milestoneId: previousMilestoneId,
            );
      final nextRef = nextMilestoneId == null
          ? null
          : _firebasePathProvider.milestoneRef(
              projectId: projectId,
              milestoneId: nextMilestoneId,
            );

      try {
        await _firestore.runTransaction((transaction) async {
          final projectDoc = await transaction.get(projectRef);
          _assertProjectNotPendingDeletion(projectDoc);
          final currentVersion = _projectOrderVersion(projectDoc.data());
          if (currentVersion != expectedOrderVersion) {
            throw const _StaleOrderVersion();
          }

          final movedDoc = await transaction.get(movedRef);
          if (!movedDoc.exists) {
            throw _milestoneNotFoundException();
          }

          if (previousMilestoneId == milestoneId ||
              nextMilestoneId == milestoneId ||
              (previousMilestoneId != null &&
                  previousMilestoneId == nextMilestoneId) ||
              (previousMilestoneId == null && nextMilestoneId == null)) {
            throw _invalidTargetException();
          }

          final previousDoc = previousRef == null
              ? null
              : await transaction.get(previousRef);
          final nextDoc = nextRef == null
              ? null
              : await transaction.get(nextRef);

          if ((previousMilestoneId != null &&
                  !(previousDoc?.exists ?? false)) ||
              (nextMilestoneId != null && !(nextDoc?.exists ?? false))) {
            throw _invalidTargetException();
          }

          final previousRank = previousDoc == null
              ? null
              : _rankFromData(previousDoc.data());
          final nextRank = nextDoc == null
              ? null
              : _rankFromData(nextDoc.data());
          if (previousRank != null &&
              nextRank != null &&
              previousRank >= nextRank) {
            throw _invalidTargetException();
          }

          final newRank = _computeDirectRank(
            previousRank: previousRank,
            nextRank: nextRank,
          );

          transaction
            ..update(movedRef, {
              'rank': newRank,
              'lastUpdated': FieldValue.serverTimestamp(),
            })
            ..update(projectRef, {
              'milestoneOrderVersion': currentVersion + 1,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
        });
        return;
      } on _StaleOrderVersion {
        throw _staleOrderException();
      } on _RebalanceRequired {
        // fall through to the full rebalance path below
      }

      final projectSnapshot = await projectRef.get();
      final preRebalanceVersion = _projectOrderVersion(projectSnapshot.data());
      if (preRebalanceVersion != expectedOrderVersion) {
        throw _staleOrderException();
      }

      final orderedSnapshot = await _milestonesCollection(
        projectId,
      ).orderBy('rank').get();
      if (orderedSnapshot.docs.length > _kMaxRebalanceMilestones) {
        throw _rebalanceLimitException();
      }

      final plannedOrder = _applyReorderPlan(
        orderedDocs: orderedSnapshot.docs,
        milestoneId: milestoneId,
        previousMilestoneId: previousMilestoneId,
        nextMilestoneId: nextMilestoneId,
      );

      await _firestore.runTransaction((transaction) async {
        final projectDoc = await transaction.get(projectRef);
        _assertProjectNotPendingDeletion(projectDoc);
        final currentVersion = _projectOrderVersion(projectDoc.data());
        if (currentVersion != expectedOrderVersion) {
          throw const _StaleOrderVersion();
        }

        for (final doc in plannedOrder) {
          final existing = await transaction.get(doc.reference);
          if (!existing.exists) {
            throw _invalidTargetException();
          }
        }

        for (final entry in plannedOrder.indexed) {
          transaction.update(entry.$2.reference, {
            'rank': _rebalancedRankForPosition(entry.$1),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        transaction.update(projectRef, {
          'milestoneOrderVersion': currentVersion + 1,
          'milestoneOrderLastRebalancedAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
    } on _StaleOrderVersion {
      throw _staleOrderException();
    } on FirebaseException catch (e) {
      return NetworkUtils.handleRemoteSourceException<void>(
        e,
        repositoryName: 'MilestoneRemoteDataSrcImpl',
        methodName: 'reorderMilestone',
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
        methodName: 'reorderMilestone',
        stackTrace: s,
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
      await _firestore.runTransaction((transaction) async {
        final projectDoc = await transaction.get(projectRef);
        if (!projectDoc.exists) {
          throw _milestoneNotFoundException();
        }
        _assertProjectNotPendingDeletion(projectDoc);
        final projectData = projectDoc.data();
        final clientId = projectData?['clientId'] as String?;
        if (clientId == null || clientId.isEmpty) {
          throw const ServerException(
            message: 'Project client not found',
            statusCode: 'PROJECT_CLIENT_NOT_FOUND',
          );
        }
        final milestoneData = await transaction.get(milestoneDoc);
        final amountPaid =
            (milestoneData.data()?['amountPaid'] as num?)?.toDouble() ?? 0.0;
        final currentVersion = _projectOrderVersion(projectDoc.data());

        transaction
          ..delete(milestoneDoc)
          ..update(projectRef, {
            'totalPaid': FieldValue.increment(-amountPaid),
            'numberOfMilestonesSoFar': FieldValue.increment(-1),
            'milestoneOrderVersion': currentVersion + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          })
          ..update(_firebasePathProvider.clientRef(clientId), {
            'totalSpent': FieldValue.increment(-amountPaid),
            'lastUpdated': FieldValue.serverTimestamp(),
          })
          ..update(_firebasePathProvider.userRef, {
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
        statusCode: _kMilestoneDetailsNotFoundCode,
      );
    }
  }
}
