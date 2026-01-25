import 'package:equatable/equatable.dart';
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/repos/project_repo.dart';

class EditProjectDetails
    extends UsecaseWithParams<void, EditProjectDetailsParams> {
  const EditProjectDetails(this._repo);

  final ProjectRepo _repo;

  @override
  ResultFuture<void> call(EditProjectDetailsParams params) =>
      _repo.editProjectDetails(
        projectId: params.projectId,
        updatedProject: params.updatedProject,
      );
}

class EditProjectDetailsParams extends Equatable {
  const EditProjectDetailsParams({
    required this.projectId,
    required this.updatedProject,
  });

  const EditProjectDetailsParams.empty()
      : this(
          projectId: 'Test String',
          updatedProject: const {},
        );

  final String projectId;
  final Map<String, dynamic> updatedProject;

  @override
  List<dynamic> get props => [
        projectId,
        updatedProject,
      ];
}
