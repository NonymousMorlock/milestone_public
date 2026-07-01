import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class ClientDetailsMessageStateComponent extends StatelessWidget {
  const ClientDetailsMessageStateComponent({
    required this.title,
    required this.message,
    this.onBackToList,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onBackToList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        if (onBackToList != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onBackToList,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to Clients'),
          ),
        ],
      ],
    );
  }
}
