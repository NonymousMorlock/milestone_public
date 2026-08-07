import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/l10n/arb/app_localizations.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
    ThemeData? darkTheme,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(390, 844),
    GoRouter? router,
  }) async {
    view.physicalSize = surfaceSize;
    view.devicePixelRatio = 1;
    addTearDown(() {
      view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    if (router != null) {
      await pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: theme ?? AppTheme.lightTheme,
          darkTheme: darkTheme ?? AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      return;
    }

    await pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        darkTheme: darkTheme ?? AppTheme.darkTheme,
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: widget,
      ),
    );
  }
}
