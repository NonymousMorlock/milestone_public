import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/extensions/iterable_extensions.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/custom_chip.dart';
import 'package:provider/provider.dart';

class ProjectFormNotes extends StatelessWidget {
  const ProjectFormNotes({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectFormController>(
      builder: (_, controller, __) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...controller.noteControllers
                .mapIndexed((
                  index,
                  textEditingController,
                ) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: GenericField(
                          controller: textEditingController,
                          label: 'Note ${index + 1}',
                          maxLines: 2,
                          minLines: 1,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          controller.removeNote(index);
                        },
                        icon: const Icon(Icons.delete_forever),
                      ),
                    ],
                  );
                })
                .toList()
                .gap(20),
            const Gap(5),
            CustomChip(label: 'Add Note', onTap: controller.addNote),
          ],
        );
      },
    );
  }
}
