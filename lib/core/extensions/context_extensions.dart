import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/theme/milestone_theme_extension.dart';
import 'package:milestone/core/enums/environment.dart';
import 'package:provider/provider.dart';

extension ContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colorScheme => theme.colorScheme;

  MilestoneThemeExtension get milestoneTheme =>
      theme.extension<MilestoneThemeExtension>()!;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get size => MediaQuery.sizeOf(this);

  double get height => size.height;

  double get width => size.width;

  bool get isDarkMode => theme.brightness == Brightness.dark;

  bool get isLightMode => theme.brightness == Brightness.light;

  Brightness get platformBrightness => MediaQuery.platformBrightnessOf(this);

  Environment get environment => read<Environment>();

  /// A method that uses `go` when the app is running on web but uses `push`
  /// otherwise.
  Future<T?> navigateTo<T extends Object?>(
    String location, {
    Object? extra,
  }) async {
    if (kIsWeb || kIsWasm) {
      go(location, extra: extra);
      return null;
    } else {
      return push<T>(location, extra: extra);
    }
  }
}
