import 'package:equatable/equatable.dart';
import 'package:milestone/core/extensions/double_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

enum ProjectWorkspaceFinanceState {
  noBudget,
  underBudget,
  fullyPaid,
  overrun,
}

class ProjectWorkspaceFinanceLayout extends Equatable {
  const ProjectWorkspaceFinanceLayout({
    required this.budgetLabel,
    required this.paidLabel,
    required this.milestoneCountLabel,
    required this.financeState,
    this.remainingLabel,
    this.overrunLabel,
  });

  factory ProjectWorkspaceFinanceLayout.fromProject(Project project) {
    final budgetLabel = project.budget.currency;
    final paidLabel = project.totalPaid.currency;
    final milestoneCountLabel = '${project.numberOfMilestonesSoFar}';

    if (project.budget <= 0) {
      return ProjectWorkspaceFinanceLayout(
        budgetLabel: 'No budget set',
        paidLabel: paidLabel,
        milestoneCountLabel: milestoneCountLabel,
        financeState: .noBudget,
      );
    }

    if (project.totalPaid < project.budget) {
      return ProjectWorkspaceFinanceLayout(
        budgetLabel: budgetLabel,
        paidLabel: paidLabel,
        milestoneCountLabel: milestoneCountLabel,
        remainingLabel: (project.budget - project.totalPaid).currency,
        financeState: .underBudget,
      );
    }

    if (project.totalPaid == project.budget) {
      return ProjectWorkspaceFinanceLayout(
        budgetLabel: budgetLabel,
        paidLabel: paidLabel,
        milestoneCountLabel: milestoneCountLabel,
        remainingLabel: 0.0.currency,
        financeState: .fullyPaid,
      );
    }

    return ProjectWorkspaceFinanceLayout(
      budgetLabel: budgetLabel,
      paidLabel: paidLabel,
      milestoneCountLabel: milestoneCountLabel,
      overrunLabel: (project.totalPaid - project.budget).currency,
      financeState: .overrun,
    );
  }

  final String budgetLabel;
  final String paidLabel;
  final String milestoneCountLabel;
  final String? remainingLabel;
  final String? overrunLabel;
  final ProjectWorkspaceFinanceState financeState;

  @override
  List<Object?> get props => [
    budgetLabel,
    paidLabel,
    milestoneCountLabel,
    remainingLabel,
    overrunLabel,
    financeState,
  ];
}
