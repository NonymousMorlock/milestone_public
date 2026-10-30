import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

abstract interface class ProjectRepo {
  const ProjectRepo();

  ResultFuture<void> addProject(Project project);

  ResultFuture<void> deleteProject(String projectId);

  ResultFuture<void> editProjectDetails({
    required String projectId,
    required DataMap updateData,
  });

  ResultFuture<Project> getProjectById(String projectId);

  ResultStream<List<Project>> getProjects({
    required bool detailed,
    required int? limit,
    bool excludePendingDeletion = false,
  });

  ResultFuture<List<String>> getUserTools();

  ResultFuture<void> removeUserTool(String toolName);
}
