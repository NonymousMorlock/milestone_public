import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/date_extensions.dart';
import 'package:milestone/core/extensions/double_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/widgets/project_info_tile.dart';
import 'package:milestone/src/project/presentation/widgets/project_pending_deletion_badge.dart';

class ProjectTileBottomHalf extends StatelessWidget {
  ProjectTileBottomHalf(
    this.project, {
    dynamic identifier,
    super.key,
  }) : identifier = identifier ?? project.id;

  final Project project;
  final dynamic identifier;

  @override
  Widget build(BuildContext context) {
    final tokens = context.milestoneTheme;
    final scheme = context.colorScheme;
    Color? deadlineColour;
    if (project.deadline != null) {
      if (project.deadline!.isBefore(DateTime.now())) {
        deadlineColour = tokens.statusOverdue;
      } else if (project.deadline!.isBefore(
        DateTime.now().add(const Duration(days: 7)),
      )) {
        deadlineColour = tokens.statusDueSoon;
      } else {
        deadlineColour = tokens.statusOnTrack;
      }
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tokens.projectCardGradientStart,
              tokens.projectCardGradientEnd,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (project.isPendingDeletion) ...[
                const ProjectPendingDeletionBadge(),
                const SizedBox(height: 12),
              ],
              Text(
                project.budget.currency,
                style: context.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ProjectInfoTile(
                text: 'Total Paid: ${project.totalPaid.currency}',
              ),
              ProjectInfoTile(text: project.clientName),
              ProjectInfoTile(text: project.projectType),
              ProjectInfoTile(
                text: project.isOneTime
                    ? 'One-time engagement'
                    : 'Continuous engagement',
              ),
              ProjectInfoTile(
                text: project.isFixed ? 'Fixed budget' : 'Flexible budget',
              ),
              ProjectInfoTile(text: 'Started: ${project.startDate.yMd}'),
              if (project.deadline != null)
                ProjectInfoTile(
                  text: 'Deadline: ${project.deadline!.yMd}',
                  style: TextStyle(color: deadlineColour),
                  showCheck: true,
                  icon: project.completed
                      ? null
                      : Icon(
                          Icons.alarm,
                          color: deadlineColour,
                        ),
                  checked:
                      project.deadline!.isBefore(DateTime.now()) ||
                      project.completed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
