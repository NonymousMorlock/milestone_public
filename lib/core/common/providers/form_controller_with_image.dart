import 'package:flutter/widgets.dart';

class FormControllerWithImage {
  bool _imageIsFile = false;

  bool get imageIsFile => _imageIsFile;

  final imageController = TextEditingController();
  final imagePathController = TextEditingController();

  void changeImageMode({required bool imageIsFile}) {
    if (_imageIsFile != imageIsFile) {
      _imageIsFile = imageIsFile;
    }
  }
}
