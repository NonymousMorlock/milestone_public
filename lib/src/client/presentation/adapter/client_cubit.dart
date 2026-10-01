import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/domain/usecases/add_client.dart';
import 'package:milestone/src/client/domain/usecases/delete_client.dart';
import 'package:milestone/src/client/domain/usecases/edit_client.dart';
import 'package:milestone/src/client/domain/usecases/get_client_by_id.dart';
import 'package:milestone/src/client/domain/usecases/get_client_project_counts.dart';
import 'package:milestone/src/client/domain/usecases/get_client_projects.dart';
import 'package:milestone/src/client/domain/usecases/get_clients.dart';
import 'package:milestone/src/client/presentation/layout/client_workspace_snapshot_layout.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

part 'client_state.dart';

class ClientCubit extends Cubit<ClientState> {
  ClientCubit({
    required AddClient addClient,
    required DeleteClient deleteClient,
    required EditClient editClient,
    required GetClientById getClientById,
    required GetClientProjectCounts getClientProjectCounts,
    required GetClientProjects getClientProjects,
    required GetClients getClients,
  }) : _addClient = addClient,
       _deleteClient = deleteClient,
       _editClient = editClient,
       _getClientById = getClientById,
       _getClientProjectCounts = getClientProjectCounts,
       _getClientProjects = getClientProjects,
       _getClients = getClients,
       super(const ClientInitial());

  final AddClient _addClient;
  final DeleteClient _deleteClient;
  final EditClient _editClient;
  final GetClientById _getClientById;
  final GetClientProjectCounts _getClientProjectCounts;
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
          statusCode: failure.statusCode,
        ),
      ),
      (client) => emit(ClientAdded(client)),
    );
  }

  Future<void> deleteClient(String clientID) async {
    final currentWorkspace = switch (state) {
      ClientWorkspaceLoaded() => state as ClientWorkspaceLoaded,
      _ => null,
    };

    if (currentWorkspace?.isMutationBusy == true) {
      return;
    }

    if (currentWorkspace != null) {
      emit(
        currentWorkspace.copyWith(
          isDeleting: true,
          isRefreshing: false,
          actionFailure: null,
        ),
      );
    } else {
      emit(const ClientLoading());
    }

    final result = await _deleteClient(clientID);
    await result.fold<Future<void>>(
      (failure) async {
        if (currentWorkspace != null &&
            failure.statusCode == _kClientLinkedProjectsConflictCode) {
          emit(
            currentWorkspace.copyWith(
              isDeleting: false,
              isRefreshing: true,
              actionFailure: null,
            ),
          );
          await _reloadWorkspaceAfterDeleteConflict(
            clientId: clientID,
            failure: ClientWorkspaceActionFailure(
              title: 'Error Deleting Client',
              message: failure.errorMessage,
              statusCode: failure.statusCode,
            ),
          );
          return;
        }

        if (currentWorkspace != null) {
          emit(
            currentWorkspace.copyWith(
              isDeleting: false,
              isRefreshing: false,
              actionFailure: ClientWorkspaceActionFailure(
                title: 'Error Deleting Client',
                message: failure.errorMessage,
                statusCode: failure.statusCode,
              ),
            ),
          );
          return;
        }

        emit(
          ClientError(
            title: 'Error Deleting Client',
            message: failure.errorMessage,
            statusCode: failure.statusCode,
          ),
        );
      },
      (_) async {
        emit(const ClientDeleted());
      },
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
          statusCode: failure.statusCode,
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
          statusCode: failure.statusCode,
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
          statusCode: failure.statusCode,
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
          statusCode: failure.statusCode,
        ),
      ),
      (clients) => emit(ClientsLoaded(clients)),
    );
  }

  Future<void> getClientWorkspaceList() async {
    emit(const ClientWorkspaceListLoading());

    final clientsFuture = _getClients();
    final countsFuture = _getClientProjectCounts();

    final clientsResult = await clientsFuture;
    final countsResult = await countsFuture;

    await clientsResult.fold<Future<void>>(
      (failure) async {
        emit(
          ClientError(
            title: 'Error Fetching Clients',
            message: failure.errorMessage,
            statusCode: failure.statusCode,
          ),
        );
      },
      (clients) async {
        await countsResult.fold<Future<void>>(
          (failure) async {
            emit(
              ClientError(
                title: 'Error Fetching Client Summaries',
                message: failure.errorMessage,
                statusCode: failure.statusCode,
              ),
            );
          },
          (counts) async {
            final summaries = clients.map((client) {
              return ClientWorkspaceSnapshotLayout(
                clientId: client.id,
                clientName: client.name,
                totalSpent: client.totalSpent,
                projectCount: counts[client.id] ?? 0,
                clientImage: client.image,
              );
            }).toList();

            emit(ClientWorkspaceListLoaded(summaries));
          },
        );
      },
    );
  }

  Future<void> getClientWorkspace(String clientId) async {
    emit(const ClientWorkspaceLoading());

    final clientResult = await _getClientById(clientId);
    Client? client;
    clientResult.fold(
      (failure) => emit(
        ClientError(
          title: 'Error Fetching Client',
          message: failure.errorMessage,
          statusCode: failure.statusCode,
        ),
      ),
      (loadedClient) => client = loadedClient,
    );
    if (client == null) {
      return;
    }
    final loadedClient = client!;

    final projectsResult = await _getClientProjects(
      GetClientProjectsParams(clientId: clientId, detailed: true),
    );
    projectsResult.fold(
      (failure) => emit(
        ClientError(
          title: 'Error Fetching Client Projects',
          message: failure.errorMessage,
          statusCode: failure.statusCode,
        ),
      ),
      (projects) {
        emit(
          ClientWorkspaceLoaded(
            snapshot: ClientWorkspaceSnapshotLayout(
              clientId: loadedClient.id,
              clientName: loadedClient.name,
              totalSpent: loadedClient.totalSpent,
              projectCount: projects.length,
              clientImage: loadedClient.image,
            ),
            projects: projects,
            isDeleting: false,
            isRefreshing: false,
          ),
        );
      },
    );
  }

  Future<void> bootstrapClientEdit(String clientId) async {
    emit(const ClientLoading());

    final result = await _getClientById(clientId);
    result.fold(
      (failure) => emit(
        ClientError(
          title: 'Error Fetching Client',
          message: failure.errorMessage,
          statusCode: failure.statusCode,
        ),
      ),
      (client) => emit(
        ClientEditLoaded(
          client: client,
          isSaving: false,
        ),
      ),
    );
  }

  Future<void> saveClientEdit({
    required String clientId,
    required DataMap updatedClient,
  }) async {
    final currentEdit = switch (state) {
      ClientEditLoaded() => state as ClientEditLoaded,
      _ => null,
    };

    if (currentEdit?.isSaving == true) {
      return;
    }

    if (currentEdit != null) {
      emit(currentEdit.copyWith(isSaving: true, actionFailure: null));
    } else {
      emit(const ClientLoading());
    }

    final result = await _editClient(
      EditClientParams(clientId: clientId, updatedClient: updatedClient),
    );

    result.fold(
      (failure) {
        if (currentEdit != null) {
          emit(
            currentEdit.copyWith(
              isSaving: false,
              actionFailure: ClientEditActionFailure(
                title: 'Error Editing Client',
                message: failure.errorMessage,
                statusCode: failure.statusCode,
              ),
            ),
          );
          return;
        }

        emit(
          ClientError(
            title: 'Error Editing Client',
            message: failure.errorMessage,
            statusCode: failure.statusCode,
          ),
        );
      },
      (_) => emit(const ClientUpdated()),
    );
  }

  Future<void> _reloadWorkspaceAfterDeleteConflict({
    required String clientId,
    required ClientWorkspaceActionFailure failure,
  }) async {
    final clientResult = await _getClientById(clientId);
    Client? client;
    clientResult.fold(
      (clientFailure) {
        if (clientFailure.statusCode == _kClientNotFoundCode) {
          emit(
            ClientError(
              title: 'Client unavailable',
              message: clientFailure.errorMessage,
              statusCode: clientFailure.statusCode,
            ),
          );
          return;
        }

        emit(
          const ClientError(
            title: 'Unable to refresh client workspace',
            message:
                'Delete was blocked because linked projects exist, but the '
                'latest workspace could not be reloaded.',
            statusCode: _kClientWorkspaceRefreshAfterDeleteConflictFailedCode,
          ),
        );
      },
      (loadedClient) => client = loadedClient,
    );

    if (client == null) {
      return;
    }
    final loadedClient = client!;

    final projectsResult = await _getClientProjects(
      GetClientProjectsParams(clientId: clientId, detailed: true),
    );
    projectsResult.fold(
      (_) => emit(
        const ClientError(
          title: 'Unable to refresh client workspace',
          message:
              'Delete was blocked because linked projects exist, but the '
              'latest workspace could not be reloaded.',
          statusCode: _kClientWorkspaceRefreshAfterDeleteConflictFailedCode,
        ),
      ),
      (projects) {
        emit(
          ClientWorkspaceLoaded(
            snapshot: ClientWorkspaceSnapshotLayout(
              clientId: loadedClient.id,
              clientName: loadedClient.name,
              totalSpent: loadedClient.totalSpent,
              projectCount: projects.length,
              clientImage: loadedClient.image,
            ),
            projects: projects,
            isDeleting: false,
            isRefreshing: false,
            actionFailure: failure,
          ),
        );
      },
    );
  }
}

const _kClientLinkedProjectsConflictCode = 'client-linked-projects-conflict';
const _kClientNotFoundCode = 'CLIENT_NOT_FOUND';
const _kClientWorkspaceRefreshAfterDeleteConflictFailedCode =
    'client-workspace-refresh-after-delete-conflict-failed';
