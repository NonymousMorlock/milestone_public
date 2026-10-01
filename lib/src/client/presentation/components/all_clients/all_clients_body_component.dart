import 'package:flutter/material.dart';
import 'package:milestone/src/client/presentation/layout/client_workspace_snapshot_layout.dart';
import 'package:milestone/src/client/presentation/widgets/all_clients/client_summary_tile.dart';

class AllClientsBodyComponent extends StatelessWidget {
  const AllClientsBodyComponent({
    required this.summaries,
    required this.onOpenClient,
    super.key,
  });

  final List<ClientWorkspaceSnapshotLayout> summaries;
  final ValueChanged<ClientWorkspaceSnapshotLayout> onOpenClient;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: summaries.map((summary) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: ClientSummaryTile(
            summary: summary,
            onTap: () => onOpenClient(summary),
          ),
        );
      }).toList(),
    );
  }
}
