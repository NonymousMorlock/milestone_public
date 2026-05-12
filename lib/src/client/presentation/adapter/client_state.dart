part of 'client_cubit.dart';

sealed class ClientState extends Equatable {
  const ClientState();

  @override
  List<Object> get props => [];
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

final class ClientError extends ClientState {
  const ClientError({required this.title, required this.message});

  final String message;
  final String title;

  @override
  List<Object> get props => [title, message];
}
