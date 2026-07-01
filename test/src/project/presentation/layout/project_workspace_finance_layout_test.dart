import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/presentation/layout/project_workspace_finance_layout.dart';

void main() {
  final project = ProjectModel.empty().copyWith(id: 'project-1');

  test('returns no-budget state when budget is zero', () {
    final layout = ProjectWorkspaceFinanceLayout.fromProject(
      project.copyWith(budget: 0, totalPaid: 40),
    );

    expect(layout.financeState, ProjectWorkspaceFinanceState.noBudget);
  });

  test('returns under-budget state with remaining label', () {
    final layout = ProjectWorkspaceFinanceLayout.fromProject(
      project.copyWith(budget: 100, totalPaid: 40),
    );

    expect(layout.financeState, ProjectWorkspaceFinanceState.underBudget);
    expect(layout.remainingLabel, isNotNull);
  });

  test('returns overrun state with overrun label', () {
    final layout = ProjectWorkspaceFinanceLayout.fromProject(
      project.copyWith(budget: 100, totalPaid: 140),
    );

    expect(layout.financeState, ProjectWorkspaceFinanceState.overrun);
    expect(layout.overrunLabel, isNotNull);
  });
}
