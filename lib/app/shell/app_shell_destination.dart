import 'package:flutter/material.dart';
import 'package:milestone/app/routing/app_routes.dart';

enum AppShellDestination {
  home,
  projects,
}

extension AppShellDestinationX on AppShellDestination {
  String get label => switch (this) {
    AppShellDestination.home => 'Home',
    AppShellDestination.projects => 'Projects',
  };

  IconData get icon => switch (this) {
    AppShellDestination.home => Icons.home_rounded,
    AppShellDestination.projects => Icons.folder_copy_outlined,
  };

  String get location => switch (this) {
    AppShellDestination.home => AppRoutes.initial,
    AppShellDestination.projects => '/projects',
  };
}

AppShellDestination? destinationFromLocation(String location) {
  if (location == AppRoutes.initial) {
    return AppShellDestination.home;
  }
  if (location.startsWith('/projects')) {
    return AppShellDestination.projects;
  }
  return null;
}
