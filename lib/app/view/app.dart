import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bootstrap5/flutter_bootstrap5.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:milestone/core/common/app/theme/cubit/theme_cubit.dart';
import 'package:milestone/core/res/styles/colours.dart';
import 'package:milestone/core/services/injection_container.dart';
import 'package:milestone/core/services/router.dart';
import 'package:milestone/l10n/arb/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colours.lightThemePrimaryColour,
      ),
      fontFamily: 'Switzer',
      scaffoldBackgroundColor: Colours.lightThemeWhiteColour,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colours.lightThemeWhiteColour,
        foregroundColor: Colours.lightThemePrimaryTextColour,
      ),
      useMaterial3: true,
    );
    return BlocProvider(
      create: (context) => sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return FlutterBootstrap5(
            builder: (_) => MaterialApp.router(
              routerConfig: router,
              themeMode:
                  state is ThemeStateLight ? ThemeMode.light : ThemeMode.dark,
              theme: theme,
              builder: FToastBuilder(),
              darkTheme: theme.copyWith(
                scaffoldBackgroundColor: Colours.darkThemeDarkSharpColour,
                textTheme: ThemeData.dark().textTheme,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colours.darkThemeDarkSharpColour,
                  foregroundColor: Colours.lightThemeWhiteColour,
                ),
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          );
        },
      ),
    );
  }
}
