import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/string_extensions.dart';
import 'package:milestone/core/helpers/cache_helper.dart';
import 'package:milestone/core/res/styles/colours.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/custom_chip.dart';
import 'package:provider/provider.dart';

class ToolsSelector extends StatefulWidget {
  const ToolsSelector({super.key});

  @override
  State<ToolsSelector> createState() => _ToolsSelectorState();
}

class _ToolsSelectorState extends State<ToolsSelector> {
  final menuController = TextEditingController();
  final loadingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formController = context.read<ProjectFormController>();
      loadingNotifier.value = true;
      unawaited(
        CacheHelper.instance.fetchTools().then(
          (value) {
            formController.setTools(value);
            loadingNotifier.value = false;
          },
        ),
      );
    });
  }

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
    return ValueListenableBuilder(
      valueListenable: loadingNotifier,
      builder: (_, loading, __) {
        return StateRenderer(
          loading: loading,
          child: Consumer<ProjectFormController>(
            builder: (_, controller, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownMenu<String>(
                        controller: menuController,
                        hintText: 'Tools for this project',
                        width: context.width * .4,
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
                          prefixStyle: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
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
                        onSelected: (tool) {
                          if (tool case String()) {
                            controller.selectTool(tool);
                          }
                          menuController.clear();
                        },
                        dropdownMenuEntries: controller.tools.map(
                          (tool) {
                            return DropdownMenuEntry<String>(
                              style: ButtonStyle(
                                foregroundColor: WidgetStatePropertyAll(
                                  Colors.grey[350],
                                ),
                              ),
                              trailingIcon: IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  controller.removeTool(tool);
                                },
                              ),
                              value: tool,
                              label: tool.titleCase,
                            );
                          },
                        ).toList(),
                        enableSearch: false,
                        enableFilter: true,
                      ),
                      const Gap(10),
                      CustomChip(
                        label: 'Add Tool',
                        onTap: () {
                          controller.addTool(
                            menuController.text.trim().titleCase,
                          );
                          menuController.clear();
                        },
                      ),
                    ],
                  ),
                  const Gap(5),
                  Text(
                    'Tool not already in list? Use the Add tool button',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.withValues(alpha: .4),
                    ),
                  ),
                  const Gap(20),
                  Wrap(
                    spacing: 10,
                    children: controller.selectedTools
                        .map(
                          (tool) => FilterChip(
                            backgroundColor:
                                Colours.lightThemePrimaryTextColour,
                            iconTheme: const IconThemeData(color: Colors.green),
                            labelStyle: const TextStyle(color: Colors.white),
                            label: Text(tool),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(90),
                            ),
                            deleteIcon: const Icon(Icons.clear),
                            deleteIconColor: Colors.red,
                            onDeleted: () {
                              controller.deselectTool(tool);
                            },
                            onSelected: (_) {},
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
