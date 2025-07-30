import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

abstract class ProjectRepo {
  const ProjectRepo();

  ResultFuture<void> addProject(Project project);

  ResultFuture<void> editProjectDetails({
    required String projectId,
    required DataMap updatedProject,
  });

  ResultFuture<void> deleteProject(String projectId);

  ResultStream<List<Project>> getProjects({required bool detailed, int? limit});

  ResultFuture<Project> getProjectById(String projectId);
}
