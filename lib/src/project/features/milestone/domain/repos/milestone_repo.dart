import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone_collection_snapshot.dart';

abstract interface class MilestoneRepo {
  ResultFuture<void> addMilestone(Milestone milestone);

  ResultFuture<void> editMilestone({
    required String projectId,
    required String milestoneId,
    required DataMap updatedMilestone,
  });

  ResultFuture<MilestoneCollectionSnapshot> getMilestones(String projectId);

  ResultFuture<void> reorderMilestone({
    required String projectId,
    required String milestoneId,
    required String? previousMilestoneId,
    required String? nextMilestoneId,
    required int expectedOrderVersion,
  });

  ResultFuture<void> deleteMilestone({
    required String projectId,
    required String milestoneId,
  });

  ResultFuture<Milestone> getMilestoneById({
    required String projectId,
    required String milestoneId,
  });
}
