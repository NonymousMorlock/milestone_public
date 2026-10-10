import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/shell/adaptive_app_shell.dart';
import 'package:milestone/app/shell/app_shell_destination.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  Widget buildShell({
    required String location,
    required Size size,
  }) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: AdaptiveAppShell(
        location: location,
        child: const Placeholder(),
      ),
    );
  }

  testWidgets('compact shell uses navigation bar and floating action', (
    tester,
  ) async {
    const size = Size(390, 844);

    await tester.pumpApp(
      buildShell(location: '/', size: size),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byKey(const Key('shell_add_project_button')), findsNothing);
  });

  testWidgets('expanded shell uses sidebar and no bottom navigation', (
    tester,
  ) async {
    const size = Size(1280, 900);

    await tester.pumpApp(
      buildShell(location: '/projects', size: size),
      surfaceSize: size,
    );

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byKey(const Key('shell_add_project_button')), findsOneWidget);
    expect(find.byKey(const Key('shell_profile_button')), findsOneWidget);
  });

  test('classifies nested project routes as projects destination', () {
    expect(destinationFromLocation('/'), AppShellDestination.home);
    expect(
      destinationFromLocation('/projects/project-1'),
      AppShellDestination.projects,
    );
    expect(destinationFromLocation('/add-project'), isNull);
  });
}
