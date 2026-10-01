import 'package:equatable/equatable.dart';
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/repos/project_repo.dart';

class GetProjects
    implements StreamUsecaseWithParams<List<Project>, GetProjectsParams> {
  const GetProjects(this._repo);

  final ProjectRepo _repo;

  @override
  ResultStream<List<Project>> call(GetProjectsParams params) =>
      _repo.getProjects(
        detailed: params.detailed,
        limit: params.limit,
        excludePendingDeletion: params.excludePendingDeletion,
      );
}

class GetProjectsParams extends Equatable {
  const GetProjectsParams({
    required this.detailed,
    required this.limit,
    required this.excludePendingDeletion,
  });

  const GetProjectsParams.empty()
    : this(detailed: false, limit: null, excludePendingDeletion: false);

  final bool detailed;
  final int? limit;
  final bool excludePendingDeletion;

  @override
  List<Object?> get props => [detailed, limit, excludePendingDeletion];
}
