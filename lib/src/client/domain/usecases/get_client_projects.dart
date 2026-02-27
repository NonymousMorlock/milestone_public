import 'package:equatable/equatable.dart';
import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/domain/repos/client_repo.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class GetClientProjects
    extends UsecaseWithParams<List<Project>, GetClientProjectsParams> {
  const GetClientProjects(this._repo);

  final ClientRepo _repo;

  @override
  ResultFuture<List<Project>> call(GetClientProjectsParams params) =>
      _repo.getClientProjects(
        clientId: params.clientId,
        detailed: params.detailed,
      );
}

class GetClientProjectsParams extends Equatable {
  const GetClientProjectsParams({
    required this.clientId,
    required this.detailed,
  });

  const GetClientProjectsParams.empty()
      : this(clientId: 'Test String', detailed: false);

  final String clientId;
  final bool detailed;

  @override
  List<dynamic> get props => [
        clientId,
        detailed,
      ];
}
