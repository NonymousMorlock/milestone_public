import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/core/common/app/milestone/app_state.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/app_page_scaffold.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/outlined_back_button.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/components/add_or_edit_project_bootstrap_error_component.dart';
import 'package:milestone/src/project/presentation/components/project_deletion_pending_component.dart';
import 'package:milestone/src/project/presentation/utils/project_pending_deletion_utils.dart';
import 'package:milestone/src/project/presentation/views/all_projects_view.dart';
import 'package:milestone/src/project/presentation/widgets/add_or_edit_project_form.dart';

class AddOrEditProjectView extends StatefulWidget {
  AddOrEditProjectView({
    required this.isEdit,
    this.projectId,
    this.seedProject,
    super.key,
  }) : assert(
         !isEdit || projectId != null,
         'projectId is required when isEdit is true',
       ),
       assert(
         seedProject == null ||
             projectId == null ||
             seedProject.id == projectId,
         'seedProject.id must match projectId when both are provided',
       );

  final bool isEdit;
  final String? projectId;
  final Project? seedProject;

  static const addPath = '/add';
  static const editPath = '/edit';

  @override
  State<AddOrEditProjectView> createState() => _AddOrEditProjectViewState();
}

class _AddOrEditProjectViewState extends State<AddOrEditProjectView> {
  bool _baselineVerified = false;
  bool _deleteRetryInFlight = false;
  Project? _lastAuthoritativeProject;
  Project? _pendingDeleteProject;
  Project? _pendingDeleteOverride;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<ClientCubit>().getClients());
    if (!widget.isEdit) {
      return;
    }

    if (widget.seedProject != null) {
      context.read<ProjectFormController>().init(
        widget.seedProject!,
        notify: false,
      );
    }
    context.read<ProjectBloc>().add(GetProjectByIdEvent(widget.projectId!));
  }

  void _goToDetails() {
    context.go('${AllProjectsView.path}/${widget.projectId!}');
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isEdit ? 'Edit Project' : 'Add Project';
    var webTitleText = titleText;
    final availableProject =
        widget.seedProject ??
        switch (context.read<ProjectBloc>().state) {
          ProjectLoaded(:final project) => project,
          _ => null,
        };
    if (widget.isEdit && availableProject != null) {
      webTitleText = '$titleText | ${availableProject.projectName}';
    }

    final subtitleText = widget.isEdit
        ? 'Update project structure and context.'
        : 'Capture the work, money, and context for a new project.';

    final seedProject = widget.seedProject;
    final blockingProject = switch (context.watch<ProjectBloc>().state) {
      ProjectLoaded(:final project) when project.isPendingDeletion => project,
      _ => _pendingDeleteOverride ?? _pendingDeleteProject,
    };

    return MultiBlocListener(
      listeners: [
        BlocListener<ClientCubit, ClientState>(
          listener: (_, state) {
            AppState.instance.stopLoading();
            if (state is ClientLoading) {
              AppState.instance.startLoading();
            } else if (state case ClientsLoaded(:final clients)) {
              context.read<ProjectFormController>().setClients(clients);
            } else if (state is ClientError) {
              CoreUtils.showSnackBar(
                logLevel: LogLevel.error,
                message: state.message,
                title: state.title,
              );
            }
          },
        ),
        BlocListener<ProjectBloc, ProjectState>(
          listener: (_, state) {
            AppState.instance.stopLoading();
            if (state is ProjectLoading) {
              AppState.instance.startLoading();
            } else if (state is ProjectAdded) {
              context.go(AppRoutes.initial);
              CoreUtils.showSnackBar(
                logLevel: LogLevel.success,
                title: 'Success',
                message: 'Project added successfully',
              );
            } else if (widget.isEdit && state is ProjectDeleted) {
              setState(() {
                _deleteRetryInFlight = false;
                _pendingDeleteProject = null;
                _pendingDeleteOverride = null;
              });
              context.go(AllProjectsView.path);
              CoreUtils.showSnackBar(
                logLevel: LogLevel.success,
                title: 'Success',
                message: 'Project deleted successfully',
              );
            } else if (widget.isEdit && state is ProjectLoaded) {
              final project = state.project;
              if (project.isPendingDeletion) {
                setState(() {
                  _baselineVerified = false;
                  _deleteRetryInFlight = false;
                  _lastAuthoritativeProject = project;
                  _pendingDeleteProject = project;
                  _pendingDeleteOverride = project;
                });
                return;
              }

              context.read<ProjectFormController>().init(project);
              setState(() {
                _baselineVerified = true;
                _deleteRetryInFlight = false;
                _lastAuthoritativeProject = project;
                _pendingDeleteProject = null;
                _pendingDeleteOverride = null;
              });
            } else if (state is ProjectUpdated) {
              _goToDetails();
              CoreUtils.showSnackBar(
                logLevel: LogLevel.success,
                title: 'Success',
                message: 'Project updated successfully',
              );
            } else if (state case ProjectError(
              :final title,
              :final message,
              :final statusCode,
            )) {
              if (widget.isEdit && statusCode == 'PROJECT_NOT_FOUND') {
                setState(() {
                  _baselineVerified = false;
                  _deleteRetryInFlight = false;
                  _pendingDeleteProject = null;
                  _pendingDeleteOverride = null;
                });
                context.go(AllProjectsView.path);
                CoreUtils.showSnackBar(
                  title: 'Project unavailable',
                  message: 'This project was already deleted.',
                );
                return;
              }

              if (widget.isEdit && statusCode == 'project-delete-pending') {
                setState(() {
                  _baselineVerified = false;
                  _deleteRetryInFlight = false;
                  final baseline = _lastAuthoritativeProject ?? seedProject;
                  if (baseline != null) {
                    _pendingDeleteOverride = markProjectAsPendingDeletion(
                      baseline,
                    );
                  }
                });
                CoreUtils.showSnackBar(
                  logLevel: LogLevel.error,
                  message: message,
                  title: title,
                );
                context.read<ProjectBloc>().add(
                  GetProjectByIdEvent(widget.projectId!),
                );
                return;
              }

              if (widget.isEdit &&
                  ((_pendingDeleteProject?.isPendingDeletion ?? false) ||
                      (_pendingDeleteOverride?.isPendingDeletion ?? false))) {
                setState(() {
                  _deleteRetryInFlight = false;
                });
              }

              CoreUtils.showSnackBar(
                logLevel: LogLevel.error,
                message: message,
                title: title,
              );
            }
          },
        ),
      ],
      child: AdaptiveBase(
        title: webTitleText,
        child: BlocBuilder<ProjectBloc, ProjectState>(
          builder: (_, projectState) {
            final bootstrapChild = projectState is ProjectError
                ? AddOrEditProjectBootstrapErrorComponent(
                    error: projectState,
                    onRetry: () {
                      context.read<ProjectBloc>().add(
                        GetProjectByIdEvent(widget.projectId!),
                      );
                    },
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                        return;
                      }
                      context.go(AppRoutes.initial);
                    },
                  )
                : const SizedBox.shrink();

            return Scaffold(
              appBar: kIsWeb
                  ? null
                  : AppBar(
                      automaticallyImplyLeading: false,
                      leading: const OutlinedBackButton(),
                      title: !kIsWeb ? Text(titleText) : null,
                    ),
              body: SafeArea(
                child: AppPageScaffold(
                  subtitle: subtitleText,
                  widthPolicy: AppPageWidthPolicy.form,
                  child: widget.isEdit && blockingProject != null
                      ? ProjectDeletionPendingComponent(
                          projectName: blockingProject.projectName,
                          isBusy: _deleteRetryInFlight,
                          onRetryDelete: () {
                            setState(() {
                              _deleteRetryInFlight = true;
                            });
                            context.read<ProjectBloc>().add(
                              DeleteProjectEvent(blockingProject.id),
                            );
                          },
                          onBackToProjects: _goToDetails,
                        )
                      : widget.isEdit && !_baselineVerified
                      ? bootstrapChild
                      : AddOrEditProjectForm(isEdit: widget.isEdit),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
