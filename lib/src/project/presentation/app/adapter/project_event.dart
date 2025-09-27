part of 'project_bloc.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

// Using the dollar sign to avoid conflict with usecase class names
class $AddProject extends ProjectEvent {
  const $AddProject(this.project);

  final Project project;

  @override
  List<Object> get props => [project];
}

class $DeleteProject extends ProjectEvent {
  const $DeleteProject(this.projectID);

  final String projectID;

  @override
  List<Object> get props => [projectID];
}

class $EditProjectDetails extends ProjectEvent {
  const $EditProjectDetails({
    required this.projectId,
    required this.updatedProject,
  });

  final String projectId;
  final DataMap updatedProject;

  @override
  List<Object> get props => [projectId, updatedProject];
}

class $GetProjectById extends ProjectEvent {
  const $GetProjectById(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

class $GetProjects extends ProjectEvent {
  const $GetProjects({this.detailed = true, this.limit});

  final bool detailed;
  final int? limit;

  @override
  List<Object?> get props => [detailed, limit];
}
