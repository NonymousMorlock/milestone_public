part of 'project_bloc.dart';

sealed class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object> get props => [];
}

final class ProjectInitial extends ProjectState {
  const ProjectInitial();
}

final class ProjectLoading extends ProjectState {
  const ProjectLoading();
}

final class ProjectAdded extends ProjectState {
  const ProjectAdded();
}

final class ProjectDeleted extends ProjectState {
  const ProjectDeleted();
}

final class ProjectUpdated extends ProjectState {
  const ProjectUpdated();
}

final class ProjectLoaded extends ProjectState {
  const ProjectLoaded(this.project);

  final Project project;

  @override
  List<Object> get props => [project];
}

final class ProjectsLoaded extends ProjectState {
  const ProjectsLoaded(this.projects);

  final List<Project> projects;

  @override
  List<Object> get props => projects;
}

final class UserToolsLoaded extends ProjectState {
  const UserToolsLoaded(this.tools);

  final List<String> tools;

  @override
  List<Object> get props => tools;
}

final class UserToolRemoved extends ProjectState {
  const UserToolRemoved();
}

final class ProjectError extends ProjectState {
  const ProjectError({
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
