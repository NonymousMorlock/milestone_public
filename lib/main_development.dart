// import 'package:flutter/rendering.dart';
import 'package:milestone/app/app.dart';
import 'package:milestone/bootstrap.dart';
import 'package:milestone/core/enums/environment.dart';
import 'package:provider/provider.dart';

void main() {
  // debugRepaintRainbowEnabled = true;
  bootstrap(
    () => Provider<Environment>.value(
      value: Environment.development,
      child: const App(),
    ),
  );
}
