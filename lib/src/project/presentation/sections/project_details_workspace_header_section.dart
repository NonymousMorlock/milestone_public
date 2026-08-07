import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/res/res.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/layout/project_workspace_finance_layout.dart';
import 'package:milestone/src/project/presentation/layout/project_workspace_status_layout.dart';

class ProjectDetailsWorkspaceHeaderSection extends StatelessWidget {
  const ProjectDetailsWorkspaceHeaderSection({
    required this.project,
    super.key,
  });

  final Project project;

  @override
  Widget build(BuildContext context) {
    final status = ProjectWorkspaceStatusLayout.fromProject(project);
    final finance = ProjectWorkspaceFinanceLayout.fromProject(project);
    final scheme = context.colorScheme;
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            image: DecorationImage(
              image: project.image == null || project.image!.isEmpty
                  ? const AssetImage(Res.projectBanner1)
                  : NetworkImage(project.image!) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );

    final metadata = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(context, status.semanticTone),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status.label,
            style: context.textTheme.labelLarge?.copyWith(
              color: _statusOnColor(context, status.semanticTone),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          project.projectName,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${project.clientName} · ${project.projectType}',
          style: context.textTheme.titleMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          project.isOneTime ? 'One-time engagement' : 'Continuous engagement',
          style: context.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          status.supportingCopy,
          style: context.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Primary signal: ${finance.paidLabel} paid',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return AppSectionCard(
      title: 'Workspace header',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              AppLayout.classify(constraints.maxWidth) == AppLayoutSize.compact;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                metadata,
                const SizedBox(height: 16),
                image,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: metadata),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: image),
            ],
          );
        },
      ),
    );
  }

  Color _statusColor(
    BuildContext context,
    ProjectWorkspaceStatusTone tone,
  ) {
    final scheme = context.colorScheme;
    return switch (tone) {
      ProjectWorkspaceStatusTone.positive => scheme.primaryContainer,
      ProjectWorkspaceStatusTone.warning => scheme.tertiaryContainer,
      ProjectWorkspaceStatusTone.critical => scheme.errorContainer,
      ProjectWorkspaceStatusTone.neutral => scheme.surfaceContainerHighest,
    };
  }

  Color _statusOnColor(
    BuildContext context,
    ProjectWorkspaceStatusTone tone,
  ) {
    final scheme = context.colorScheme;
    return switch (tone) {
      ProjectWorkspaceStatusTone.positive => scheme.onPrimaryContainer,
      ProjectWorkspaceStatusTone.warning => scheme.onTertiaryContainer,
      ProjectWorkspaceStatusTone.critical => scheme.onErrorContainer,
      ProjectWorkspaceStatusTone.neutral => scheme.onSurfaceVariant,
    };
  }
}
