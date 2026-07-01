import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/presentation/layout/project_workspace_status_layout.dart';

void main() {
  final project = ProjectModel.empty().copyWith(
    id: 'project-1',
    startDate: DateTime(2024),
  );

  test('returns pending deletion when deletion marker exists', () {
    final layout = ProjectWorkspaceStatusLayout.fromProject(
      project.copyWith(deletionRequestedAt: DateTime(2024, 1, 2)),
      now: DateTime(2024, 1, 3),
    );

    expect(layout.label, 'Pending deletion');
  });

  test('returns overdue when deadline has passed', () {
    final layout = ProjectWorkspaceStatusLayout.fromProject(
      project.copyWith(deadline: DateTime(2024, 1, 2)),
      now: DateTime(2024, 1, 5),
    );

    expect(layout.label, 'Overdue');
  });

  test('returns ongoing for continuous projects without deadline pressure', () {
    final layout = ProjectWorkspaceStatusLayout.fromProject(
      project.copyWith(isOneTime: false),
      now: DateTime(2024, 1, 3),
    );

    expect(layout.label, 'Ongoing');
  });
}
