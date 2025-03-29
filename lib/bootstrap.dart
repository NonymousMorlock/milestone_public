import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:milestone/core/services/injection_container.dart';
import 'package:milestone/core/services/router.dart';
import 'package:milestone/firebase_options.dart';
import 'package:provider/provider.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
    if (kIsWasm || kIsWeb) {
      log('-------------STACKTRACE-------------\n${details.stack}');
    }
  };

  Bloc.observer = const AppBlocObserver();
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await init();
  FirebaseUIAuth.configureProviders([EmailAuthProvider()]);
  // Add cross-flavor configuration here
  usePathUrlStrategy();
  runApp(
    Provider(
      create: (_) => FToast()..init(rootNavigatorKey.currentContext!),
      child: await builder(),
    ),
  );
}
