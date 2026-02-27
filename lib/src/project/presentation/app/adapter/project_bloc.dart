import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/usecases/add_project.dart';
import 'package:milestone/src/project/domain/usecases/delete_project.dart';
import 'package:milestone/src/project/domain/usecases/edit_project_details.dart';
import 'package:milestone/src/project/domain/usecases/get_project_by_id.dart';
import 'package:milestone/src/project/domain/usecases/get_projects.dart';

part 'project_event.dart';

part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  ProjectBloc({
    required AddProject addProject,
    required DeleteProject deleteProject,
    required EditProjectDetails editProjectDetails,
    required GetProjectById getProjectById,
    required GetProjects getProjects,
  })  : _addProject = addProject,
        _deleteProject = deleteProject,
        _editProjectDetails = editProjectDetails,
        _getProjectById = getProjectById,
        _getProjects = getProjects,
        super(const ProjectInitial()) {
    on<ProjectEvent>((_, emit) => emit(const ProjectLoading()));
    on<$AddProject>(_addProjectHandler);
    on<$DeleteProject>(_deleteProjectHandler);
    on<$EditProjectDetails>(_editProjectDetailsHandler);
    on<$GetProjectById>(_getProjectByIdHandler);
    on<$GetProjects>(_getProjectsHandler);
  }

  final AddProject _addProject;
  final DeleteProject _deleteProject;
  final EditProjectDetails _editProjectDetails;
  final GetProjectById _getProjectById;
  final GetProjects _getProjects;

  Future<void> _addProjectHandler(
    $AddProject event,
    Emitter<ProjectState> emit,
  ) async {
    final result = await _addProject(event.project);
    result.fold(
      (failure) => emit(
        ProjectError(
          title: 'Error Adding Project',
          message: failure.errorMessage,
        ),
      ),
      (projectID) => emit(const ProjectAdded()),
    );
  }

  Future<void> _deleteProjectHandler(
    $DeleteProject event,
    Emitter<ProjectState> emit,
  ) async {
    final result = await _deleteProject(event.projectID);
    result.fold(
      (failure) => emit(
        ProjectError(
          title: 'Error Deleting Project',
          message: failure.errorMessage,
        ),
      ),
      (_) => emit(const ProjectDeleted()),
    );
  }

  Future<void> _editProjectDetailsHandler(
    $EditProjectDetails event,
    Emitter<ProjectState> emit,
  ) async {
    final result = await _editProjectDetails(
      EditProjectDetailsParams(
        projectId: event.projectId,
        updatedProject: event.updatedProject,
      ),
    );
    result.fold(
      (failure) => emit(
        ProjectError(
          title: 'Error Editing Project',
          message: failure.errorMessage,
        ),
      ),
      (_) => emit(const ProjectUpdated()),
    );
  }

  Future<void> _getProjectByIdHandler(
    $GetProjectById event,
    Emitter<ProjectState> emit,
  ) async {
    final result = await _getProjectById(event.id);
    result.fold(
      (failure) => emit(
        ProjectError(
          title: 'Error Fetching Project',
          message: failure.errorMessage,
        ),
      ),
      (project) => emit(ProjectLoaded(project)),
    );
  }

  Future<void> _getProjectsHandler(
    $GetProjects event,
    Emitter<ProjectState> emit,
  ) async {
    // the usecase `getProjects` returns a stream,
    return emit.forEach(
      _getProjects(event.detailed),
      onData: (data) => data.fold(
        (failure) => ProjectError(
          title: 'Error Fetching Projects',
          message: failure.errorMessage,
        ),
        ProjectsLoaded.new,
      ),
      // I personally don't think this is necessary since the usecase listens
      // to the repo and in the repoImpl we transform the original stream to
      // the stream we are currently dealing with, and in there, we handle the
      // errors and return failure objects, so, I think the onData will cover
      // all the cases, but I might be wrong.
      // If I'm right, then `_getProjectsHandler1` might be the correct way to
      // handle the stream. or just delete the onError totally since it's not
      // required anyway.
      onError: (error, stackTrace) {
        debugPrint('Error Fetching Projects: $error');
        debugPrintStack(stackTrace: stackTrace);
        return const ProjectError(
          title: 'Error Fetching Projects',
          message: 'An error occurred while fetching projects',
        );
      },
    );
  }

// void _getProjectsHandler1($GetProjects event, Emitter<ProjectState> emit) {
//   // the usecase returns a stream, so we need to handle it differently
//   // we will use the `forEach` method of the emitter to listen to the stream
//   // and emit the states
//
//   _getProjects(event.detailed).forEach(
//     (result) => result.fold(
//       (failure) => emit(
//         ProjectError(
//           title: 'Error Fetching Projects',
//           message: failure.errorMessage,
//         ),
//       ),
//       (projects) => emit(ProjectsLoaded(projects)),
//     ),
//   );
// }
}
