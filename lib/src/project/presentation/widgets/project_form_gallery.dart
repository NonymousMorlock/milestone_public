import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/extensions/iterable_extensions.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/custom_chip.dart';
import 'package:milestone/src/project/presentation/widgets/gallery_field.dart';
import 'package:provider/provider.dart';

class ProjectFormGallery extends StatelessWidget {
  const ProjectFormGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectFormController>(
      builder: (_, controller, __) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...controller.galleryControllers
                .mapIndexed((
                  index,
                  textEditingController,
                ) {
                  return GalleryField(
                    controls: controller.galleryControllers[index],
                    index: index,
                  );
                })
                .toList()
                .gap(20),
            const Gap(5),
            CustomChip(
              label: 'Add Image',
              onTap: () {
                if (controller.galleryControllers.length < 5) {
                  controller.addToGallery();
                } else {
                  CoreUtils.showSnackBar(
                    message: 'You can only add up to 5 images',
                    logLevel: LogLevel.warning,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
