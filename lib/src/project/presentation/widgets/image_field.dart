import 'dart:io';

import 'package:flutter/material.dart';
import 'package:milestone/core/common/providers/form_controller_with_image.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/utils/core_utils.dart';

class ImageField extends StatelessWidget {
  const ImageField({required this.controller, required this.label, super.key});

  final FormControllerWithImage controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.imageController,
      builder: (_, __) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GenericField(
              controller: controller.imageController,
              keyboardType: TextInputType.url,
              readOnly: controller.imageIsFile,
              helperText: 'Pick an image from gallery or add image link',
              label: label,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_rounded),
                    onPressed: () async {
                      final image = await CoreUtils.pickImage(context);
                      if (image != null) {
                        controller.imagePathController.text = image.path;
                        controller.imageController.text =
                            image.path.split('/').last;
                        controller.changeImageMode(imageIsFile: true);
                      }
                    },
                  ),
                  if (controller.imageController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.imageController.clear();
                        controller.changeImageMode(imageIsFile: false);
                      },
                    ),
                ],
              ),
            ),
            if (controller.imageController.text.isNotEmpty)
              Container(
                width: double.maxFinite,
                margin: const EdgeInsets.only(top: 10),
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: switch (controller.imageIsFile) {
                      true => FileImage(
                          File(controller.imagePathController.text.trim()),
                        ),
                      _ => NetworkImage(controller.imageController.text.trim())
                          as ImageProvider,
                    },
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
