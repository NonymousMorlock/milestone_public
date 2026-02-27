import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/res/styles/colours.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/presentation/views/add_client_view.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/custom_chip.dart';
import 'package:provider/provider.dart';

class ClientPicker extends StatefulWidget {
  const ClientPicker({super.key});

  @override
  State<ClientPicker> createState() => _ClientPickerState();
}

class _ClientPickerState extends State<ClientPicker> {
  final menuController = TextEditingController();

  @override
  void dispose() {
    menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(10),
    );
    return Consumer<ProjectFormController>(
      builder: (_, controller, __) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownMenu<Client>(
                  controller: menuController,
                  hintText: 'Client',
                  requestFocusOnTap: true,
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colours.lightThemePrimaryColour.withValues(
                      alpha: .2,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorBorder: border,
                    focusedErrorBorder: border,
                    enabledBorder: border,
                    focusedBorder: border,
                    contentPadding: const EdgeInsets.only(
                      top: 10,
                      left: 10,
                    ),
                    prefixStyle:
                        const TextStyle(fontSize: 16, color: Colors.black),
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  menuStyle: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      Colours.lightThemePrimaryColour,
                    ),
                    surfaceTintColor: WidgetStatePropertyAll(
                      Colours.lightThemeSecondaryTextColour,
                    ),
                  ),
                  onSelected: controller.selectClient,
                  dropdownMenuEntries: controller.clients.map(
                    (client) {
                      return DropdownMenuEntry<Client>(
                        style: ButtonStyle(
                          foregroundColor:
                              WidgetStatePropertyAll(Colors.grey[350]),
                        ),
                        value: client,
                        label: client.name,
                      );
                    },
                  ).toList(),
                  enableSearch: false,
                  enableFilter: true,
                ),
                const Gap(10),
                CustomChip(
                  label: 'Add Client',
                  onTap: () async {
                    final result = await context.navigateTo<Client>(
                      AddClientView.path,
                    );
                    if (result case Client()) {
                      controller.selectClient(result);
                      menuController.text = result.name;
                    }
                  },
                ),
              ],
            ),
            const Gap(5),
            Text(
              "Can't find the client?. Add Client",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.withValues(alpha: .4),
              ),
            ),
          ],
        );
      },
    );
  }
}
