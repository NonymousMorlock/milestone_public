import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/utils/url_launcher_utils.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ProjectDetailsLinksSection extends StatelessWidget {
  const ProjectDetailsLinksSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    if (project.urls.isEmpty) {
      return Text(
        'No links available for this project.',
        style: context.textTheme.bodyLarge?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: project.urls.map((link) {
        return Padding(
          padding: const .only(bottom: 12),
          child: AppSectionCard(
            title: link.title,
            subtitle: link.url,
            action: TextButton(
              onPressed: () async {
                await UrlLauncherUtils.openLink(link.url);
              },
              child: const Text('Open'),
            ),
            child: Text(
              'Project reference link',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
