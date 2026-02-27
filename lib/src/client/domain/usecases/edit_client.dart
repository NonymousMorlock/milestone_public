import 'package:equatable/equatable.dart';
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/domain/repos/client_repo.dart';

class EditClient extends UsecaseWithParams<void, EditClientParams> {
  const EditClient(this._repo);

  final ClientRepo _repo;

  @override
  ResultFuture<void> call(EditClientParams params) => _repo.editClient(
        clientId: params.clientId,
        updatedClient: params.updatedClient,
      );
}

class EditClientParams extends Equatable {
  const EditClientParams({
    required this.clientId,
    required this.updatedClient,
  });

  EditClientParams.empty() : this(clientId: 'Test String', updatedClient: {});

  final String clientId;
  final Map<String, dynamic> updatedClient;

  @override
  List<dynamic> get props => [
        clientId,
        updatedClient,
      ];
}
