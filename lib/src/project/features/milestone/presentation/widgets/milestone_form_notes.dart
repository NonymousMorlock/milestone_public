import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/extensions/iterable_extensions.dart';
import 'package:milestone/src/project/features/milestone/presentation/providers/milestone_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/custom_chip.dart';
import 'package:provider/provider.dart';

class MilestoneFormNotes extends StatelessWidget {
  const MilestoneFormNotes({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MilestoneFormController>(
      builder: (_, controller, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...controller.noteControllers
                .mapIndexed((index, noteController) {
                  return Row(
                    children: [
                      Expanded(
                        child: GenericField(
                          controller: noteController,
                          label: 'Note ${index + 1}',
                          maxLines: 2,
                          minLines: 1,
                        ),
                      ),
                      const Gap(8),
                      IconButton(
                        onPressed: () => controller.removeNote(index),
                        icon: const Icon(Icons.delete_forever_rounded),
                      ),
                    ],
                  );
                })
                .toList()
                .gap(16),
            const Gap(8),
            CustomChip(
              label: 'Add Note',
              onTap: controller.addNote,
            ),
          ],
        );
      },
    );
  }
}
