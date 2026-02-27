part of 'project_bloc.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object> get props => [];
}

class ProjectInitial extends ProjectState {
  const ProjectInitial();
}

class ProjectLoading extends ProjectState {
  const ProjectLoading();
}

class ProjectAdded extends ProjectState {
  const ProjectAdded();
}

class ProjectDeleted extends ProjectState {
  const ProjectDeleted();
}

class ProjectUpdated extends ProjectState {
  const ProjectUpdated();
}

class ProjectLoaded extends ProjectState {
  const ProjectLoaded(this.project);

  final Project project;

  @override
  List<Object> get props => [project];
}

class ProjectsLoaded extends ProjectState {
  const ProjectsLoaded(this.projects);

  final List<Project> projects;

  @override
  List<Object> get props => [projects];
}

class ProjectError extends ProjectState {
  const ProjectError({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  List<Object> get props => [title, message];
}
