import 'package:milestone/app/app.dart';
import 'package:milestone/bootstrap.dart';
import 'package:milestone/core/enums/environment.dart';
import 'package:provider/provider.dart';

void main() {
  bootstrap(
    () => Provider<Environment>.value(
      value: Environment.staging,
      child: const App(),
    ),
  );
}
