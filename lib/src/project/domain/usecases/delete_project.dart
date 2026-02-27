import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/repos/project_repo.dart';

class DeleteProject extends UsecaseWithParams<void, String> {
  const DeleteProject(this._repo);

  final ProjectRepo _repo;

  @override
  ResultFuture<void> call(String params) => _repo.deleteProject(params);
}
