import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/double_extensions.dart';
import 'package:milestone/src/client/presentation/layout/client_workspace_snapshot_layout.dart';

class ClientDetailsHeaderSection extends StatelessWidget {
  const ClientDetailsHeaderSection({
    required this.snapshot,
    super.key,
  });

  final ClientWorkspaceSnapshotLayout snapshot;

  @override
  Widget build(BuildContext context) {
    final overview = Column(
      crossAxisAlignment: .start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage:
              snapshot.clientImage != null && snapshot.clientImage!.isNotEmpty
              ? NetworkImage(snapshot.clientImage!)
              : null,
          child: snapshot.clientImage == null || snapshot.clientImage!.isEmpty
              ? Text(_initials(snapshot.clientName))
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          snapshot.clientName,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Relationship context and linked work at a glance.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final metrics = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final metric in [
          ('Total spent', snapshot.totalSpent.currency),
          ('Linked projects', '${snapshot.projectCount}'),
        ])
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      metric.$1,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metric.$2,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    return AppSectionCard(
      title: 'Relationship overview',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              AppLayout.classify(constraints.maxWidth) == AppLayoutSize.compact;
          if (compact) {
            return Column(
              crossAxisAlignment: .stretch,
              children: [
                overview,
                const SizedBox(height: 16),
                metrics,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: overview),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: metrics),
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    return parts.map((part) => part.substring(0, 1)).join().toUpperCase();
  }
}
