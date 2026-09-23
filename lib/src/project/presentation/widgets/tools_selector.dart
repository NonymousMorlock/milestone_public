import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/helpers/cache_helper.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/custom_chip.dart';
import 'package:provider/provider.dart';

class ToolsSelector extends StatelessWidget {
  const ToolsSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProjectBloc>(),
      child: const ToolsSelectorMain(),
    );
  }
}

class ToolsSelectorMain extends StatefulWidget {
  const ToolsSelectorMain({super.key});

  @override
  State<ToolsSelectorMain> createState() => _ToolsSelectorState();
}

class _ToolsSelectorState extends State<ToolsSelectorMain> {
  final menuController = TextEditingController();
  final loadingNotifier = ValueNotifier<bool>(false);

  Future<void> fetchTools() async {
    loadingNotifier.value = true;
    final formController = context.read<ProjectFormController>();
    try {
      final cachedTools = await CacheHelper.instance.fetchTools();
      if (cachedTools.isNotEmpty) {
        formController.setTools(cachedTools);
      }
      if (!mounted) return;
      context.read<ProjectBloc>().add(const GetUserToolsEvent());
    } finally {
      if (mounted) loadingNotifier.value = false;
    }
  }

  Future<void> onDeleteTool({
    required BuildContext context,
    required String tool,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog.adaptive(
          title: Text(
            'Confirm Tool Deletion',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: .w600),
          ),
          content: Text(
            'Are you sure you want to delete "$tool"? This will remove it '
            'from all your tools list.'
            '\n\n'
            'This means that for new projects, you cannot find this tool in '
            'your tools list to select it.\n'
            'However, it will not remove the tool from existing projects '
            'that have it selected.'
            '\n\n'
            'NB: You can re-add the tool later if you change your mind.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: context.colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if ((confirmed ?? false) && context.mounted) {
      unawaited(context.read<ProjectFormController>().removeTool(tool));
      if (context.mounted) {
        context.read<ProjectBloc>().add(
          RemoveUserToolEvent(tool),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(fetchTools());
    });
  }

  @override
  void dispose() {
    menuController.dispose();
    loadingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        loadingNotifier.value = false;
        if (state is ProjectLoading) {
          loadingNotifier.value = true;
        } else if (state case UserToolsLoaded(:final tools)) {
          unawaited(context.read<ProjectFormController>().addTools(tools));
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: loadingNotifier,
        builder: (_, loading, _) {
          if (loading) return const LinearProgressIndicator();
          return Consumer<ProjectFormController>(
            builder: (_, controller, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 600;
                  final dropdownWidth = compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 116) < 220
                      ? 220.0
                      : constraints.maxWidth - 116;

                  final pickerHelperText = Text(
                    'Tool not already in list? Use the Add tool button.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  );

                  final picker = SizedBox(
                    width: dropdownWidth,
                    child: DropdownMenu<String>(
                      controller: menuController,
                      width: dropdownWidth,
                      hintText: 'Tools for this project',
                      requestFocusOnTap: true,
                      onSelected: (tool) {
                        if (tool case String()) {
                          controller.selectTool(tool);
                        }
                        menuController.clear();
                      },
                      dropdownMenuEntries: controller.tools.map(
                        (tool) {
                          return DropdownMenuEntry<String>(
                            trailingIcon: IconButton(
                              icon: Icon(
                                Icons.delete_forever,
                                color: context.colorScheme.error,
                              ),
                              onPressed: () async {
                                await onDeleteTool(
                                  context: context,
                                  tool: tool,
                                );
                              },
                            ),
                            value: tool,
                            label: tool,
                          );
                        },
                      ).toList(),
                      enableSearch: false,
                      enableFilter: true,
                    ),
                  );

                  final addAction = CustomChip(
                    label: 'Add Tool',
                    onTap: () {
                      if (menuController.text.trim().isEmpty) return;
                      unawaited(
                        controller.addTool(
                          menuController.text.trim(),
                        ),
                      );
                      menuController.clear();
                    },
                  );

                  return Column(
                    crossAxisAlignment: .start,
                    children: [
                      if (compact)
                        Column(
                          crossAxisAlignment: .start,
                          spacing: 12,
                          children: [
                            Column(
                              crossAxisAlignment: .start,
                              mainAxisSize: .min,
                              spacing: 6,
                              children: [picker, pickerHelperText],
                            ),
                            addAction,
                          ],
                        )
                      else
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(child: picker),
                            addAction,
                          ],
                        ),
                      const Gap(8),
                      if (!compact) pickerHelperText,
                      const Gap(16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: controller.selectedTools
                            .map(
                              (tool) => FilterChip(
                                label: Text(tool),
                                deleteIcon: const Icon(Icons.clear),
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
              );
            },
          );
        },
      ),
    );
  }
}
