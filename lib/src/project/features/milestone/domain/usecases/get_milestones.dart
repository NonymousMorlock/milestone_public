import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/repos/milestone_repo.dart';

class GetMilestones extends UsecaseWithParams<List<Milestone>, String> {
  const GetMilestones(this._repo);

  final MilestoneRepo _repo;

  @override
  ResultFuture<List<Milestone>> call(String params) =>
      _repo.getMilestones(params);
}
