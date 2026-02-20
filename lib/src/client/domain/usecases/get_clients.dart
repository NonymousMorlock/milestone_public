import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/domain/repos/client_repo.dart';

class GetClients extends UsecaseWithoutParams<List<Client>> {
  const GetClients(this._repo);

  final ClientRepo _repo;

  @override
  ResultFuture<List<Client>> call() => _repo.getClients();
}
