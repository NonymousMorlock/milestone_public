import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class ProjectPendingDeletionBadge extends StatelessWidget {
  const ProjectPendingDeletionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: const .symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: .circular(999),
      ),
      child: Text(
        'Pending deletion',
        style: context.textTheme.labelLarge?.copyWith(
          color: scheme.onErrorContainer,
          fontWeight: .w700,
        ),
      ),
    );
  }
}
