import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/core/common/app/milestone/app_state.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:milestone/src/project/features/milestone/presentation/views/add_or_edit_milestone_view.dart';
import 'package:milestone/src/project/features/milestone/presentation/widgets/milestone_drag_proxy.dart';
import 'package:milestone/src/project/features/milestone/presentation/widgets/milestone_entry.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';

class ProjectDetailsMilestonesSection extends StatefulWidget {
  const ProjectDetailsMilestonesSection({
    required this.projectId,
    required this.projectName,
    super.key,
  });

  final String projectId;
  final String projectName;

  @override
  State<ProjectDetailsMilestonesSection> createState() =>
      _ProjectDetailsMilestonesSectionState();
}

class _ProjectDetailsMilestonesSectionState
    extends State<ProjectDetailsMilestonesSection> {
  List<Milestone> _visibleMilestones = const [];
  int _visibleOrderVersion = 0;
  bool _hasVisibleProjection = false;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<MilestoneCubit>().state;
    if (currentState.collection case MilestoneCollectionSuccess(
      :final snapshot,
    )) {
      _visibleMilestones = List<Milestone>.of(snapshot.milestones);
      _visibleOrderVersion = snapshot.orderVersion;
      _hasVisibleProjection = true;
    }
    unawaited(_refreshMilestones());
  }

  @override
  void didUpdateWidget(covariant ProjectDetailsMilestonesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      setState(() {
        _visibleMilestones = const [];
        _visibleOrderVersion = 0;
        _hasVisibleProjection = false;
      });
      unawaited(_refreshMilestones());
    }
  }

  Future<void> _refreshMilestones() {
    return context.read<MilestoneCubit>().getMilestones(widget.projectId);
  }

  void _refreshProject() {
    context.read<ProjectBloc>().add(GetProjectByIdEvent(widget.projectId));
  }

  void _syncVisibleOrderFromState(MilestoneState state) {
    if (state.collection case MilestoneCollectionSuccess(:final snapshot)) {
      setState(() {
        _visibleMilestones = List<Milestone>.of(snapshot.milestones);
        _visibleOrderVersion = snapshot.orderVersion;
        _hasVisibleProjection = true;
      });
    }
  }

  List<Milestone> _reorderListLocally(
    List<Milestone> milestones,
    int oldIndex,
    int newIndex, {
    bool normalizeReorderableIndex = false,
  }) {
    var normalizedNewIndex = newIndex;
    if (normalizeReorderableIndex && oldIndex < newIndex) {
      normalizedNewIndex -= 1;
    }

    if (oldIndex == normalizedNewIndex ||
        oldIndex < 0 ||
        oldIndex >= milestones.length ||
        normalizedNewIndex < 0 ||
        normalizedNewIndex >= milestones.length) {
      return milestones;
    }

    final reordered = List<Milestone>.of(milestones);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(normalizedNewIndex, moved);
    return reordered;
  }

  void _dispatchReorderFromVisibleList({
    required List<Milestone> reordered,
    required String movedMilestoneId,
  }) {
    final movedIndex = reordered.indexWhere(
      (milestone) => milestone.id == movedMilestoneId,
    );
    final previousMilestoneId = movedIndex > 0
        ? reordered[movedIndex - 1].id
        : null;
    final nextMilestoneId = movedIndex < reordered.length - 1
        ? reordered[movedIndex + 1].id
        : null;

    unawaited(
      context.read<MilestoneCubit>().reorderMilestone(
        projectId: widget.projectId,
        milestoneId: movedMilestoneId,
        previousMilestoneId: previousMilestoneId,
        nextMilestoneId: nextMilestoneId,
        expectedOrderVersion: _visibleOrderVersion,
      ),
    );
  }

  Future<void> _handleAddPressed() async {
    final result = await context.navigateTo<MilestoneRouteResult>(
      AppRoutes.addProjectMilestone(projectId: widget.projectId),
    );
    if (!mounted) {
      return;
    }

    if (result == MilestoneRouteResult.added ||
        result == MilestoneRouteResult.updated) {
      _refreshProject();
      unawaited(_refreshMilestones());
    }
  }

  Future<void> _handleEditPressed(Milestone milestone) async {
    final result = await context.navigateTo<MilestoneRouteResult>(
      AppRoutes.editProjectMilestone(
        projectId: widget.projectId,
        milestoneId: milestone.id,
      ),
      extra: milestone,
    );
    if (!mounted) {
      return;
    }

    if (result == MilestoneRouteResult.updated) {
      _refreshProject();
      unawaited(_refreshMilestones());
    }
  }

  Future<void> _handleDeletePressed(Milestone milestone) async {
    if (context.read<MilestoneCubit>().state.isMutating) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: const Text('Delete milestone?'),
          content: Text(_deleteImpactCopy(milestone)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    unawaited(
      context.read<MilestoneCubit>().deleteMilestone(
        projectId: widget.projectId,
        milestoneId: milestone.id,
      ),
    );
  }

  void _handleDragReorder(int oldIndex, int newIndex) {
    if (context.read<MilestoneCubit>().state.isMutating) {
      return;
    }

    final sourceMilestones = _visibleMilestones;
    final reordered = _reorderListLocally(
      sourceMilestones,
      oldIndex,
      newIndex,
      normalizeReorderableIndex: true,
    );
    if (identical(reordered, sourceMilestones)) {
      return;
    }

    final movedMilestoneId = sourceMilestones[oldIndex].id;
    setState(() {
      _visibleMilestones = reordered;
      _hasVisibleProjection = true;
    });
    _dispatchReorderFromVisibleList(
      reordered: reordered,
      movedMilestoneId: movedMilestoneId,
    );
  }

  void _handleMoveUp(int index) {
    if (index == 0 || context.read<MilestoneCubit>().state.isMutating) {
      return;
    }

    final sourceMilestones = _visibleMilestones;
    final reordered = _reorderListLocally(
      sourceMilestones,
      index,
      index - 1,
    );
    if (identical(reordered, sourceMilestones)) {
      return;
    }

    final movedMilestoneId = sourceMilestones[index].id;
    setState(() {
      _visibleMilestones = reordered;
      _hasVisibleProjection = true;
    });
    _dispatchReorderFromVisibleList(
      reordered: reordered,
      movedMilestoneId: movedMilestoneId,
    );
  }

  void _handleMoveDown(int index) {
    if (index >= _visibleMilestones.length - 1 ||
        context.read<MilestoneCubit>().state.isMutating) {
      return;
    }

    final sourceMilestones = _visibleMilestones;
    final reordered = _reorderListLocally(
      sourceMilestones,
      index,
      index + 1,
    );
    if (identical(reordered, sourceMilestones)) {
      return;
    }

    final movedMilestoneId = sourceMilestones[index].id;
    setState(() {
      _visibleMilestones = reordered;
      _hasVisibleProjection = true;
    });
    _dispatchReorderFromVisibleList(
      reordered: reordered,
      movedMilestoneId: movedMilestoneId,
    );
  }

  String _deleteImpactCopy(Milestone milestone) {
    if (milestone.amountPaid != null) {
      final amount = NumberFormat.simpleCurrency().format(
        milestone.amountPaid,
      );
      return 'This removes the milestone and subtracts'
          ' $amount from project, client, and earnings rollups.';
    }
    return 'This removes the milestone and decreases'
        ' the milestone count for the project.';
  }

  String _successMessage(MilestoneMutationType mutationType) {
    return switch (mutationType) {
      MilestoneMutationType.add => 'Milestone added successfully.',
      MilestoneMutationType.edit => 'Milestone updated successfully.',
      MilestoneMutationType.delete => 'Milestone deleted successfully.',
      MilestoneMutationType.reorder => 'Milestone order updated.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MilestoneCubit, MilestoneState>(
      listenWhen: (previous, current) {
        final collectionTransitionedToSuccess =
            previous.collection != current.collection &&
                current.collection is MilestoneCollectionSuccess ||
            current.collection is MilestoneCollectionLoading;
        final mutationTransitioned = previous.mutation != current.mutation;
        return collectionTransitionedToSuccess || mutationTransitioned;
      },
      listener: (context, state) {
        AppState.instance.stopLoading();
        if (state.collection is MilestoneCollectionSuccess) {
          _syncVisibleOrderFromState(state);
        }

        if (state.mutation case MilestoneMutationSuccess(:final type)) {
          if (type == MilestoneMutationType.delete) {
            _refreshProject();
            unawaited(_refreshMilestones());
            CoreUtils.showSnackBar(
              logLevel: .success,
              title: 'Success',
              message: _successMessage(type),
            );
            context.read<MilestoneCubit>().clearMutationFeedback();
            return;
          }

          if (type == MilestoneMutationType.reorder) {
            CoreUtils.showSnackBar(
              logLevel: LogLevel.success,
              title: 'Success',
              message: _successMessage(type),
            );
            context.read<MilestoneCubit>().clearMutationFeedback();
            unawaited(_refreshMilestones());
          }
        }

        if (state.mutation is MilestoneMutationInFlight ||
            state.collection is MilestoneCollectionLoading) {
          AppState.instance.startLoading();
        }

        if (state.mutation case MilestoneMutationFailure(
          :final type,
          :final title,
          :final message,
        )) {
          if (type == MilestoneMutationType.reorder) {
            final fallbackSnapshot = state.latestCollectionSnapshot;
            setState(() {
              _visibleMilestones = List<Milestone>.of(
                fallbackSnapshot?.milestones ?? const [],
              );
              _visibleOrderVersion = fallbackSnapshot?.orderVersion ?? 0;
              _hasVisibleProjection = fallbackSnapshot != null;
            });
            CoreUtils.showSnackBar(
              logLevel: LogLevel.error,
              title: title,
              message: message,
            );
            context.read<MilestoneCubit>().clearMutationFeedback();
            if (title == 'Milestone order changed') {
              unawaited(_refreshMilestones());
            }
            return;
          }

          if (type == MilestoneMutationType.delete) {
            CoreUtils.showSnackBar(
              logLevel: LogLevel.error,
              title: title,
              message: message,
            );
            context.read<MilestoneCubit>().clearMutationFeedback();
          }
        }
      },
      builder: (context, state) {
        final visibleMilestones = _hasVisibleProjection
            ? _visibleMilestones
            : state.latestCollectionSnapshot?.milestones ?? const [];
        final hasMilestones = visibleMilestones.isNotEmpty;
        final isMutationLocked = state.isMutating;
        final isInlineRefreshing =
            state.collection is MilestoneCollectionLoading && hasMilestones;
        final collectionFailure = state.collection is MilestoneCollectionFailure
            ? state.collection as MilestoneCollectionFailure
            : null;
        final isInlineFailure = collectionFailure != null && hasMilestones;

        if (state.collection is MilestoneCollectionLoading && !hasMilestones) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        }

        if (collectionFailure != null && !hasMilestones) {
          return Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                collectionFailure.title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: .w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                collectionFailure.message,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: _refreshMilestones,
                    child: const Text('Retry'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _handleAddPressed,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Milestone'),
                  ),
                ],
              ),
            ],
          );
        }

        if (!hasMilestones) {
          return Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                'No milestones yet for ${widget.projectName}.',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: .w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track delivery checkpoints and payment events'
                ' here as the project moves forward.',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _handleAddPressed,
                icon: const Icon(Icons.add),
                label: const Text('Add Milestone'),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: .stretch,
          spacing: 16,
          children: [
            Align(
              alignment: .centerRight,
              child: OutlinedButton.icon(
                onPressed: isMutationLocked ? null : _handleAddPressed,
                icon: const Icon(Icons.add),
                label: const Text('Add Milestone'),
              ),
            ),
            if (isInlineRefreshing) const LinearProgressIndicator(),
            if (isInlineFailure)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colorScheme.errorContainer,
                  borderRadius: .circular(16),
                ),
                child: Padding(
                  padding: const .all(16),
                  child: Row(
                    crossAxisAlignment: .start,
                    spacing: 12,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: context.colorScheme.onErrorContainer,
                      ),
                      Expanded(
                        child: Text(
                          collectionFailure.message,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _refreshMilestones,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560),
              child: ReorderableListView.builder(
                primary: false,
                shrinkWrap: visibleMilestones.length < 5,
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) {
                  if (index < 0 || index >= visibleMilestones.length) {
                    return child;
                  }

                  final milestone = visibleMilestones[index];
                  return MilestoneDragProxy(
                    milestone: milestone,
                    sequence: index + 1,
                    animation: animation,
                  );
                },
                onReorder: _handleDragReorder,
                itemCount: visibleMilestones.length,
                itemBuilder: (context, index) {
                  final milestone = visibleMilestones[index];
                  return MilestoneEntry(
                    key: ValueKey(milestone.id),
                    milestone: milestone,
                    sequence: index + 1,
                    isLast: index == visibleMilestones.length - 1,
                    canMoveUp: index > 0 && !isMutationLocked,
                    canMoveDown:
                        index < visibleMilestones.length - 1 &&
                        !isMutationLocked,
                    showDragHandle: !isMutationLocked,
                    onMoveUp: index > 0 && !isMutationLocked
                        ? () => _handleMoveUp(index)
                        : null,
                    onMoveDown:
                        index < visibleMilestones.length - 1 &&
                            !isMutationLocked
                        ? () => _handleMoveDown(index)
                        : null,
                    onEdit: isMutationLocked
                        ? null
                        : () => _handleEditPressed(milestone),
                    onDelete: isMutationLocked
                        ? null
                        : () => _handleDeletePressed(milestone),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
