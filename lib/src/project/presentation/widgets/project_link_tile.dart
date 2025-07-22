import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/res/styles/colours.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectLinkTile extends StatelessWidget {
  const ProjectLinkTile({
    required this.index,
    required this.controller,
    super.key,
  });

  final LinkControllers controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(
          ClipboardData(text: controller.urlController.text),
        );
        if (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux) {
          unawaited(
            CoreUtils.showSnackBar(message: 'Copied to clipboard'),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colours.lightThemePrimaryColour.withValues(alpha: .2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(8),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListenableBuilder(
                  listenable: controller.titleController,
                  builder: (context, _) {
                    return Text(
                      controller.titleController.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
            ListTile(
              leading: GestureDetector(
                onTap: () async {
                  if (!await launchUrl(
                    Uri.parse(controller.urlController.text),
                  )) {
                    throw Exception(
                      'Could not launch ${controller.titleController.text}',
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(90),
                  ),
                  child: const Text('View', style: TextStyle(fontSize: 11)),
                ),
              ),
              title: Center(
                child: ListenableBuilder(
                  listenable: controller.urlController,
                  builder: (context, _) {
                    return Text(
                      controller.urlController.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              trailing: PopupMenuButton<String>(
                iconColor: Colors.white,
                onSelected: (response) {
                  if (response == 'delete') {
                    context.read<ProjectFormController>().removeLink(index);
                  } else if (response == 'edit') {
                    showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor:
                              context.theme.scaffoldBackgroundColor,
                          title: const Text('Edit URL'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 10,
                            children: [
                              GenericField(
                                controller: controller.titleController,
                                label: 'Title',
                              ),
                              GenericField(
                                controller: controller.urlController,
                                label: 'URL',
                                keyboardType: TextInputType.url,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                itemBuilder: (_) {
                  return const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
