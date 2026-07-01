import 'package:flutter/material.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  const CacheHelper._internal();

  static const CacheHelper instance = CacheHelper._internal();

  static const _toolsKey = 'my-freelance-tools';
  static const _themeModeKey = 'selected-theme-mode';
  static const _legacyThemeKey = 'selected-theme';

  Future<void> cacheTools(List<String> tools) async {
    try {
      await sl<SharedPreferences>().setStringList(_toolsKey, tools);
    } on Exception catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<List<String>> fetchTools() async {
    try {
      return sl<SharedPreferences>().getStringList(_toolsKey) ?? [];
    } on Exception catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
      return [];
    }
  }

  Future<void> cacheThemeMode({required ThemeMode mode}) async {
    try {
      await sl<SharedPreferences>().setString(_themeModeKey, mode.name);
    } on Exception catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<ThemeMode> fetchThemeMode() async {
    try {
      final prefs = sl<SharedPreferences>();
      final storedMode = prefs.getString(_themeModeKey);
      if (storedMode case final String modeName) {
        return switch (modeName) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.dark,
        };
      }

      final legacyIsDark = prefs.getBool(_legacyThemeKey);
      if (legacyIsDark != null) {
        final resolved = legacyIsDark ? ThemeMode.dark : ThemeMode.light;
        await cacheThemeMode(mode: resolved);
        return resolved;
      }

      return ThemeMode.dark;
    } on Exception catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
      return ThemeMode.dark;
    }
  }
}
