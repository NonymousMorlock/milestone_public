// We need the enums to be all caps
// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';

class AppState {
  AppState._internal();

  static final AppState instance = AppState._internal();

  final ValueNotifier<$State> _current = ValueNotifier<$State>($State.IDLE);
  final ValueNotifier<$State> _previous = ValueNotifier<$State>($State.IDLE);

  void update($State state) {
    if (_current.value != state) {
      _previous.value = _current.value;
      _current.value = state;
    }
  }

  void resetCurrent() {
    _current.value = $State.IDLE;
  }

  void startLoading() {
    update($State.LOADING);
  }

  void stopLoading() {
    update($State.IDLE);
  }

  ValueListenable<$State> get current => _current;

  ValueListenable<$State> get previous => _previous;
}

enum $State { IDLE, LOADING }
