import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone_collection_snapshot.dart';
import 'package:milestone/src/project/features/milestone/domain/repos/milestone_repo.dart';

class GetMilestones
    implements UsecaseWithParams<MilestoneCollectionSnapshot, String> {
  const GetMilestones(this._repo);

  final MilestoneRepo _repo;

  @override
  ResultFuture<MilestoneCollectionSnapshot> call(String params) =>
      _repo.getMilestones(params);
}
