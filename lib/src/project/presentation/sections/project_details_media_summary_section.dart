import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/res/res.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ProjectDetailsMediaSummarySection extends StatelessWidget {
  const ProjectDetailsMediaSummarySection({
    required this.project,
    super.key,
  });

  final Project project;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tokens = context.milestoneTheme;
    return AppSectionCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = AppLayout.classify(constraints.maxWidth) == .compact;
          final media = ClipRRect(
            borderRadius: .circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  image: DecorationImage(
                    image: project.image == null || project.image!.isEmpty
                        ? const AssetImage(Res.projectBanner1)
                        : NetworkImage(project.image!) as ImageProvider,
                    fit: .cover,
                    colorFilter: .mode(tokens.imageScrim, .darken),
                  ),
                ),
              ),
            ),
          );

          final summary = Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                project.shortDescription,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: .w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Client: ${project.clientName}',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Project type: ${project.projectType}',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                project.isOneTime
                    ? 'One-time engagement'
                    : 'Continuous engagement',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: .stretch,
              spacing: 16,
              children: [
                media,
                summary,
              ],
            );
          }

          return Row(
            crossAxisAlignment: .start,
            spacing: 20,
            children: [
              Expanded(flex: 5, child: media),
              Expanded(flex: 4, child: summary),
            ],
          );
        },
      ),
    );
  }
}
