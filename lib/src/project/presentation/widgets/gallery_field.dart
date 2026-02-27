import 'dart:io';

import 'package:flutter/material.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/utils/control.dart';
import 'package:provider/provider.dart';

class GalleryField extends StatelessWidget {
  const GalleryField({required this.controls, required this.index, super.key});

  final Control controls;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectFormController>(
      builder: (_, controller, __) {
        return ListenableBuilder(
          listenable: controls.imageController,
          builder: (_, __) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GenericField(
                        controller: controls.imageController,
                        readOnly: controls.imageIsFile,
                        helperText: 'Pick an image from gallery or add '
                            'image link',
                        label: 'Project Image',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_a_photo_rounded),
                              onPressed: () async {
                                final image =
                                    await CoreUtils.pickImage(context);
                                if (image != null) {
                                  controls.imagePathController.text =
                                      image.path;
                                  controls.imageController.text =
                                      image.path.split('/').last;
                                  controller.changeGalleryImageMode(
                                    index: index,
                                    imageIsFile: true,
                                  );
                                }
                              },
                            ),
                            if (controls.imageController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  controls.imageController.clear();
                                  controller.changeGalleryImageMode(
                                    index: index,
                                    imageIsFile: false,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        controller.removeImageFromGallery(index);
                      },
                      icon: const Icon(Icons.delete_forever),
                    ),
                  ],
                ),
                if (controls.imageController.text.isNotEmpty)
                  Container(
                    width: double.maxFinite,
                    margin: const EdgeInsets.only(top: 10),
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: switch (controls.imageIsFile) {
                          true => FileImage(
                              File(controls.imagePathController.text.trim()),
                            ),
                          _ =>
                            NetworkImage(controls.imageController.text.trim())
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
      },
    );
  }
}
