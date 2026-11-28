import 'package:flutter/material.dart';
import 'package:milestone/app/theme/milestone_theme_extension.dart';
import 'package:milestone/core/res/styles/colours.dart';

sealed class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = _buildLightColorScheme();
    final milestoneTheme = MilestoneThemeExtension.light(colorScheme);
    return _buildTheme(
      colorScheme: colorScheme,
      milestoneTheme: milestoneTheme,
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = _buildDarkColorScheme();
    final milestoneTheme = MilestoneThemeExtension.dark(colorScheme);
    return _buildTheme(
      colorScheme: colorScheme,
      milestoneTheme: milestoneTheme,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required MilestoneThemeExtension milestoneTheme,
  }) {
    final textTheme = _buildTextTheme(colorScheme.brightness);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Switzer',
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: _buildAppBarTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(
        colorScheme,
        milestoneTheme,
      ),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      popupMenuTheme: _buildPopupMenuTheme(colorScheme),
      dropdownMenuTheme: _buildDropdownMenuTheme(
        colorScheme,
        milestoneTheme,
      ),
      dialogTheme: _buildDialogTheme(colorScheme, textTheme),
      datePickerTheme: _buildDatePickerTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      dividerColor: colorScheme.outlineVariant,
      extensions: <ThemeExtension<dynamic>>[milestoneTheme],
    );
  }

  static ColorScheme _buildLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: Colours.lightThemePrimaryColour,
    ).copyWith(
      primary: Colours.lightThemePrimaryColour,
      secondary: Colours.lightThemeSecondaryColour,
      tertiary: Colours.lightThemePinkColour,
      surface: Colours.lightThemeWhiteColour,
      onSurface: Colours.lightThemePrimaryTextColour,
      onSurfaceVariant: Colours.lightThemeSecondaryTextColour,
      outlineVariant: Colours.lightThemeStockColour,
      surfaceContainerHighest: Colours.lightThemeTintStockColour,
      surfaceContainerHigh: Colors.white,
      surfaceContainer: Colours.lightThemeTintStockColour,
      shadow: Colors.black12,
    );
  }

  static ColorScheme _buildDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: Colours.lightThemePrimaryColour,
      brightness: Brightness.dark,
    ).copyWith(
      primary: Colours.lightThemePrimaryTint,
      secondary: Colours.lightThemeSecondaryColour,
      tertiary: Colours.lightThemePinkColour,
      surface: Colours.darkThemeDarkSharpColour,
      onSurface: Colours.lightThemeWhiteColour,
      onSurfaceVariant: Colours.lightThemeSecondaryTextColour,
      outlineVariant: Colors.blueGrey.shade700,
      surfaceContainerHighest: Colours.darkThemeDarkNavBarColour,
      surfaceContainerHigh: Colors.blueGrey.shade900,
      surfaceContainer: Colours.darkThemeDarkNavBarColour,
      shadow: Colors.black54,
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme.apply(fontFamily: 'Switzer');
  }

  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    ColorScheme colorScheme,
    MilestoneThemeExtension milestoneTheme,
  ) {
    final border = OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(10),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: milestoneTheme.fieldFillSubtle,
      border: border,
      errorBorder: border,
      focusedErrorBorder: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: border,
      contentPadding: const EdgeInsets.only(top: 10, left: 10),
      hintStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
      helperStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
      ),
      prefixStyle: TextStyle(
        fontSize: 16,
        color: colorScheme.onSurface,
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(
    ColorScheme colorScheme,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    return ChipThemeData.fromDefaults(
      secondaryColor: colorScheme.primary,
      brightness: colorScheme.brightness,
      labelStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ).copyWith(
      backgroundColor: colorScheme.surfaceContainerHighest,
      disabledColor: colorScheme.surfaceContainer,
      selectedColor: colorScheme.surfaceContainerHighest,
      secondarySelectedColor: colorScheme.surfaceContainerHighest,
      deleteIconColor: colorScheme.error,
      side: BorderSide(color: colorScheme.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(90),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  static PopupMenuThemeData _buildPopupMenuTheme(ColorScheme colorScheme) {
    return PopupMenuThemeData(
      color: colorScheme.surfaceContainerHighest,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: colorScheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static DropdownMenuThemeData _buildDropdownMenuTheme(
    ColorScheme colorScheme,
    MilestoneThemeExtension milestoneTheme,
  ) {
    final border = OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(10),
    );

    return DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: milestoneTheme.fieldFillSubtle,
        border: border,
        errorBorder: border,
        focusedErrorBorder: border,
        enabledBorder: border,
        focusedBorder: border,
        contentPadding: const EdgeInsets.only(top: 10, left: 10),
        prefixStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHighest,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(
          BorderSide(color: colorScheme.outlineVariant),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  static DialogThemeData _buildDialogTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
    );
  }

  static DatePickerThemeData _buildDatePickerTheme(ColorScheme colorScheme) {
    return DatePickerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: colorScheme.primary,
      headerForegroundColor: colorScheme.onPrimary,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.onSurface;
      }),
      todayForegroundColor: WidgetStatePropertyAll(colorScheme.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      color: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      contentTextStyle: TextStyle(color: colorScheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }
}
