import 'package:flutter/foundation.dart';
import 'package:milestone/core/services/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  const CacheHelper._internal();

  static const CacheHelper instance = CacheHelper._internal();

  static const _toolsKey = 'my-freelance-tools';
  static const _themeKey = 'selected-theme';

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

  Future<void> cacheThemeMode({required bool isDarkMode}) async {
    try {
      await sl<SharedPreferences>().setBool(_themeKey, isDarkMode);
    } on Exception catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  /// Returns true if the theme mode is dark.
  Future<bool> fetchThemeMode$isDark() async {
    try {
      return sl<SharedPreferences>().getBool(_themeKey) ?? true;
    } on Exception catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
      return true;
    }
  }
}
