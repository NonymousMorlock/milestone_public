import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/domain/repos/client_repo.dart';

class GetClientById extends UsecaseWithParams<Client, String> {
  const GetClientById(this._repo);

  final ClientRepo _repo;

  @override
  ResultFuture<Client> call(String params) => _repo.getClientById(params);
}
