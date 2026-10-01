import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';

class AddOrEditProjectBootstrapErrorComponent extends StatelessWidget {
  const AddOrEditProjectBootstrapErrorComponent({
    required this.error,
    required this.onRetry,
    required this.onBack,
    super.key,
  });

  final ProjectError error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: .min,
          children: [
            Text(
              error.title,
              style: context.textTheme.titleMedium,
              textAlign: .center,
            ),
            const SizedBox(height: 12),
            Text(
              error.message,
              textAlign: .center,
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
