import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class AllProjectsEmptyStateComponent extends StatelessWidget {
  const AllProjectsEmptyStateComponent({
    required this.onAddProject,
    super.key,
  });

  final VoidCallback onAddProject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No projects yet.',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use Add Project to create the first tracked piece of work '
          'in this library.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAddProject,
          icon: const Icon(Icons.add),
          label: const Text('Add Project'),
        ),
      ],
    );
  }
}
