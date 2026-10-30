import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/app/shell/app_shell_destination.dart';
import 'package:milestone/app/shell/widgets/shell_sidebar.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/src/profile/presentation/views/profile_view.dart';
import 'package:milestone/src/project/presentation/views/all_projects_view.dart';

class AdaptiveAppShell extends StatelessWidget {
  const AdaptiveAppShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  static const List<AppShellDestination> _destinations =
      AppShellDestination.values;

  @override
  Widget build(BuildContext context) {
    final destination =
        destinationFromLocation(location) ?? AppShellDestination.home;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = AppLayout.classify(constraints.maxWidth);
        final compact = sizeClass == AppLayoutSize.compact;
        return Scaffold(
          appBar: compact
              ? AppBar(
                  title: const Text('Milestone'),
                  actions: [
                    IconButton(
                      key: const Key('shell_profile_action'),
                      onPressed: () => context.go(ProfileView.path),
                      icon: const Icon(Icons.account_circle_outlined),
                    ),
                  ],
                )
              : null,
          body: Row(
            children: [
              if (!compact)
                SafeArea(
                  child: ShellSidebar(
                    selectedDestination: destination,
                    onSelectDestination: (value) => context.go(value.location),
                    onAddProject: () => context.go(AppRoutes.addProject),
                    onOpenProfile: () => context.go(ProfileView.path),
                  ),
                ),
              Expanded(
                child: compact ? child : SafeArea(child: child),
              ),
            ],
          ),
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: _destinations.indexOf(destination),
                  onDestinationSelected: (index) {
                    context.go(_destinations[index].location);
                  },
                  destinations: _destinations
                      .map(
                        (value) => NavigationDestination(
                          icon: Icon(value.icon),
                          label: value.label,
                        ),
                      )
                      .toList(),
                )
              : null,
          floatingActionButton:
              compact &&
                  (location == AppRoutes.initial ||
                      location == AllProjectsView.path)
              ? FloatingActionButton.extended(
                  key: const Key('shell_add_project_fab'),
                  onPressed: () => context.go(AppRoutes.addProject),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Project'),
                )
              : null,
        );
      },
    );
  }
}
