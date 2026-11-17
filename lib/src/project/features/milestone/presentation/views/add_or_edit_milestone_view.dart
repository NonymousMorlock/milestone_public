import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/core/common/app/milestone/app_state.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/app_page_scaffold.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/outlined_back_button.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:milestone/src/project/features/milestone/presentation/components/add_or_edit_milestone_bootstrap_error_component.dart';
import 'package:milestone/src/project/features/milestone/presentation/providers/milestone_form_controller.dart';
import 'package:milestone/src/project/features/milestone/presentation/widgets/add_or_edit_milestone_form.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/components/project_deletion_pending_component.dart';
import 'package:milestone/src/project/presentation/utils/project_pending_deletion_utils.dart';

enum MilestoneRouteResult { added, updated }

class AddOrEditMilestoneView extends StatefulWidget {
  const AddOrEditMilestoneView.add({
    required this.projectId,
    super.key,
  }) : isEdit = false,
       milestoneId = null,
       seedMilestone = null;

  const AddOrEditMilestoneView.edit({
    required this.projectId,
    required this.milestoneId,
    this.seedMilestone,
    super.key,
  }) : isEdit = true;

  static const addPath = '/add';
  static const editPath = '/edit';

  final String projectId;
  final bool isEdit;
  final String? milestoneId;
  final Milestone? seedMilestone;

  @override
  State<AddOrEditMilestoneView> createState() => _AddOrEditMilestoneViewState();
}

class _AddOrEditMilestoneViewState extends State<AddOrEditMilestoneView> {
  bool _milestoneBaselineVerified = false;
  bool _parentProjectReady = false;
  bool _deleteRetryInFlight = false;
  Project? _lastAuthoritativeProject;
  Project? _pendingDeleteProject;
  Project? _pendingDeleteOverride;

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(GetProjectByIdEvent(widget.projectId));
    if (!widget.isEdit) {
      return;
    }

    if (widget.seedMilestone != null) {
      context.read<MilestoneFormController>().init(
        widget.seedMilestone!,
        notify: false,
      );
      _milestoneBaselineVerified = true;
      return;
    }

    unawaited(_loadMilestone());
  }

  Future<void> _loadMilestone() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppState.instance.startLoading();
    });
    return context.read<MilestoneCubit>().getMilestoneById(
      projectId: widget.projectId,
      milestoneId: widget.milestoneId!,
    );
  }

  void _requestCloseToProject({MilestoneRouteResult? result}) {
    if (context.canPop()) {
      if (result != null) {
        context.pop(result);
      } else {
        context.pop();
      }
      return;
    }

    context.go('/projects/${widget.projectId}');
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isEdit ? 'Edit Milestone' : 'Add Milestone';
    var webTitleText = titleText;
    final availableMilestone =
        widget.seedMilestone ??
        switch (context.read<MilestoneCubit>().state.detail) {
          MilestoneDetailSuccess(:final milestone) => milestone,
          _ => null,
        };
    if (widget.isEdit && availableMilestone != null) {
      webTitleText = '$titleText | ${availableMilestone.title}';
    }

    final subtitleText = widget.isEdit
        ? 'Update delivery and payment details for this project milestone.'
        : 'Capture a new delivery checkpoint for this project.';

    final projectState = context.watch<ProjectBloc>().state;

    final blockingProject = switch (projectState) {
      ProjectLoaded(:final project) when project.isPendingDeletion => project,
      _ => _pendingDeleteOverride ?? _pendingDeleteProject,
    };

    return AdaptiveBase(
      title: webTitleText,
      child: MultiBlocListener(
        listeners: [
          BlocListener<ProjectBloc, ProjectState>(
            listener: (context, state) {
              if (state is ProjectLoading) {
                AppState.instance.startLoading();
                return;
              }

              if (state case ProjectDeleted()) {
                setState(() {
                  _deleteRetryInFlight = false;
                  _pendingDeleteProject = null;
                  _pendingDeleteOverride = null;
                });
                _requestCloseToProject();
                CoreUtils.showSnackBar(
                  message: 'Project deleted successfully.',
                  title: 'Success',
                  logLevel: LogLevel.success,
                );
                return;
              }

              if (state case ProjectLoaded(:final project)) {
                setState(() {
                  _deleteRetryInFlight = false;
                  _lastAuthoritativeProject = project;
                  if (project.isPendingDeletion) {
                    _parentProjectReady = false;
                    _pendingDeleteProject = project;
                    _pendingDeleteOverride = project;
                  } else {
                    _parentProjectReady = true;
                    _pendingDeleteProject = null;
                    _pendingDeleteOverride = null;
                  }
                });
                return;
              }

              if (state case ProjectError(
                :final title,
                :final message,
                :final statusCode,
              )) {
                if (statusCode == 'PROJECT_NOT_FOUND') {
                  setState(() {
                    _deleteRetryInFlight = false;
                    _parentProjectReady = false;
                    _pendingDeleteProject = null;
                    _pendingDeleteOverride = null;
                  });
                  _requestCloseToProject();
                  CoreUtils.showSnackBar(
                    message: 'This project was already deleted.',
                    title: 'Project unavailable',
                  );
                  return;
                }

                if (statusCode == 'project-delete-pending') {
                  setState(() {
                    _deleteRetryInFlight = false;
                    _parentProjectReady = false;
                    if (_lastAuthoritativeProject != null) {
                      _pendingDeleteOverride = markProjectAsPendingDeletion(
                        _lastAuthoritativeProject!,
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

                if ((_pendingDeleteProject?.isPendingDeletion ?? false) ||
                    (_pendingDeleteOverride?.isPendingDeletion ?? false)) {
                  setState(() {
                    _deleteRetryInFlight = false;
                  });
                }

                CoreUtils.showSnackBar(
                  message: message,
                  title: title,
                  logLevel: LogLevel.error,
                );
              }
            },
          ),
          BlocListener<MilestoneCubit, MilestoneState>(
            listenWhen: (previous, current) {
              return previous.detail != current.detail ||
                  previous.mutation != current.mutation;
            },
            listener: (context, state) {
              if (state.isMutating || state.detail is MilestoneDetailLoading) {
                AppState.instance.startLoading();
              } else {
                AppState.instance.stopLoading();
              }

              if (state.detail case MilestoneDetailSuccess(:final milestone)) {
                context.read<MilestoneFormController>().init(milestone);
                if (!_milestoneBaselineVerified) {
                  setState(() {
                    _milestoneBaselineVerified = true;
                  });
                }
              }

              if (state.mutation is MilestoneMutationSuccess) {
                final mutation = state.mutation as MilestoneMutationSuccess;
                if (mutation.type == MilestoneMutationType.add ||
                    mutation.type == MilestoneMutationType.edit) {
                  _requestCloseToProject(
                    result: widget.isEdit
                        ? MilestoneRouteResult.updated
                        : MilestoneRouteResult.added,
                  );
                }
              }

              if (state.mutation case MilestoneMutationFailure(
                :final title,
                :final message,
                :final statusCode,
              )) {
                if (statusCode == 'project-pending-delete' &&
                    _lastAuthoritativeProject != null) {
                  setState(() {
                    _parentProjectReady = false;
                    _pendingDeleteOverride = markProjectAsPendingDeletion(
                      _lastAuthoritativeProject!,
                    );
                  });
                  context.read<ProjectBloc>().add(
                    GetProjectByIdEvent(widget.projectId),
                  );
                }
                CoreUtils.showSnackBar(
                  message: message,
                  title: title,
                  logLevel: .error,
                );
              }
            },
          ),
        ],
        child: Scaffold(
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
              child: blockingProject != null
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
                      onBackToProjects: _requestCloseToProject,
                    )
                  : !_parentProjectReady ||
                        (widget.isEdit && !_milestoneBaselineVerified)
                  ? BlocBuilder<MilestoneCubit, MilestoneState>(
                      builder: (context, milestoneState) {
                        if (projectState case ProjectError(
                          :final title,
                          :final message,
                        )) {
                          return AddOrEditMilestoneBootstrapErrorComponent(
                            title: title,
                            message: message,
                            onRetry: () {
                              context.read<ProjectBloc>().add(
                                GetProjectByIdEvent(widget.projectId),
                              );
                              if (widget.isEdit &&
                                  widget.seedMilestone == null) {
                                unawaited(_loadMilestone());
                              }
                            },
                            onBack: _requestCloseToProject,
                          );
                        }

                        if (milestoneState.detail case MilestoneDetailFailure(
                          :final title,
                          :final message,
                        )) {
                          return AddOrEditMilestoneBootstrapErrorComponent(
                            title: title,
                            message: message,
                            onRetry: _loadMilestone,
                            onBack: _requestCloseToProject,
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    )
                  : AddOrEditMilestoneForm(
                      projectId: widget.projectId,
                      milestoneId: widget.milestoneId,
                      isEdit: widget.isEdit,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
