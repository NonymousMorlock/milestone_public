// Only work if client has no activity yet
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/domain/repos/client_repo.dart';

class DeleteClient extends UsecaseWithParams<void, String> {
  const DeleteClient(this._repo);

  final ClientRepo _repo;

  @override
  ResultFuture<void> call(String params) => _repo.deleteClient(params);
}
