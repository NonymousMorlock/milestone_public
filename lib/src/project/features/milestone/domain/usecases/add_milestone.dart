import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/repos/milestone_repo.dart';

class AddMilestone extends UsecaseWithParams<void, Milestone> {
  const AddMilestone(this._repo);

  final MilestoneRepo _repo;

  @override
  ResultFuture<void> call(Milestone params) => _repo.addMilestone(params);
}
