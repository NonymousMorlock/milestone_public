import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/extensions/iterable_extensions.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/custom_chip.dart';
import 'package:provider/provider.dart';

class ProjectFormLinks extends StatelessWidget {
  const ProjectFormLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectFormController>(
      builder: (_, controller, __) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...controller.linkControllers
                .mapIndexed((
                  index,
                  controllers,
                ) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Link ${index + 1}',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              controller.removeLink(index);
                            },
                            icon: const Icon(Icons.delete_forever),
                          ),
                        ],
                      ),
                      const Gap(10),
                      GenericField(
                        keyboardType: TextInputType.text,
                        controller: controllers.titleController,
                        helperText: 'If left blank, the url will be used as '
                            'the title instead.',
                        label: 'Title',
                        maxLines: 2,
                        minLines: 1,
                      ),
                      const Gap(5),
                      GenericField(
                        keyboardType: TextInputType.url,
                        controller: controllers.urlController,
                        required: true,
                        label: 'URL',
                        maxLines: 2,
                        minLines: 1,
                      ),
                      if (index != controller.linkControllers.length - 1)
                        const Gap(20),
                    ],
                  );
                })
                .toList()
                .gap(20),
            const Gap(5),
            CustomChip(label: 'Add Link', onTap: controller.addLink),
          ],
        );
      },
    );
  }
}
