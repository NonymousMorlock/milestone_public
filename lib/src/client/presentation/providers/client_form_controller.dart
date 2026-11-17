import 'package:flutter/material.dart';
import 'package:milestone/core/common/providers/form_controller_with_image.dart';
import 'package:milestone/core/extensions/string_extensions.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/client/domain/entities/client.dart';

class ClientFormController extends FormControllerWithImage with ChangeNotifier {
  ClientFormController() {
    for (final controller in [
      nameController,
      totalSpentController,
      imageController,
      imagePathController,
    ]) {
      controller.addListener(notifyListeners);
    }
  }

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final totalSpentController = TextEditingController();
  Client? originalClient;

  @override
  void changeImageMode({required bool imageIsFile}) {
    final changed = this.imageIsFile != imageIsFile;
    super.changeImageMode(imageIsFile: imageIsFile);
    if (changed) {
      notifyListeners();
    }
  }

  ClientModel compileCreate({required String clientId}) {
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
      id: clientId,
      name: name,
      totalSpent: totalSpent,
      imageIsFile: imageIsFile,
      image: image,
      dateCreated: DateTime.now(),
    );
  }

  void init(Client client) {
    originalClient = client;
    nameController.text = client.name;
    totalSpentController.text = client.totalSpent == 0
        ? ''
        : client.totalSpent.toString();
    imageController.clear();
    imagePathController.clear();
    changeImageMode(imageIsFile: false);
    if (client.image != null && client.image!.isNotEmpty) {
      imageController.text = client.image!;
    }
    notifyListeners();
  }

  Map<String, dynamic> compileUpdateData() {
    final originalClient = this.originalClient;
    if (originalClient == null) {
      return <String, dynamic>{};
    }

    final updateData = <String, dynamic>{};
    final nextName = nameController.text.trim();
    if (nextName != originalClient.name) {
      updateData['name'] = nextName;
    }

    final originalImage = originalClient.image ?? '';
    final nextImage = imageIsFile
        ? imagePathController.text.trim()
        : imageController.text.trim();
    if (imageIsFile) {
      if (nextImage.isNotEmpty) {
        updateData['image'] = nextImage;
        updateData['imageIsFile'] = true;
      }
      return updateData;
    }

    if (nextImage != originalImage) {
      updateData['image'] = nextImage.isEmpty ? null : nextImage;
      updateData['imageIsFile'] = false;
    }

    return updateData;
  }

  bool get updateRequired => compileUpdateData().isNotEmpty;

  @override
  void dispose() {
    imageController.dispose();
    imagePathController.dispose();
    nameController.dispose();
    totalSpentController.dispose();
    super.dispose();
  }
}
