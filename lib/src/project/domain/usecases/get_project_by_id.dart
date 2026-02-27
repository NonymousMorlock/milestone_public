import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/repos/project_repo.dart';

class GetProjectById extends UsecaseWithParams<Project, String> {
  const GetProjectById(this._repo);

  final ProjectRepo _repo;

  @override
  ResultFuture<Project> call(String params) => _repo.getProjectById(params);
}
