import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class HomeEmptyProjectsStateComponent extends StatelessWidget {
  const HomeEmptyProjectsStateComponent({
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
          'No projects have been created yet.',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start with one project so the dashboard can track work, deadlines, '
          'and money.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(200, 45),
            maximumSize: const Size.fromWidth(600),
          ),
          onPressed: onAddProject,
          icon: const Icon(Icons.add),
          label: const Text('Add Project'),
        ),
      ],
    );
  }
}

@Preview(name: 'Home Empty Projects State Component', group: 'Components')
Widget preview() {
  return HomeEmptyProjectsStateComponent(onAddProject: () {});
}
