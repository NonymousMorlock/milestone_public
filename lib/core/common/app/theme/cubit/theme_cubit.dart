import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:milestone/core/helpers/cache_helper.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({required ThemeMode initialMode})
    : super(ThemeState(themeMode: initialMode));

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      throw UnsupportedError('ThemeMode.system is not supported in this phase');
    }
    if (state.themeMode == mode) return;
    emit(state.copyWith(themeMode: mode));
    await CacheHelper.instance.cacheThemeMode(mode: mode);
  }

  Future<void> toggle() async {
    final nextMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(nextMode);
  }
}
