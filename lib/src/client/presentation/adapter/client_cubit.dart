import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/domain/usecases/add_client.dart';
import 'package:milestone/src/client/domain/usecases/delete_client.dart';
import 'package:milestone/src/client/domain/usecases/edit_client.dart';
import 'package:milestone/src/client/domain/usecases/get_client_by_id.dart';
import 'package:milestone/src/client/domain/usecases/get_client_projects.dart';
import 'package:milestone/src/client/domain/usecases/get_clients.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

part 'client_state.dart';

class ClientCubit extends Cubit<ClientState> {
  ClientCubit({
    required AddClient addClient,
    required DeleteClient deleteClient,
    required EditClient editClient,
    required GetClientById getClientById,
    required GetClientProjects getClientProjects,
    required GetClients getClients,
  })  : _addClient = addClient,
        _deleteClient = deleteClient,
        _editClient = editClient,
        _getClientById = getClientById,
        _getClientProjects = getClientProjects,
        _getClients = getClients,
        super(const ClientInitial());

  final AddClient _addClient;
  final DeleteClient _deleteClient;
  final EditClient _editClient;
  final GetClientById _getClientById;
  final GetClientProjects _getClientProjects;
  final GetClients _getClients;

  Future<void> addClient(Client client) async {
    emit(const ClientLoading());
    final result = await _addClient(client);
    result.fold(
      (failure) => emit(
        ClientError(
          title: 'Error Adding Client',
          message: failure.errorMessage,
        ),
      ),
      (client) => emit(ClientAdded(client)),
    );
  }

  Future<void> deleteClient(String clientID) async {
    emit(const ClientLoading());
    final result = await _deleteClient(clientID);
    result.fold(
      (failure) => emit(
        ClientError(
          title: 'Error Deleting Client',
          message: failure.errorMessage,
        ),
      ),
      (_) => emit(const ClientDeleted()),
    );
  }

  Future<void> editClient({
    required String clientId,
    required DataMap updatedClient,
  }) async {
    emit(const ClientLoading());
    final result = await _editClient(
      EditClientParams(
        clientId: clientId,
        updatedClient: updatedClient,
      ),
    );
    result.fold(
      (failure) => emit(
        ClientError(
          title: 'Error Editing Client',
          message: failure.errorMessage,
        ),
      ),
      (_) => emit(const ClientUpdated()),
    );
  }

  Future<void> getClientById(String clientId) async {
    emit(const ClientLoading());
    final result = await _getClientById(clientId);
    result.fold(
      (failure) => emit(
        ClientError(
          title: 'Error Fetching Client',
          message: failure.errorMessage,
        ),
      ),
      (client) => emit(ClientLoaded(client)),
    );
  }

  Future<void> getClientProjects({
    required String clientId,
    required bool detailed,
  }) async {
    emit(const ClientProjectsLoading());
    final result = await _getClientProjects(
      GetClientProjectsParams(
        clientId: clientId,
        detailed: detailed,
      ),
    );
    result.fold(
      (failure) => emit(
        ClientError(
          title: 'Error Fetching Client Projects',
          message: failure.errorMessage,
        ),
      ),
      (projects) => emit(ClientProjectsLoaded(projects)),
    );
  }

  Future<void> getClients() async {
    emit(const ClientLoading());
    final result = await _getClients();
    result.fold(
      (failure) => emit(
        ClientError(
          title: 'Error Fetching Clients',
          message: failure.errorMessage,
        ),
      ),
      (clients) => emit(ClientsLoaded(clients)),
    );
  }
}
