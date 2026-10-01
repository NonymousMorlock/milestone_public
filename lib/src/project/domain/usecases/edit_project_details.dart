import 'package:equatable/equatable.dart';
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/repos/project_repo.dart';

class EditProjectDetails
    implements UsecaseWithParams<void, EditProjectDetailsParams> {
  const EditProjectDetails(this._repo);

  final ProjectRepo _repo;

  @override
  ResultFuture<void> call(EditProjectDetailsParams params) =>
      _repo.editProjectDetails(
        projectId: params.projectId,
        updateData: params.updateData,
      );
}

class EditProjectDetailsParams extends Equatable {
  const EditProjectDetailsParams({
    required this.projectId,
    required this.updateData,
  });

  const EditProjectDetailsParams.empty()
    : this(projectId: 'Test String', updateData: const {});

  final String projectId;
  final Map<String, dynamic> updateData;

  @override
  List<dynamic> get props => [projectId, updateData];
}
