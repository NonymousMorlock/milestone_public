import 'package:equatable/equatable.dart';
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/repos/milestone_repo.dart';

class GetMilestoneById
    extends UsecaseWithParams<Milestone, GetMilestoneByIdParams> {
  const GetMilestoneById(this._repo);

  final MilestoneRepo _repo;

  @override
  ResultFuture<Milestone> call(GetMilestoneByIdParams params) =>
      _repo.getMilestoneById(
        projectId: params.projectId,
        milestoneId: params.milestoneId,
      );
}

class GetMilestoneByIdParams extends Equatable {
  const GetMilestoneByIdParams({
    required this.projectId,
    required this.milestoneId,
  });

  const GetMilestoneByIdParams.empty()
      : this(projectId: 'Test String', milestoneId: 'Test String');

  final String projectId;
  final String milestoneId;

  @override
  List<dynamic> get props => [
        projectId,
        milestoneId,
      ];
}
