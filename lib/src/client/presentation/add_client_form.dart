import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/common/widgets/rounded_button.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/image_field.dart';
import 'package:provider/provider.dart';

class AddClientForm extends StatelessWidget {
  const AddClientForm({
    required this.onSubmit,
    this.isSubmitting = false,
    this.submitLabel = 'Add Client',
    this.allowTotalSpentEdit = true,
    super.key,
  });

  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String submitLabel;
  final bool allowTotalSpentEdit;

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientFormController>(
      builder: (_, controller, _) {
        return Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              AppSectionCard(
                title: 'Client basics',
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    GenericField(
                      controller: controller.nameController,
                      label: 'Client name',
                      required: true,
                      maxLength: 30,
                    ),
                    const Gap(16),
                    ImageField(controller: controller, label: 'Client Image'),
                  ],
                ),
              ),
              const Gap(16),
              AppSectionCard(
                title: 'Financial context',
                subtitle: allowTotalSpentEdit
                    ? 'Optional starting total until project history builds '
                          'up.'
                    : 'Client spend is derived from project history and '
                          'seeded setup.',
                child: allowTotalSpentEdit
                    ? ListenableBuilder(
                        listenable: controller.totalSpentController,
                        builder: (_, _) {
                          return GenericField(
                            controller: controller.totalSpentController,
                            keyboardType: TextInputType.number,
                            label: 'Total Spent',
                            suffixIcon:
                                controller.totalSpentController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed:
                                        controller.totalSpentController.clear,
                                  )
                                : null,
                            inputFormatters: [CurrencyInputFormatter()],
                          );
                        },
                      )
                    : const Text(
                        'This value is create-only in this phase. Use project '
                        'and milestone payments to move the relationship '
                        'total forward.',
                      ),
              ),
              const Gap(24),
              Align(
                alignment: Alignment.centerRight,
                child: RoundedButton(
                  text: submitLabel,
                  onPressed: isSubmitting ? null : onSubmit,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
