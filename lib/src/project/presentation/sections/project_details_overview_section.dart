import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/date_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ProjectDetailsOverviewSection extends StatelessWidget {
  const ProjectDetailsOverviewSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final details = <({String label, String value})>[
      (label: 'Start date', value: project.startDate.yMd),
      (label: 'End date', value: project.endDate?.yMd ?? 'Not completed'),
      (label: 'Deadline', value: project.deadline?.yMd ?? 'No deadline'),
      (
        label: 'Budget mode',
        value: project.isFixed ? 'Fixed budget' : 'Flexible budget',
      ),
    ];

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (project.longDescription?.trim().isNotEmpty ?? false) ...[
          Text(
            project.longDescription!,
            style: context.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Short description',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: .w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          project.shortDescription,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...details.map(
          (detail) => Padding(
            padding: const .only(bottom: 10),
            child: Row(
              crossAxisAlignment: .start,
              spacing: 16,
              children: [
                Expanded(
                  child: Text(
                    detail.label,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: .w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    detail.value,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
