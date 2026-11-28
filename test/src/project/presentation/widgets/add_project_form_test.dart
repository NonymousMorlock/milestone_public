import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/add_or_edit_project_form.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    final prefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => prefs);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildSubject() {
    return ChangeNotifierProvider(
      create: (_) => ProjectFormController(),
      child: const Scaffold(
        body: SingleChildScrollView(
          child: AddOrEditProjectForm(isEdit: false),
        ),
      ),
    );
  }

  testWidgets('groups the project form into the shadowed sections', (
    tester,
  ) async {
    await tester.pumpApp(buildSubject());
    await tester.pump();

    expect(find.text('Project basics'), findsOneWidget);
    expect(find.text('Client and commercial terms'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Descriptions, notes, and links'), findsOneWidget);
    expect(find.text('Tools and gallery'), findsOneWidget);
    expect(find.text('Add Client'), findsOneWidget);
  });

  testWidgets('stays stable on compact widths without overflow', (
    tester,
  ) async {
    await tester.pumpApp(
      buildSubject(),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
