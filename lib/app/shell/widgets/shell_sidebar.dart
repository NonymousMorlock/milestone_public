import 'package:flutter/material.dart';
import 'package:milestone/app/shell/app_shell_destination.dart';
import 'package:milestone/app/shell/widgets/sidebar_destination_tile.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class ShellSidebar extends StatelessWidget {
  const ShellSidebar({
    required this.selectedDestination,
    required this.onSelectDestination,
    required this.onAddProject,
    required this.onOpenProfile,
    super.key,
  });

  final AppShellDestination selectedDestination;
  final ValueChanged<AppShellDestination> onSelectDestination;
  final VoidCallback onAddProject;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tokens = context.milestoneTheme;

    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(
          right: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Milestone',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('shell_add_project_button'),
            onPressed: onAddProject,
            icon: const Icon(Icons.add),
            label: const Text('Add Project'),
          ),
          const SizedBox(height: 24),
          ...AppShellDestination.values.map(
            (destination) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SidebarDestinationTile(
                destination: destination,
                selected: destination == selectedDestination,
                onTap: () => onSelectDestination(destination),
                backgroundColor: tokens.navTileSurface,
              ),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            key: const Key('shell_profile_button'),
            onPressed: onOpenProfile,
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Profile'),
          ),
        ],
      ),
    );
  }
}
