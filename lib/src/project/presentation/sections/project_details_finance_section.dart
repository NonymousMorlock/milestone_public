import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/layout/project_workspace_finance_layout.dart';

class ProjectDetailsFinanceSection extends StatelessWidget {
  const ProjectDetailsFinanceSection({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final finance = ProjectWorkspaceFinanceLayout.fromProject(project);
    final cards = [
      (label: 'Budget', value: finance.budgetLabel),
      (label: 'Total paid', value: finance.paidLabel),
      (label: 'Milestones', value: finance.milestoneCountLabel),
      if (finance.remainingLabel != null)
        (label: 'Remaining', value: finance.remainingLabel!),
      if (finance.overrunLabel != null)
        (label: 'Overrun', value: finance.overrunLabel!),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final compact = AppLayout.classify(constraints.maxWidth) == .compact;
        final itemWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - (spacing * (cards.length - 1))) /
                  cards.length;
        return AppSectionCard(
          title: 'Finance',
          subtitle: switch (finance.financeState) {
            ProjectWorkspaceFinanceState.noBudget =>
              'Budget is still open, but paid totals are tracked.',
            ProjectWorkspaceFinanceState.underBudget =>
              'The project is still within budget.',
            ProjectWorkspaceFinanceState.fullyPaid =>
              'Budget and paid totals are currently aligned.',
            ProjectWorkspaceFinanceState.overrun =>
              'Paid totals have exceeded the tracked budget.',
          },
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: cards.map((card) {
              return SizedBox(
                width: itemWidth,
                child: AppSectionCard(
                  title: card.label,
                  child: Text(
                    card.value,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: .w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
