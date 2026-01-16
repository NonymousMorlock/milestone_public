import 'package:flutter/foundation.dart';

class ExpandableCardController extends ChangeNotifier {
  dynamic _expandedIdentifier;

  dynamic get expandedIdentifier => _expandedIdentifier;

  void setExpandedIdentifier(dynamic identifier) {
    if (_expandedIdentifier != identifier) _expandedIdentifier = identifier;
    notifyListeners();
  }
}
