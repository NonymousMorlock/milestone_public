import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/src/home/presentation/components/home_empty_projects_state_component.dart';
import 'package:milestone/src/home/presentation/sections/home_total_earned_section.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/views/all_projects_view.dart';
import 'package:milestone/src/project/presentation/widgets/boxy/project_tile_style.dart';
import 'package:milestone/src/project/presentation/widgets/client_widget.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile_bottom_half.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile_top_half.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({
    required this.projects,
    required this.style,
    super.key,
    this.errorMessage,
  });

  final List<Project> projects;
  final ProjectTileStyle style;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final activeProjects = projects
        .where((project) => !project.isPendingDeletion)
        .take(5)
        .toList();
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 24,
      children: [
        HomeTotalEarnedSection(
          onOpenProjects: () => context.go(AllProjectsView.path),
        ),
        if (errorMessage case final value?)
          AppSectionCard(
            title: 'Recent projects unavailable',
            subtitle:
                'The dashboard is still available, '
                'but project data failed to load.',
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        AppSectionCard(
          title: 'Recent projects',
          subtitle: activeProjects.isEmpty
              ? projects.isEmpty
                    ? 'Create your first project to start tracking '
                          'work and money.'
                    : 'Pending-delete cleanup is still in progress. Recent'
                          ' active work will appear when an active project'
                          ' exists.'
              : 'Your latest active work surfaces.',
          action: activeProjects.isEmpty
              ? null
              : TextButton(
                  onPressed: () => context.go(AllProjectsView.path),
                  child: const Text('View all'),
                ),
          child: activeProjects.isEmpty
              ? projects.isEmpty
                    ? HomeEmptyProjectsStateComponent(
                        onAddProject: () {
                          context.go(AppRoutes.addProject);
                        },
                      )
                    : Text(
                        'Pending-delete projects are hidden from recent'
                        ' active work.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
              : Wrap(
                  spacing: 16,
                  runSpacing: 24,
                  children: activeProjects.map(
                    (project) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: ProjectTile(
                          topHalf: ProjectTileTopHalf(project),
                          bottomHalf: ProjectTileBottomHalf(project),
                          clientAvatar: ClientWidget(
                            clientId: project.clientId,
                            clientName: project.clientName,
                          ),
                          style: style,
                        ),
                      );
                    },
                  ).toList(),
                ),
        ),
      ],
    );
  }
}
