import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class ClientDetailsNoProjectsComponent extends StatelessWidget {
  const ClientDetailsNoProjectsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No projects for this client yet.',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Projects attached to this relationship will appear here.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
