import 'package:equatable/equatable.dart';
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/repos/project_repo.dart';

class GetProjects extends StreamUsecaseWithParams<List<Project>, bool> {
  const GetProjects(this._repo);

  final ProjectRepo _repo;

  @override
  ResultStream<List<Project>> call(bool params) =>
      _repo.getProjects(detailed: params);
}

class GetProjectsParams extends Equatable {
  const GetProjectsParams({required this.detailed, this.limit});

  const GetProjectsParams.empty() : this(detailed: false);

  final bool detailed;
  final int? limit;

  @override
  List<Object?> get props => [detailed, limit];
}
