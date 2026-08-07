import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/common/widgets/date_field.dart';
import 'package:milestone/core/common/widgets/form_checkbox.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/common/widgets/rounded_button.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/client_picker.dart';
import 'package:milestone/src/project/presentation/widgets/image_field.dart';
import 'package:milestone/src/project/presentation/widgets/project_form_gallery.dart';
import 'package:milestone/src/project/presentation/widgets/project_form_links.dart';
import 'package:milestone/src/project/presentation/widgets/project_form_notes.dart';
import 'package:milestone/src/project/presentation/widgets/responsive_fields.dart';
import 'package:milestone/src/project/presentation/widgets/tools_selector.dart';
import 'package:provider/provider.dart';

class AddOrEditProjectForm extends StatelessWidget {
  const AddOrEditProjectForm({required this.isEdit, super.key});

  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final titleText = isEdit ? 'Update Project' : 'Add Project';
    return Consumer<ProjectFormController>(
      builder: (_, controller, _) {
        final canSubmitEdit = !isEdit || controller.updateRequired;
        return Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionCard(
                title: 'Project basics',
                child: ResponsiveFields(
                  children: [
                    GenericField(
                      controller: controller.nameController,
                      label: 'Project name',
                      required: true,
                      maxLength: 30,
                    ),
                    ImageField(controller: controller, label: 'Project Image'),
                  ],
                ),
              ),
              const Gap(16),
              AppSectionCard(
                title: 'Client and commercial terms',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ClientPicker(),
                    const Gap(16),
                    ResponsiveFields(
                      children: [
                        ListenableBuilder(
                          listenable: controller.budgetController,
                          builder: (_, _) {
                            return GenericField(
                              controller: controller.budgetController,
                              keyboardType: TextInputType.number,
                              label: 'Budget',
                              suffixIcon:
                                  controller.budgetController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed:
                                          controller.budgetController.clear,
                                    )
                                  : null,
                              inputFormatters: [CurrencyInputFormatter()],
                            );
                          },
                        ),
                        if (isEdit)
                          GenericField(
                            controller: controller.totalPaidController,
                            keyboardType: TextInputType.number,
                            label: 'Total Paid',
                            helperText:
                                'Updated by milestone activity, '
                                'not by project edit.',
                            readOnly: true,
                          )
                        else
                          ListenableBuilder(
                            listenable: controller.totalPaidController,
                            builder: (_, _) {
                              return GenericField(
                                controller: controller.totalPaidController,
                                keyboardType: TextInputType.number,
                                label: 'Total Paid',
                                suffixIcon:
                                    controller
                                        .totalPaidController
                                        .text
                                        .isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: controller
                                            .totalPaidController
                                            .clear,
                                      )
                                    : null,
                                inputFormatters: [
                                  CurrencyInputFormatter(),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                    const Gap(16),
                    ResponsiveFields(
                      children: [
                        GenericField(
                          controller: controller.projectTypeController,
                          label: 'Project Type',
                          suffixIcon: PopupMenuButton(
                            icon: const Icon(Icons.arrow_drop_down_rounded),
                            onSelected: (value) {
                              controller.projectTypeController.text = value;
                            },
                            itemBuilder: (context) {
                              return const [
                                PopupMenuItem<String>(
                                  value: 'Full-Stack',
                                  child: Text('Full-Stack'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Backend',
                                  child: Text('Backend'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Frontend',
                                  child: Text('Frontend'),
                                ),
                              ];
                            },
                          ),
                        ),
                        FormCheckbox(
                          value: controller.isOneTime,
                          onChanged: (newValue) {
                            if (newValue case bool()) {
                              controller.changeContinuity(isOneTime: newValue);
                            }
                          },
                          label: 'One-time project',
                          infoMessage:
                              'One-time project means the project is a '
                              'one-time project and will not require '
                              'continuous development',
                        ),
                      ],
                    ),
                    ListenableBuilder(
                      listenable: controller.budgetController,
                      builder: (_, _) {
                        if (controller.budgetController.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: FormCheckbox(
                            value: controller.budgetIsFixed,
                            onChanged: (newValue) {
                              if (newValue case bool()) {
                                controller.changeBudgetFlexibility(
                                  isFixed: newValue,
                                );
                              }
                            },
                            label: 'Fixed Budget',
                            infoMessage:
                                'Fixed budget means the project budget '
                                'is fixed and cannot be changed',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Gap(16),
              AppSectionCard(
                title: 'Schedule',
                child: ResponsiveFields(
                  expandedColumns: 3,
                  children: [
                    DateField(
                      dateController: controller.startDateController,
                      dateNotifier: controller.startDateNotifier,
                      dateFormat: DateFormat.yMMMd(),
                      label: 'Start Date',
                      allowClear: !isEdit,
                    ),
                    DateField(
                      dateController: controller.endDateController,
                      dateNotifier: controller.endDateNotifier,
                      dateFormat: DateFormat.yMMMd(),
                      label: 'End Date',
                    ),
                    DateField(
                      dateController: controller.deadlineController,
                      dateNotifier: controller.deadlineNotifier,
                      dateFormat: DateFormat.yMMMd(),
                      label: 'Deadline',
                    ),
                  ],
                ),
              ),
              const Gap(16),
              AppSectionCard(
                title: 'Descriptions, notes, and links',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GenericField(
                      controller: controller.shortDescriptionController,
                      keyboardType: TextInputType.multiline,
                      label: 'Short description',
                      maxLines: 5,
                      minLines: 1,
                      maxLength: 255,
                    ),
                    const Gap(16),
                    GenericField(
                      controller: controller.longDescriptionController,
                      keyboardType: .multiline,
                      label: 'Long description',
                      maxLines: 5,
                      minLines: 1,
                    ),
                    const Gap(16),
                    const ProjectFormNotes(),
                    const Gap(16),
                    const ProjectFormLinks(),
                  ],
                ),
              ),
              const Gap(16),
              const AppSectionCard(
                title: 'Tools and gallery',
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    ToolsSelector(),
                    Gap(16),
                    ProjectFormGallery(),
                  ],
                ),
              ),
              const Gap(24),
              Align(
                alignment: Alignment.centerRight,
                child: RoundedButton(
                  text: titleText,
                  onPressed: canSubmitEdit
                      ? () {
                          if (controller.selectedClient == null) {
                            CoreUtils.showSnackBar(
                              message: 'Please select a client',
                              logLevel: LogLevel.error,
                              enhanceBlur: true,
                              enhanceMessage: true,
                            );
                            return;
                          }
                          if (!controller.formKey.currentState!.validate()) {
                            return;
                          }

                          if (!isEdit) {
                            context.read<ProjectBloc>().add(
                              AddProjectEvent(controller.compile()),
                            );
                            return;
                          }

                          final updateData = controller.compileUpdateData();
                          if (updateData.isEmpty) {
                            return;
                          }

                          context.read<ProjectBloc>().add(
                            EditProjectDetailsEvent(
                              projectId: controller.originalProject!.id,
                              updateData: updateData,
                            ),
                          );
                        }
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
