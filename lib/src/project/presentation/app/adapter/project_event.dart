part of 'project_bloc.dart';

sealed class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

// Using the dollar sign to avoid conflict with usecase class names
final class AddProjectEvent extends ProjectEvent {
  const AddProjectEvent(this.project);

  final Project project;

  @override
  List<Object> get props => [project];
}

final class DeleteProjectEvent extends ProjectEvent {
  const DeleteProjectEvent(this.projectID);

  final String projectID;

  @override
  List<Object> get props => [projectID];
}

final class EditProjectDetailsEvent extends ProjectEvent {
  const EditProjectDetailsEvent({
    required this.projectId,
    required this.updateData,
  });

  final String projectId;
  final DataMap updateData;

  @override
  List<Object> get props => [projectId, updateData];
}

final class GetProjectByIdEvent extends ProjectEvent {
  const GetProjectByIdEvent(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

final class GetProjectsEvent extends ProjectEvent {
  const GetProjectsEvent({
    this.detailed = true,
    this.limit,
    this.excludePendingDeletion = false,
  });

  final bool detailed;
  final int? limit;
  final bool excludePendingDeletion;

  @override
  List<Object?> get props => [detailed, limit, excludePendingDeletion];
}

final class GetUserToolsEvent extends ProjectEvent {
  const GetUserToolsEvent();
}

final class RemoveUserToolEvent extends ProjectEvent {
  const RemoveUserToolEvent(this.toolName);

  final String toolName;

  @override
  List<Object> get props => [toolName];
}
