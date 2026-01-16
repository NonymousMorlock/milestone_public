import 'package:intl/intl.dart';

extension DoubleExt on double {
  String get currency {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: r'$',
    ).format(this);
  }
}
