import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/repos/project_repo.dart';

class GetUserTools implements UsecaseWithoutParams<List<String>> {
  const GetUserTools(this._repo);

  final ProjectRepo _repo;

  @override
  ResultFuture<List<String>> call() => _repo.getUserTools();
}
