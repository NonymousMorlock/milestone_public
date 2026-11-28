import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ProjectDetailsGallerySection extends StatelessWidget {
  const ProjectDetailsGallerySection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    if (project.images.isEmpty) {
      return Text(
        'No gallery images have been attached to this project.',
        style: context.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: project.images.map((image) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            image,
            width: 160,
            height: 110,
            fit: .cover,
            errorBuilder: (_, _, _) {
              return Container(
                width: 160,
                height: 110,
                color: scheme.surfaceContainerHighest,
                alignment: .center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
