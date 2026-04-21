import 'package:milestone/core/extensions/string_extensions.dart';
import 'package:milestone/src/project/features/milestone/presentation/views/add_or_edit_milestone_view.dart';
import 'package:milestone/src/project/presentation/views/add_or_edit_project_view.dart';
import 'package:milestone/src/project/presentation/views/all_projects_view.dart';

sealed class AppRoutes {
  const AppRoutes();

  static const String initial = '/';

  /// /projects/add
  static String get addProject {
    final path = AddOrEditProjectView.addPath.normalisedNestedPath;
    return '${AllProjectsView.path}/$path';
  }

  static String editProject(String projectId) {
    final editPath = AddOrEditProjectView.editPath.normalisedNestedPath;
    return '${AllProjectsView.path}/$projectId/$editPath';
  }

  static String addProjectMilestone({required String projectId}) {
    final addPath = AddOrEditMilestoneView.addPath.normalisedNestedPath;
    return '${AllProjectsView.path}/$projectId/milestones/$addPath';
  }

  static String editProjectMilestone({
    required String projectId,
    required String milestoneId,
  }) {
    final editPath = AddOrEditMilestoneView.editPath.normalisedNestedPath;
    return '${AllProjectsView.path}/$projectId/milestones/$milestoneId/$editPath';
  }

  static String addClient = '/clients/add';
}
