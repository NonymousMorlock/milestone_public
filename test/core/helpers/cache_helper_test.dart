import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/core/helpers/cache_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('fetchThemeMode returns dark by default', () async {
    final result = await CacheHelper.instance.fetchThemeMode();

    expect(result, ThemeMode.dark);
  });

  test('fetchThemeMode reads the canonical string key', () async {
    final prefs = sl<SharedPreferences>();
    await prefs.setString('selected-theme-mode', 'light');

    final result = await CacheHelper.instance.fetchThemeMode();

    expect(result, ThemeMode.light);
  });

  test('fetchThemeMode migrates the legacy bool key', () async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool('selected-theme', false);

    final result = await CacheHelper.instance.fetchThemeMode();

    expect(result, ThemeMode.light);
    expect(prefs.getString('selected-theme-mode'), 'light');
  });

  test('fetchThemeMode falls back safely on invalid string data', () async {
    final prefs = sl<SharedPreferences>();
    await prefs.setString('selected-theme-mode', 'broken');

    final result = await CacheHelper.instance.fetchThemeMode();

    expect(result, ThemeMode.dark);
  });
}
