import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

extension WidgetListExt on List<Widget> {
  List<Widget> gap(double gap) {
    final list = <Widget>[];
    for (var i = 0; i < length; i++) {
      if (i > 0) {
        list.add(Gap(gap));
      }
      list.add(this[i]);
    }
    return list;
  }
}
