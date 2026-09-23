import 'package:flutter/widgets.dart';

class Control {
  const Control({
    required this.imageController,
    required this.imagePathController,
    this.imageIsFile = false,
  });

  final TextEditingController imageController;
  final TextEditingController imagePathController;
  final bool imageIsFile;

  Control copyWith({bool? imageIsFile}) {
    return Control(
      imageController: imageController,
      imagePathController: imagePathController,
      imageIsFile: imageIsFile ?? this.imageIsFile,
    );
  }
}
