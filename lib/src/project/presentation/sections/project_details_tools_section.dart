import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ProjectDetailsToolsSection extends StatelessWidget {
  const ProjectDetailsToolsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    if (project.tools.isEmpty) {
      return Text(
        'No tools captured for this project yet.',
        style: context.textTheme.bodyLarge?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: project.tools.map((tool) => Chip(label: Text(tool))).toList(),
    );
  }
}
