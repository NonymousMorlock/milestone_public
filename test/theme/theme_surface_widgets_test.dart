import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/app/theme/milestone_theme_extension.dart';
import 'package:milestone/core/common/providers/form_controller_with_image.dart';
import 'package:milestone/core/common/widgets/form_checkbox.dart';
import 'package:milestone/core/common/widgets/text_placeholder.dart';
import 'package:milestone/core/enums/environment.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/home/presentation/widgets/nav_tile.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/utils/control.dart';
import 'package:milestone/src/project/presentation/widgets/client_picker.dart';
import 'package:milestone/src/project/presentation/widgets/gallery_field.dart';
import 'package:milestone/src/project/presentation/widgets/image_field.dart';
import 'package:milestone/src/project/presentation/widgets/project_form_links.dart';
import 'package:milestone/src/project/presentation/widgets/project_info_tile.dart';
import 'package:milestone/src/project/presentation/widgets/tools_selector.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildHarness(Widget child, {ThemeMode themeMode = ThemeMode.dark}) {
  return MultiProvider(
    providers: [
      Provider<Environment>.value(value: Environment.production),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'my-freelance-tools': ['Flutter'],
    });
    await sl.reset();
    final prefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => prefs);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('FormCheckbox and TextPlaceholder use themed colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        const Column(
          children: [
            FormCheckbox(
              value: true,
              onChanged: _noopChanged,
              label: 'Fixed Budget',
              infoMessage: 'Fixed budget info',
            ),
            TextPlaceholder(width: 120),
          ],
        ),
      ),
    );

    final theme = AppTheme.darkTheme;
    final milestoneTheme = theme.extension<MilestoneThemeExtension>()!;
    final label = tester.widget<Text>(find.text('Fixed Budget'));
    final icon = tester.widget<Icon>(find.byIcon(Icons.info));
    final placeholderContainer = tester
        .widgetList<Container>(find.byType(Container))
        .lastWhere((container) => container.color != null);

    expect(label.style?.color, theme.colorScheme.onSurface);
    expect(icon.color, theme.colorScheme.onSurfaceVariant);
    expect(find.byType(TextPlaceholder), findsOneWidget);
    expect(placeholderContainer.color, milestoneTheme.placeholderSolid);
  });

  testWidgets(
    'project form descendants use theme typography and outline colors',
    (
      tester,
    ) async {
      final imagePath = File('test/fixtures/project.png').absolute.path;
      final projectController = ProjectFormController()..addLink();
      addTearDown(projectController.dispose);
      projectController.linkControllers.first.titleController.text =
          'Portfolio';
      projectController.linkControllers.first.urlController.text =
          'https://example.com';

      final imageController = FormControllerWithImage()
        ..imageController.text = imagePath
        ..imagePathController.text = imagePath
        ..changeImageMode(imageIsFile: true);
      final galleryControl = Control(
        imageController: TextEditingController(text: imagePath),
        imagePathController: TextEditingController(text: imagePath),
        imageIsFile: true,
      );
      addTearDown(() {
        imageController.imageController.dispose();
        imageController.imagePathController.dispose();
        galleryControl.imageController.dispose();
        galleryControl.imagePathController.dispose();
      });

      await tester.pumpWidget(
        _buildHarness(
          ChangeNotifierProvider<ProjectFormController>.value(
            value: projectController,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const ProjectFormLinks(),
                  ImageField(
                    controller: imageController,
                    label: 'Project Image',
                  ),
                  GalleryField(controls: galleryControl, index: 0),
                ],
              ),
            ),
          ),
        ),
      );

      final theme = AppTheme.darkTheme;
      final linkHeading = tester.widget<Text>(find.text('Link 1'));
      final previews = tester
          .widgetList<Container>(find.byType(Container))
          .where((container) {
            final decoration = container.decoration;
            return decoration is BoxDecoration && decoration.image != null;
          })
          .map((container) => container.decoration! as BoxDecoration)
          .toList();

      expect(linkHeading.style?.fontWeight, FontWeight.w600);
      expect(
        linkHeading.style?.fontFamily,
        theme.textTheme.titleMedium?.fontFamily,
      );
      expect(previews, isNotEmpty);
      for (final preview in previews) {
        expect(
          preview.border,
          Border.all(color: theme.colorScheme.outlineVariant),
        );
      }
    },
  );

  testWidgets(
    'client picker and tools selector rely on app theme '
    'instead of local menu overrides',
    (
      tester,
    ) async {
      final controller = ProjectFormController()
        ..setClients([ClientModel.empty().copyWith(id: '1', name: 'Acme')]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildHarness(
          ChangeNotifierProvider<ProjectFormController>.value(
            value: controller,
            child: const Column(
              children: [
                ClientPicker(),
                ToolsSelector(),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final clientDropdown = tester.widget<DropdownMenu<Client>>(
        find.byWidgetPredicate((widget) => widget is DropdownMenu<Client>),
      );
      final toolsDropdown = tester.widget<DropdownMenu<String>>(
        find.byWidgetPredicate((widget) => widget is DropdownMenu<String>),
      );

      expect(clientDropdown.inputDecorationTheme, isNull);
      expect(clientDropdown.menuStyle, isNull);
      expect(toolsDropdown.inputDecorationTheme, isNull);
      expect(toolsDropdown.menuStyle, isNull);

      final helperText = tester.widget<Text>(
        find.text("Can't find the client? Add Client"),
      );
      expect(
        helperText.style?.color,
        AppTheme.darkTheme.colorScheme.onSurfaceVariant,
      );
    },
  );

  testWidgets('NavTile and ProjectInfoTile use theme-driven semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        const Column(
          children: [
            NavTile(icon: Icons.settings_outlined, title: 'Settings'),
            ProjectInfoTile(
              text: 'Fixed',
              showCheck: true,
              checked: true,
            ),
          ],
        ),
      ),
    );

    final theme = AppTheme.darkTheme;
    final milestoneTheme = theme.extension<MilestoneThemeExtension>()!;
    final listTile = tester.widget<ListTile>(find.byType(ListTile));
    final trailingIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_right));
    final projectInfoText = tester.widget<Text>(find.text('Fixed'));
    final projectInfoIcon = tester.widget<Icon>(find.byIcon(Icons.check));

    expect(listTile.tileColor, milestoneTheme.navTileSurface);
    expect(trailingIcon.color, theme.colorScheme.onSurface);
    expect(projectInfoText.style?.color, theme.colorScheme.onSurface);
    expect(projectInfoIcon.color, milestoneTheme.statusOnTrack);
  });
}

void _noopChanged(bool? _) {}
