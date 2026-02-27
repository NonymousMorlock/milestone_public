import 'package:equatable/equatable.dart';
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/repos/milestone_repo.dart';

class DeleteMilestone extends UsecaseWithParams<void, DeleteMilestoneParams> {
  const DeleteMilestone(this._repo);

  final MilestoneRepo _repo;

  @override
  ResultFuture<void> call(DeleteMilestoneParams params) =>
      _repo.deleteMilestone(
        projectId: params.projectId,
        milestoneId: params.milestoneId,
      );
}

class DeleteMilestoneParams extends Equatable {
  const DeleteMilestoneParams({
    required this.projectId,
    required this.milestoneId,
  });

  const DeleteMilestoneParams.empty()
      : this(projectId: 'Test String', milestoneId: 'Test String');

  final String projectId;
  final String milestoneId;

  @override
  List<dynamic> get props => [
        projectId,
        milestoneId,
      ];
}
