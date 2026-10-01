import 'package:equatable/equatable.dart';
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/repos/milestone_repo.dart';

class ReorderMilestone
    implements UsecaseWithParams<void, ReorderMilestoneParams> {
  const ReorderMilestone(this._repo);

  final MilestoneRepo _repo;

  @override
  ResultFuture<void> call(ReorderMilestoneParams params) =>
      _repo.reorderMilestone(
        projectId: params.projectId,
        milestoneId: params.milestoneId,
        previousMilestoneId: params.previousMilestoneId,
        nextMilestoneId: params.nextMilestoneId,
        expectedOrderVersion: params.expectedOrderVersion,
      );
}

class ReorderMilestoneParams extends Equatable {
  const ReorderMilestoneParams({
    required this.projectId,
    required this.milestoneId,
    required this.previousMilestoneId,
    required this.nextMilestoneId,
    required this.expectedOrderVersion,
  });

  const ReorderMilestoneParams.empty()
    : this(
        projectId: 'Test String',
        milestoneId: 'Test String',
        previousMilestoneId: null,
        nextMilestoneId: null,
        expectedOrderVersion: 0,
      );

  final String projectId;
  final String milestoneId;
  final String? previousMilestoneId;
  final String? nextMilestoneId;
  final int expectedOrderVersion;

  @override
  List<Object?> get props => [
    projectId,
    milestoneId,
    previousMilestoneId,
    nextMilestoneId,
    expectedOrderVersion,
  ];
}
