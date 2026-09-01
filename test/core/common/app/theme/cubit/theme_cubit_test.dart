import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/core/common/app/theme/cubit/theme_cubit.dart';
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

  test(
    'toggle switches from dark to light and persists the new mode',
    () async {
      final cubit = ThemeCubit(initialMode: ThemeMode.dark);

      await cubit.toggle();

      expect(cubit.state.themeMode, ThemeMode.light);
      expect(
        sl<SharedPreferences>().getString('selected-theme-mode'),
        ThemeMode.light.name,
      );
    },
  );

  test(
    'setThemeMode does not write again when the mode is unchanged',
    () async {
      final cubit = ThemeCubit(initialMode: ThemeMode.dark);

      await cubit.setThemeMode(ThemeMode.dark);

      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(sl<SharedPreferences>().getString('selected-theme-mode'), isNull);
    },
  );
}
