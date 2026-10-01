import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/double_extensions.dart';
import 'package:milestone/src/client/presentation/layout/client_workspace_snapshot_layout.dart';

class ClientSummaryTile extends StatelessWidget {
  const ClientSummaryTile({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final ClientWorkspaceSnapshotLayout summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        summary.clientImage != null &&
                            summary.clientImage!.isNotEmpty
                        ? NetworkImage(summary.clientImage!)
                        : null,
                    child:
                        summary.clientImage == null ||
                            summary.clientImage!.isEmpty
                        ? Text(_initials(summary.clientName))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      summary.clientName,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                summary.totalSpent.currency,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Relationship spend',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${summary.projectCount} '
                'linked '
                '${summary.projectCount == 1 ? 'project' : 'projects'}',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
