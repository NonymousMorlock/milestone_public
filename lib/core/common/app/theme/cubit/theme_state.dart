// coverage:ignore-file
part of 'theme_cubit.dart';

abstract class ThemeState {
  Color get backgroundColor;
  Color get primaryTextColor;
  // Color get appBarColor;
  // Color get accentColor;
  // MaterialColor get primarySwatch;
}

class ThemeStateDark implements ThemeState {
  const ThemeStateDark();
  @override
  Color get backgroundColor => const Color(0xff191821);

  @override
  Color get primaryTextColor => const Color(0xFFEEEEEE);
}

class ThemeStateLight implements ThemeState {
  const ThemeStateLight();
  @override
  Color get backgroundColor => const Color(0xFFFFFFFF);

  @override
  Color get primaryTextColor => const Color(0xFF000000);
}
