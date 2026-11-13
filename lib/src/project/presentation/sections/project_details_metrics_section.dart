import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/double_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ProjectDetailsMetricsSection extends StatelessWidget {
  const ProjectDetailsMetricsSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (label: 'Budget', value: project.budget.currency),
      (label: 'Total paid', value: project.totalPaid.currency),
      (label: 'Milestones', value: '${project.numberOfMilestonesSoFar}'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final compact = AppLayout.classify(constraints.maxWidth) == .compact;
        final itemWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - (spacing * (metrics.length - 1))) /
                  metrics.length;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map(
            (metric) {
              return SizedBox(
                width: itemWidth,
                child: AppSectionCard(
                  title: metric.label,
                  child: Text(
                    metric.value,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: .w700,
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }
}
