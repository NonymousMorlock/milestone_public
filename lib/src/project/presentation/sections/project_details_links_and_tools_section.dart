import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/utils/url_launcher_utils.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ProjectDetailsLinksAndToolsSection extends StatelessWidget {
  const ProjectDetailsLinksAndToolsSection({
    required this.project,
    super.key,
  });

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tools',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (project.tools.isEmpty)
          Text(
            'No tools captured for this project yet.',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: project.tools
                .map((tool) => Chip(label: Text(tool)))
                .toList(),
          ),
        const SizedBox(height: 20),
        Text(
          'Links',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (project.urls.isEmpty)
          Text(
            'No links available for this project.',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...project.urls.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
            ),
          ),
      ],
    );
  }
}
