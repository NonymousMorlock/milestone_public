import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/core/common/layout/app_page_scaffold.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/components/all_projects_empty_state_component.dart';
import 'package:milestone/src/project/presentation/components/all_projects_message_state_component.dart';
import 'package:milestone/src/project/presentation/widgets/boxy/project_tile_style.dart';
import 'package:milestone/src/project/presentation/widgets/client_widget.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile_bottom_half.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile_top_half.dart';

class AllProjectsView extends StatefulWidget {
  const AllProjectsView({super.key});

  static const path = '/projects';

  @override
  State<AllProjectsView> createState() => _AllProjectsViewState();
}

class _AllProjectsViewState extends State<AllProjectsView> {
  final style = const ProjectTileStyle();

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(const GetProjectsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Projects',
      child: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (_, state) {
          if (state case ProjectError(
            :final String title,
            :final String message,
          )) {
            CoreUtils.showSnackBar(
              message: message,
              title: title,
              logLevel: .error,
            );
          }
        },
        builder: (_, state) {
          return AppPageScaffold(
            title: 'Projects',
            subtitle: 'Track current work, budgets, and deadlines.',
            child: AppSectionCard(
              title: 'Project library',
              subtitle:
                  'Space reserved for filters and sorting in later phases.',
              child: StateRenderer(
                loading: state is ProjectLoading,
                builder: (context) {
                  if (state case ProjectError(:final message)) {
                    return AllProjectsMessageStateComponent(
                      title: 'Unable to load projects',
                      message: message,
                    );
                  }
                  if (state case ProjectsLoaded(:final projects)) {
                    if (projects.isEmpty) {
                      return AllProjectsEmptyStateComponent(
                        onAddProject: () => context.go(AppRoutes.addProject),
                      );
                    }

                    final activeProjects = projects
                        .where((project) => !project.isPendingDeletion)
                        .toList();
                    final pendingDeletionProjects = projects
                        .where((project) => project.isPendingDeletion)
                        .toList();

                    return Column(
                      crossAxisAlignment: .stretch,
                      spacing: 24,
                      children: [
                        if (activeProjects.isNotEmpty)
                          Wrap(
                            spacing: 16,
                            runSpacing: 24,
                            children: activeProjects.map((project) {
                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
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
                            }).toList(),
                          ),
                        if (pendingDeletionProjects.isNotEmpty)
                          AppSectionCard(
                            title: 'Pending deletion',
                            subtitle:
                                'These projects stay visible while cleanup'
                                ' finishes, but they are no longer '
                                'active work.',
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 24,
                              children: pendingDeletionProjects.map((project) {
                                return ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 320,
                                  ),
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
                              }).toList(),
                            ),
                          ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
