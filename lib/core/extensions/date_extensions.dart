import 'package:intl/intl.dart';

extension DateExt on DateTime {
  String get yMd => DateFormat.yMd().format(this);
}
