part of 'client_cubit.dart';

abstract class ClientState extends Equatable {
  const ClientState();

  @override
  List<Object> get props => [];
}

class ClientInitial extends ClientState {
  const ClientInitial();
}

class ClientLoading extends ClientState {
  /// This will cover for add, delete, edit, and all two fetch states
  /// (getClient, getClients).
  ///
  /// For the loading state of `getClientProjects`, use
  /// `ClientProjectsLoading` instead.
  const ClientLoading();
}

class ClientProjectsLoading extends ClientState {
  const ClientProjectsLoading();
}

class ClientLoaded extends ClientState {
  const ClientLoaded(this.client);

  final Client client;

  @override
  List<Object> get props => [client];
}

class ClientsLoaded extends ClientState {
  const ClientsLoaded(this.clients);

  final List<Client> clients;

  @override
  List<Object> get props => [clients];
}

class ClientProjectsLoaded extends ClientState {
  const ClientProjectsLoaded(this.projects);

  final List<Project> projects;

  @override
  List<Object> get props => [projects];
}

class ClientAdded extends ClientState {
  const ClientAdded(this.client);

  final Client client;

  @override
  List<Object> get props => [client];
}

class ClientDeleted extends ClientState {
  const ClientDeleted();
}

class ClientUpdated extends ClientState {
  const ClientUpdated();
}

class ClientError extends ClientState {
  const ClientError({required this.title, required this.message});

  final String message;
  final String title;

  @override
  List<Object> get props => [title, message];
}
