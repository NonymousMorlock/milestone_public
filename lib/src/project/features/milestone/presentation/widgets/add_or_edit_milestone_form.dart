import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/common/widgets/date_field.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/common/widgets/rounded_button.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:milestone/src/project/features/milestone/presentation/providers/milestone_form_controller.dart';
import 'package:milestone/src/project/features/milestone/presentation/widgets/milestone_form_notes.dart';
import 'package:milestone/src/project/presentation/widgets/responsive_fields.dart';
import 'package:provider/provider.dart';

class AddOrEditMilestoneForm extends StatelessWidget {
  const AddOrEditMilestoneForm({
    required this.projectId,
    required this.isEdit,
    super.key,
    this.milestoneId,
  });

  final String projectId;
  final String? milestoneId;
  final bool isEdit;

  void _submit(
    BuildContext context,
    MilestoneFormController controller, {
    required bool isSubmitting,
  }) {
    if (isSubmitting) {
      return;
    }

    final formState = controller.formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final chronologyError = controller.chronologyValidationMessage();
    if (chronologyError != null) {
      CoreUtils.showSnackBar(
        logLevel: LogLevel.error,
        title: 'Invalid milestone dates',
        message: chronologyError,
      );
      return;
    }

    if (isEdit) {
      final updateData = controller.compileUpdateData();
      if (updateData.isEmpty) {
        return;
      }

      unawaited(
        context.read<MilestoneCubit>().editMilestone(
          projectId: projectId,
          milestoneId: milestoneId!,
          updatedMilestone: updateData,
        ),
      );
      return;
    }

    unawaited(
      context.read<MilestoneCubit>().addMilestone(
        controller.compileForCreate(projectId: projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<MilestoneCubit, bool>(
      (cubit) => cubit.state.isMutating,
    );
    return Consumer<MilestoneFormController>(
      builder: (context, controller, child) {
        final canSubmit =
            !isSubmitting && (!isEdit || controller.updateRequired);
        return Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionCard(
                title: 'Milestone details',
                child: ResponsiveFields(
                  children: [
                    GenericField(
                      controller: controller.titleController,
                      label: 'Title',
                      required: true,
                      maxLength: 60,
                    ),
                    GenericField(
                      controller: controller.shortDescriptionController,
                      label: 'Short description',
                      maxLength: 255,
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ],
                ),
              ),
              const Gap(16),
              AppSectionCard(
                title: 'Payment and schedule',
                child: ResponsiveFields(
                  expandedColumns: 3,
                  children: [
                    ListenableBuilder(
                      listenable: controller.amountPaidController,
                      builder: (_, _) {
                        return GenericField(
                          controller: controller.amountPaidController,
                          keyboardType: TextInputType.number,
                          label: 'Amount paid',
                          helperText:
                              'Leave blank if no payment has been'
                              ' recorded yet.',
                          inputFormatters: [CurrencyInputFormatter()],
                          validator: controller.amountPaidValidationMessage,
                          suffixIcon:
                              controller.amountPaidController.text.isNotEmpty
                              ? IconButton(
                                  onPressed:
                                      controller.amountPaidController.clear,
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                        );
                      },
                    ),
                    DateField(
                      dateController: controller.startDateController,
                      dateNotifier: controller.startDateNotifier,
                      dateFormat: DateFormat.yMMMd(),
                      label: 'Start date',
                    ),
                    DateField(
                      dateController: controller.endDateController,
                      dateNotifier: controller.endDateNotifier,
                      dateFormat: DateFormat.yMMMd(),
                      label: 'End date',
                    ),
                  ],
                ),
              ),
              const Gap(16),
              const AppSectionCard(
                title: 'Notes',
                child: MilestoneFormNotes(),
              ),
              const Gap(24),
              Align(
                alignment: Alignment.centerRight,
                child: RoundedButton(
                  text: isEdit ? 'Update Milestone' : 'Add Milestone',
                  onPressed: canSubmit
                      ? () => _submit(
                          context,
                          controller,
                          isSubmitting: isSubmitting,
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
