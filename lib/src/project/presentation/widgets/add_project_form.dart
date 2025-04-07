import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:milestone/core/common/widgets/date_field.dart';
import 'package:milestone/core/common/widgets/form_checkbox.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/common/widgets/rounded_button.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/res/styles/colours.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/client_picker.dart';
import 'package:milestone/src/project/presentation/widgets/image_field.dart';
import 'package:milestone/src/project/presentation/widgets/project_form_gallery.dart';
import 'package:milestone/src/project/presentation/widgets/project_form_links.dart';
import 'package:milestone/src/project/presentation/widgets/project_form_notes.dart';
import 'package:milestone/src/project/presentation/widgets/tools_selector.dart';
import 'package:provider/provider.dart';

class AddOrEditProjectForm extends StatelessWidget {
  const AddOrEditProjectForm({required this.isEdit, super.key});

  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final titleText = isEdit ? 'Update Project' : 'Add Project';
    return Consumer<ProjectFormController>(
      builder: (_, controller, __) {
        return Form(
          key: controller.formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GenericField(
                      controller: controller.nameController,
                      label: 'Project name',
                      required: true,
                      maxLength: 30,
                    ),
                    const Gap(20),
                    ImageField(controller: controller, label: 'Project Image'),
                    const Gap(20),
                    const ClientPicker(),
                    const Gap(20),
                    ListenableBuilder(
                      listenable: controller.budgetController,
                      builder: (_, __) {
                        return GenericField(
                          controller: controller.budgetController,
                          keyboardType: TextInputType.number,
                          label: 'Budget',
                          suffixIcon: controller
                                  .budgetController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: controller.budgetController.clear,
                                )
                              : null,
                          inputFormatters: [CurrencyInputFormatter()],
                        );
                      },
                    ),
                    const Gap(20),
                    ListenableBuilder(
                      listenable: controller.budgetController,
                      builder: (_, __) {
                        final value = controller.budgetController.text;
                        if (value case String(isNotEmpty: true)) {
                          return FormCheckbox(
                            value: controller.budgetIsFixed,
                            onChanged: (newValue) {
                              if (newValue case bool()) {
                                controller.changeBudgetFlexibility(
                                  isFixed: newValue,
                                );
                              }
                            },
                            label: 'Fixed Budget',
                            infoMessage: 'Fixed budget means the project '
                                'budget is fixed and cannot be changed',
                          );
                        }
                        return const SizedBox.shrink();
                      },
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
                          'One-time project means the project is a one-time '
                          'project and will not require continuous development',
                    ),
                    const Gap(20),
                    GenericField(
                      controller: controller.shortDescriptionController,
                      keyboardType: TextInputType.multiline,
                      label: 'Short description',
                      maxLines: 5,
                      minLines: 1,
                      maxLength: 255,
                    ),
                    const Gap(20),
                    GenericField(
                      controller: controller.longDescriptionController,
                      keyboardType: TextInputType.multiline,
                      label: 'Long description',
                      maxLines: 5,
                      minLines: 1,
                    ),
                    const Gap(20),
                    const ProjectFormNotes(),
                    const Gap(20),
                    const ProjectFormLinks(),
                    const Gap(20),
                    GenericField(
                      controller: controller.projectTypeController,
                      label: 'Project Type',
                      suffixIcon: PopupMenuButton(
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        onSelected: (value) {
                          controller.projectTypeController.text = value;
                        },
                        color: Colours.lightThemePrimaryColour,
                        surfaceTintColor: Colours.lightThemeSecondaryTextColour,
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'Full-Stack',
                              child: Text(
                                'Full-Stack',
                                style: TextStyle(
                                  color: Colors.grey[350],
                                ),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'Backend',
                              child: Text(
                                'Backend',
                                style: TextStyle(
                                  color: Colors.grey[350],
                                ),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'Frontend',
                              child: Text(
                                'Frontend',
                                style: TextStyle(
                                  color: Colors.grey[350],
                                ),
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                    const Gap(20),
                    ListenableBuilder(
                      listenable: controller.totalPaidController,
                      builder: (_, __) {
                        return GenericField(
                          controller: controller.totalPaidController,
                          keyboardType: TextInputType.number,
                          label: 'Total Paid',
                          suffixIcon:
                              controller.totalPaidController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed:
                                          controller.totalPaidController.clear,
                                    )
                                  : null,
                          inputFormatters: [CurrencyInputFormatter()],
                        );
                      },
                    ),
                    const Gap(20),
                    DateField(
                      dateController: controller.startDateController,
                      dateNotifier: controller.startDateNotifier,
                      dateFormat: DateFormat.yMMMd(),
                      label: 'Start Date',
                    ),
                    const Gap(20),
                    DateField(
                      dateController: controller.endDateController,
                      dateNotifier: controller.endDateNotifier,
                      dateFormat: DateFormat.yMMMd(),
                      label: 'End Date',
                    ),
                    const Gap(20),
                    DateField(
                      dateController: controller.deadlineController,
                      dateNotifier: controller.deadlineNotifier,
                      dateFormat: DateFormat.yMMMd(),
                      label: 'Deadline',
                    ),
                    const Gap(20),
                    const ToolsSelector(),
                    const Gap(20),
                    Text(
                      'Project Gallery',
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const Gap(10),
                    const ProjectFormGallery(),
                  ],
                ),
              ),
              const Gap(20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(
                  bottom: 20,
                ),
                child: RoundedButton(
                  text: titleText,
                  onPressed: () {
                    if (controller.selectedClient == null) {
                      CoreUtils.showSnackBar(
                        message: 'Please select a client',
                        logLevel: LogLevel.error,
                        enhanceBlur: true,
                        enhanceMessage: true,
                      );
                      return;
                    }
                    if (controller.formKey.currentState!.validate()) {
                      context.read<ProjectBloc>().add(
                            $AddProject(controller.compile()),
                          );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
