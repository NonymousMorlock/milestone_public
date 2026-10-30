import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ProjectDetailsNotesSection extends StatelessWidget {
  const ProjectDetailsNotesSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    if (project.notes.isEmpty) {
      return Text(
        'No notes captured for this project yet.',
        style: context.textTheme.bodyLarge?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: project.notes.mapIndexed((index, note) {
        return Padding(
          padding: const .only(bottom: 12),
          child: Row(
            crossAxisAlignment: .start,
            spacing: 12,
            children: [
              Text(
                '${index + 1}.',
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: .w700,
                ),
              ),
              Expanded(
                child: Text(note, style: context.textTheme.bodyLarge),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
