import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/app_page_scaffold.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/double_extensions.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/components/project_deletion_pending_component.dart';
import 'package:milestone/src/project/presentation/components/project_details_message_state_component.dart';
import 'package:milestone/src/project/presentation/sections/project_details_descriptions_section.dart';
import 'package:milestone/src/project/presentation/sections/project_details_finance_section.dart';
import 'package:milestone/src/project/presentation/sections/project_details_gallery_section.dart';
import 'package:milestone/src/project/presentation/sections/project_details_links_section.dart';
import 'package:milestone/src/project/presentation/sections/project_details_milestones_section.dart';
import 'package:milestone/src/project/presentation/sections/project_details_notes_section.dart';
import 'package:milestone/src/project/presentation/sections/project_details_schedule_section.dart';
import 'package:milestone/src/project/presentation/sections/project_details_tools_section.dart';
import 'package:milestone/src/project/presentation/sections/project_details_workspace_header_section.dart';
import 'package:milestone/src/project/presentation/utils/project_pending_deletion_utils.dart';
import 'package:milestone/src/project/presentation/views/all_projects_view.dart';

class ProjectDetailsView extends StatefulWidget {
  const ProjectDetailsView({required this.projectId, super.key});

  final String projectId;

  @override
  State<ProjectDetailsView> createState() => _ProjectDetailsViewState();
}

class _ProjectDetailsViewState extends State<ProjectDetailsView> {
  Project? _lastLoadedProject;
  Project? _pendingDeleteOverride;
  String? _projectName;
  bool _projectRefreshFailed = false;
  bool _deleteInFlight = false;

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(GetProjectByIdEvent(widget.projectId));
  }

  Future<void> _confirmDelete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: const Text('Delete project?'),
          content: Text(
            'Delete ${project.projectName}?\n\n'
            '${project.numberOfMilestonesSoFar} milestone records will be'
            ' removed.\n'
            '${project.totalPaid.currency} will be removed from client and'
            ' earned totals.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: context.colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _deleteInFlight = true;
    });
    context.read<ProjectBloc>().add(DeleteProjectEvent(project.id));
  }

  void _goToProjects() {
    context.go(AllProjectsView.path);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: _projectName == null
          ? 'Project Details'
          : 'Projects | $_projectName',
      child: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state case ProjectLoaded(:final project)) {
            context.read<ProjectFormController>().init(project);
            if (_lastLoadedProject != project ||
                _pendingDeleteOverride != project ||
                _projectName != project.projectName ||
                _projectRefreshFailed ||
                _deleteInFlight) {
              setState(() {
                _lastLoadedProject = project;
                _pendingDeleteOverride = project.isPendingDeletion
                    ? project
                    : null;
                _projectName = project.projectName;
                _projectRefreshFailed = false;
                _deleteInFlight = false;
              });
            }
            return;
          }

          if (state case ProjectDeleted()) {
            setState(() {
              _deleteInFlight = false;
              _pendingDeleteOverride = null;
              _lastLoadedProject = null;
              _projectRefreshFailed = false;
            });
            _goToProjects();
            CoreUtils.showSnackBar(
              message: 'Project deleted successfully',
              title: 'Success',
              logLevel: LogLevel.success,
            );
            return;
          }

          if (state case ProjectError(
            :final title,
            :final message,
            :final statusCode,
          )) {
            if (statusCode == 'PROJECT_NOT_FOUND') {
              setState(() {
                _deleteInFlight = false;
                _pendingDeleteOverride = null;
                _lastLoadedProject = null;
                _projectRefreshFailed = false;
              });
              _goToProjects();
              CoreUtils.showSnackBar(
                message: 'This project was already deleted.',
                title: 'Project unavailable',
              );
              return;
            }

            if (statusCode == 'project-delete-pending') {
              final baseline = _lastLoadedProject;
              setState(() {
                _deleteInFlight = false;
                if (baseline != null) {
                  _pendingDeleteOverride = markProjectAsPendingDeletion(
                    baseline,
                  );
                }
              });
              CoreUtils.showSnackBar(
                message: message,
                title: title,
                logLevel: LogLevel.error,
              );
              context.read<ProjectBloc>().add(
                GetProjectByIdEvent(widget.projectId),
              );
              return;
            }

            if (_lastLoadedProject != null) {
              setState(() {
                _deleteInFlight = false;
                _projectRefreshFailed = true;
              });
            } else if (_deleteInFlight) {
              setState(() {
                _deleteInFlight = false;
              });
            }

            CoreUtils.showSnackBar(
              message: message,
              title: title,
              logLevel: LogLevel.error,
            );
          }
        },
        builder: (context, state) {
          final loadedProject = switch (state) {
            ProjectLoaded(:final project) => project,
            _ => null,
          };
          final visibleProject =
              loadedProject ?? _pendingDeleteOverride ?? _lastLoadedProject;

          return SafeArea(
            child: AppPageScaffold(
              title: _projectName ?? 'Project details',
              subtitle:
                  visibleProject?.clientName ??
                  'Project context and commercial status.',
              widthPolicy: AppPageWidthPolicy.details,
              actions: [
                FilledButton.icon(
                  onPressed:
                      visibleProject == null ||
                          visibleProject.isPendingDeletion ||
                          _deleteInFlight
                      ? null
                      : () => context.go(
                          AppRoutes.editProject(visibleProject.id),
                          extra: visibleProject,
                        ),
                  icon: const Icon(Icons.drive_file_rename_outline),
                  label: const Text('Edit Project'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      visibleProject == null ||
                          visibleProject.isPendingDeletion ||
                          _deleteInFlight
                      ? null
                      : () => _confirmDelete(visibleProject),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Project'),
                ),
              ],
              child: visibleProject == null
                  ? switch (state) {
                      ProjectError(:final message) =>
                        ProjectDetailsMessageStateComponent(
                          title: 'Unable to load project',
                          message: message,
                        ),
                      _ => const StateRenderer(
                        loading: true,
                        child: SizedBox.shrink(),
                      ),
                    }
                  : visibleProject.isPendingDeletion
                  ? ProjectDeletionPendingComponent(
                      projectName: visibleProject.projectName,
                      isBusy: _deleteInFlight,
                      onRetryDelete: () {
                        setState(() {
                          _deleteInFlight = true;
                        });
                        context.read<ProjectBloc>().add(
                          DeleteProjectEvent(visibleProject.id),
                        );
                      },
                      onBackToProjects: _goToProjects,
                    )
                  : Column(
                      crossAxisAlignment: .stretch,
                      spacing: 16,
                      children: [
                        if (_deleteInFlight) ...[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Deleting project. Milestones, rollups, and'
                                ' owned media are being finalized.',
                              ),
                            ),
                          ),
                        ] else if (state is ProjectLoading &&
                            _lastLoadedProject != null) ...[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        context.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Refreshing project totals'
                                      ' and milestone rollups.',
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: context
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_projectRefreshFailed) ...[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: .start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color:
                                        context.colorScheme.onTertiaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Showing last confirmed project data'
                                      ' while the latest refresh is retried.',
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: context
                                                .colorScheme
                                                .onTertiaryContainer,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton(
                                    onPressed: () {
                                      context.read<ProjectBloc>().add(
                                        GetProjectByIdEvent(widget.projectId),
                                      );
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        ProjectDetailsWorkspaceHeaderSection(
                          project: visibleProject,
                        ),
                        ProjectDetailsFinanceSection(project: visibleProject),
                        AppSectionCard(
                          title: 'Schedule and status',
                          child: ProjectDetailsScheduleSection(
                            project: visibleProject,
                          ),
                        ),
                        AppSectionCard(
                          title: 'Descriptions',
                          child: ProjectDetailsDescriptionsSection(
                            project: visibleProject,
                          ),
                        ),
                        AppSectionCard(
                          title: 'Notes',
                          child: ProjectDetailsNotesSection(
                            project: visibleProject,
                          ),
                        ),
                        AppSectionCard(
                          title: 'Links',
                          child: ProjectDetailsLinksSection(
                            project: visibleProject,
                          ),
                        ),
                        AppSectionCard(
                          title: 'Tools',
                          child: ProjectDetailsToolsSection(
                            project: visibleProject,
                          ),
                        ),
                        AppSectionCard(
                          title: 'Gallery',
                          child: ProjectDetailsGallerySection(
                            project: visibleProject,
                          ),
                        ),
                        AppSectionCard(
                          title: 'Milestones',
                          subtitle:
                              'Delivery checkpoints and payment history'
                              ' for this project.',
                          child: ProjectDetailsMilestonesSection(
                            projectId: visibleProject.id,
                            projectName: visibleProject.projectName,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
