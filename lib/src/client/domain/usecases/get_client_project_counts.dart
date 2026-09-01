import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/domain/repos/client_repo.dart';

class GetClientProjectCounts implements UsecaseWithoutParams<Map<String, int>> {
  const GetClientProjectCounts(this._repo);

  final ClientRepo _repo;

  @override
  ResultFuture<Map<String, int>> call() => _repo.getClientProjectCounts();
}
