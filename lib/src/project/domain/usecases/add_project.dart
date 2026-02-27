import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/repos/project_repo.dart';

class AddProject extends UsecaseWithParams<void, Project> {
  const AddProject(this._repo);

  final ProjectRepo _repo;

  @override
  ResultFuture<void> call(Project params) => _repo.addProject(params);
}
