import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';

abstract class MilestoneRepo {
  ResultFuture<void> addMilestone(Milestone milestone);

  ResultFuture<void> editMilestone({
    required String projectId,
    required String milestoneId,
    required DataMap updatedMilestone,
  });

  ResultFuture<List<Milestone>> getMilestones(String projectId);

  ResultFuture<void> deleteMilestone({
    required String projectId,
    required String milestoneId,
  });

  ResultFuture<Milestone> getMilestoneById({
    required String projectId,
    required String milestoneId,
  });
}
