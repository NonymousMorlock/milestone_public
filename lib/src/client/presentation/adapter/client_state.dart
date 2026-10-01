part of 'client_cubit.dart';

sealed class ClientState extends Equatable {
  const ClientState();

  @override
  List<Object?> get props => [];
}

final class ClientInitial extends ClientState {
  const ClientInitial();
}

final class ClientLoading extends ClientState {
  /// This will cover for add, delete, edit, and all two fetch states
  /// (getClient, getClients).
  ///
  /// For the loading state of `getClientProjects`, use
  /// `ClientProjectsLoading` instead.
  const ClientLoading();
}

final class ClientWorkspaceListLoading extends ClientState {
  const ClientWorkspaceListLoading();
}

final class ClientWorkspaceLoading extends ClientState {
  const ClientWorkspaceLoading();
}

final class ClientProjectsLoading extends ClientState {
  const ClientProjectsLoading();
}

final class ClientLoaded extends ClientState {
  const ClientLoaded(this.client);

  final Client client;

  @override
  List<Object> get props => [client];
}

final class ClientsLoaded extends ClientState {
  const ClientsLoaded(this.clients);

  final List<Client> clients;

  @override
  List<Object> get props => [clients];
}

final class ClientWorkspaceListLoaded extends ClientState {
  const ClientWorkspaceListLoaded(this.summaries);

  final List<ClientWorkspaceSnapshotLayout> summaries;

  @override
  List<Object> get props => [summaries];
}

final class ClientProjectsLoaded extends ClientState {
  const ClientProjectsLoaded(this.projects);

  final List<Project> projects;

  @override
  List<Object> get props => [projects];
}

final class ClientAdded extends ClientState {
  const ClientAdded(this.client);

  final Client client;

  @override
  List<Object> get props => [client];
}

final class ClientDeleted extends ClientState {
  const ClientDeleted();
}

final class ClientUpdated extends ClientState {
  const ClientUpdated();
}

final class ClientWorkspaceActionFailure extends Equatable {
  const ClientWorkspaceActionFailure({
    required this.title,
    required this.message,
    required this.statusCode,
  });

  final String title;
  final String message;
  final String statusCode;

  @override
  List<Object> get props => [title, message, statusCode];
}

final class ClientWorkspaceLoaded extends ClientState {
  const ClientWorkspaceLoaded({
    required this.snapshot,
    required this.projects,
    required this.isDeleting,
    required this.isRefreshing,
    this.actionFailure,
  });

  final ClientWorkspaceSnapshotLayout snapshot;
  final List<Project> projects;
  final bool isDeleting;
  final bool isRefreshing;
  final ClientWorkspaceActionFailure? actionFailure;

  bool get isMutationBusy => isDeleting || isRefreshing;

  ClientWorkspaceLoaded copyWith({
    ClientWorkspaceSnapshotLayout? snapshot,
    List<Project>? projects,
    bool? isDeleting,
    bool? isRefreshing,
    Object? actionFailure = _clientStateSentinel,
  }) {
    return ClientWorkspaceLoaded(
      snapshot: snapshot ?? this.snapshot,
      projects: projects ?? this.projects,
      isDeleting: isDeleting ?? this.isDeleting,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      actionFailure: actionFailure == _clientStateSentinel
          ? this.actionFailure
          : actionFailure as ClientWorkspaceActionFailure?,
    );
  }

  @override
  List<Object?> get props => [
    snapshot,
    projects,
    isDeleting,
    isRefreshing,
    actionFailure,
  ];
}

final class ClientEditActionFailure extends Equatable {
  const ClientEditActionFailure({
    required this.title,
    required this.message,
    required this.statusCode,
  });

  final String title;
  final String message;
  final String statusCode;

  @override
  List<Object> get props => [title, message, statusCode];
}

final class ClientEditLoaded extends ClientState {
  const ClientEditLoaded({
    required this.client,
    required this.isSaving,
    this.actionFailure,
  });

  final Client client;
  final bool isSaving;
  final ClientEditActionFailure? actionFailure;

  ClientEditLoaded copyWith({
    Client? client,
    bool? isSaving,
    Object? actionFailure = _clientStateSentinel,
  }) {
    return ClientEditLoaded(
      client: client ?? this.client,
      isSaving: isSaving ?? this.isSaving,
      actionFailure: actionFailure == _clientStateSentinel
          ? this.actionFailure
          : actionFailure as ClientEditActionFailure?,
    );
  }

  @override
  List<Object?> get props => [client, isSaving, actionFailure];
}

final class ClientError extends ClientState {
  const ClientError({
    required this.title,
    required this.message,
    this.statusCode,
  });

  final String message;
  final String title;
  final String? statusCode;

  @override
  List<Object?> get props => [title, message, statusCode];
}

const _clientStateSentinel = Object();
