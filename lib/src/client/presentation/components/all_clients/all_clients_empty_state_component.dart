import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class AllClientsEmptyStateComponent extends StatelessWidget {
  const AllClientsEmptyStateComponent({
    required this.onAddClient,
    super.key,
  });

  final VoidCallback onAddClient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No clients yet.',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a client before attaching new work to the relationship.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAddClient,
          icon: const Icon(Icons.add),
          label: const Text('Add Client'),
        ),
      ],
    );
  }
}
