import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

void main() {
  testWidgets(
    'AppTheme registers the milestone extension and context.isDarkMode '
    'follows theme brightness',
    (tester) async {
      var isDarkMode = false;
      Color? heroGradientStart;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              isDarkMode = context.isDarkMode;
              heroGradientStart = context.milestoneTheme.heroGradientStart;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(isDarkMode, isTrue);
      expect(heroGradientStart, isNotNull);
    },
  );
}
