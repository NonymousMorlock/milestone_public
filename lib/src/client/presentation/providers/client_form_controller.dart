import 'package:flutter/material.dart';
import 'package:milestone/core/common/providers/form_controller_with_image.dart';
import 'package:milestone/core/extensions/string_extensions.dart';
import 'package:milestone/src/client/data/models/client_model.dart';

class ClientFormController extends FormControllerWithImage with ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final totalSpentController = TextEditingController();

  ClientModel compile() {
    String? image = imageIsFile
        ? imagePathController.text.trim()
        : imageController.text.trim();
    if (image.isEmpty) image = null;
    final name = nameController.text.trim();
    final totalSpent = totalSpentController.text.trim().isEmpty
        ? 0.0
        : double.parse(
            totalSpentController.text.trim().onlyNumbers,
          );
    return ClientModel(
      id: '',
      name: name,
      totalSpent: totalSpent,
      imageIsFile: imageIsFile,
      image: image,
      dateCreated: DateTime.now(),
    );
  }

  @override
  void dispose() {
    imageController.dispose();
    imagePathController.dispose();
    nameController.dispose();
    totalSpentController.dispose();
    super.dispose();
  }
}
