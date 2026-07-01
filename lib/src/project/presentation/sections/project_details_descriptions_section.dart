import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ProjectDetailsDescriptionsSection extends StatelessWidget {
  const ProjectDetailsDescriptionsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final longDescription = project.longDescription?.trim();
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 8,
      children: [
        Text(
          'Short description',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(project.shortDescription, style: context.textTheme.bodyLarge),
        const SizedBox.shrink(),
        Text(
          'Long description',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: .w700,
          ),
        ),
        Text(
          longDescription == null || longDescription.isEmpty
              ? 'No extended project description has been captured yet.'
              : longDescription,
          style: context.textTheme.bodyLarge?.copyWith(
            color: longDescription == null || longDescription.isEmpty
                ? context.colorScheme.onSurfaceVariant
                : null,
          ),
        ),
      ],
    );
  }
}

@Preview(name: 'Project Details Descriptions Section', group: 'Sections')
Widget projectDetailsDescriptionsSectionPreview() {
  return ProjectDetailsDescriptionsSection(
    project: Project.empty().copyWith(
      id: '1',
      shortDescription: 'A mobile app for tracking fitness activities.',
      longDescription:
          'This project involves developing a '
          'cross-platform mobile application that allows users to track '
          'their fitness activities, set goals, and monitor progress over '
          'time. The app will include features such as GPS tracking, '
          'workout logging, and social sharing.',
      clientName: 'FitTrack Inc.',
    ),
  );
}
