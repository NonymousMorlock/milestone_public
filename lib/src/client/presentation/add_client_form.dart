import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/common/widgets/rounded_button.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/image_field.dart';
import 'package:provider/provider.dart';

class AddClientForm extends StatelessWidget {
  const AddClientForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientFormController>(
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
                      label: 'Client name',
                      required: true,
                      maxLength: 30,
                    ),
                    const Gap(20),
                    ImageField(controller: controller, label: 'Client Image'),
                    const Gap(20),
                    ListenableBuilder(
                      listenable: controller.totalSpentController,
                      builder: (_, __) {
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
                    ),
                  ],
                ),
              ),
              const Gap(20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(
                  bottom: 20,
                ),
                child: RoundedButton(
                  text: 'Add Client',
                  onPressed: () {
                    if (controller.formKey.currentState!.validate()) {
                      context.read<ClientCubit>().addClient(
                            controller.compile(),
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
