import 'package:flutter/material.dart';
import 'package:milestone/app/routing/app_routes.dart';

enum AppShellDestination {
  home,
  projects,
  clients,
}

extension AppShellDestinationX on AppShellDestination {
  String get label => switch (this) {
    AppShellDestination.home => 'Home',
    AppShellDestination.projects => 'Projects',
    AppShellDestination.clients => 'Clients',
  };

  IconData get icon => switch (this) {
    AppShellDestination.home => Icons.home_rounded,
    AppShellDestination.projects => Icons.folder_copy_outlined,
    AppShellDestination.clients => Icons.groups_outlined,
  };

  String get location => switch (this) {
    AppShellDestination.home => AppRoutes.initial,
    AppShellDestination.projects => '/projects',
    AppShellDestination.clients => AppRoutes.clients,
  };
}

AppShellDestination? destinationFromLocation(String location) {
  if (location == AppRoutes.initial) {
    return AppShellDestination.home;
  }
  if (location.startsWith('/projects')) {
    return AppShellDestination.projects;
  }
  if (location.startsWith(AppRoutes.clients)) {
    return AppShellDestination.clients;
  }
  return null;
}
