import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/date_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/layout/project_workspace_status_layout.dart';

class ProjectDetailsScheduleSection extends StatelessWidget {
  const ProjectDetailsScheduleSection({
    required this.project,
    super.key,
  });

  final Project project;

  @override
  Widget build(BuildContext context) {
    final status = ProjectWorkspaceStatusLayout.fromProject(project);
    final rows = <({String label, String value})>[
      (label: 'Start date', value: project.startDate.yMd),
      (label: 'Deadline', value: project.deadline?.yMd ?? 'No deadline'),
      (label: 'End date', value: project.endDate?.yMd ?? 'Not completed'),
      (
        label: 'Budget mode',
        value: project.isFixed ? 'Fixed budget' : 'Flexible budget',
      ),
      (label: 'Status', value: status.label),
    ];

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        ...rows.map((row) {
          return Padding(
            padding: const .only(bottom: 12),
            child: Row(
              crossAxisAlignment: .start,
              spacing: 16,
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: .w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    row.value,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          status.supportingCopy,
          style: context.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

@Preview(name: 'Project Details Schedule Section', group: 'Sections')
Widget projectDetailsScheduleSectionPreview() {
  return ProjectDetailsScheduleSection(
    project: Project.empty().copyWith(
      id: '1',
      startDate: DateTime(2024),
      deadline: DateTime(2024, 3, 31),
      isFixed: true,
    ),
  );
}
