import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bootstrap5/flutter_bootstrap5.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/app/routing/router.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/core/common/app/theme/cubit/theme_cubit.dart';
import 'package:milestone/l10n/arb/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return FlutterBootstrap5(
            builder: (_) => MaterialApp.router(
              routerConfig: router,
              themeMode: state.themeMode,
              theme: AppTheme.lightTheme,
              builder: FToastBuilder(),
              darkTheme: AppTheme.darkTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          );
        },
      ),
    );
  }
}
