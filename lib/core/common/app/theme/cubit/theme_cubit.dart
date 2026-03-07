import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:milestone/core/helpers/cache_helper.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({required bool isDarkMode}) : super(const ThemeStateDark()) {
    if (!isDarkMode) emit(const ThemeStateLight());
  }

  Future<void> goDark() async {
    await CacheHelper.instance.cacheThemeMode(isDarkMode: true);
    emit(const ThemeStateDark());
  }

  Future<void> goLight() async {
    await CacheHelper.instance.cacheThemeMode(isDarkMode: false);
    emit(const ThemeStateLight());
  }

  Future<void> toggle() async {
    if (state is ThemeStateLight) {
      await goDark();
    } else {
      await goLight();
    }
  }
}
