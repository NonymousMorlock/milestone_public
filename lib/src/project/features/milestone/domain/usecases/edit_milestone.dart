import 'package:equatable/equatable.dart';
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/repos/milestone_repo.dart';

class EditMilestone extends UsecaseWithParams<void, EditMilestoneParams> {
  const EditMilestone(this._repo);

  final MilestoneRepo _repo;

  @override
  ResultFuture<void> call(EditMilestoneParams params) => _repo.editMilestone(
        projectId: params.projectId,
        milestoneId: params.milestoneId,
        updatedMilestone: params.updatedMilestone,
      );
}

class EditMilestoneParams extends Equatable {
  const EditMilestoneParams({
    required this.projectId,
    required this.milestoneId,
    required this.updatedMilestone,
  });

  EditMilestoneParams.empty()
      : this(
          projectId: 'Test String',
          milestoneId: 'Test String',
          updatedMilestone: {},
        );

  final String projectId;
  final String milestoneId;
  final Map<String, dynamic> updatedMilestone;

  @override
  List<dynamic> get props => [
        projectId,
        milestoneId,
        updatedMilestone,
      ];
}
