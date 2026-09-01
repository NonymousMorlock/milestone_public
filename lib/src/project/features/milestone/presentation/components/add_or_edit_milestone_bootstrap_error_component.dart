import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class AddOrEditMilestoneBootstrapErrorComponent extends StatelessWidget {
  const AddOrEditMilestoneBootstrapErrorComponent({
    required this.title,
    required this.message,
    required this.onRetry,
    required this.onBack,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: context.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onBack,
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
