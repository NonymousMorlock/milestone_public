import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/reorder_milestone.dart';
import 'package:mocktail/mocktail.dart';

import 'milestone_repo.mock.dart';

void main() {
  late MockMilestoneRepo repo;
  late ReorderMilestone usecase;

  setUp(() {
    repo = MockMilestoneRepo();
    usecase = ReorderMilestone(repo);
  });

  test('should call the [MilestoneRepo.reorderMilestone]', () async {
    when(
      () => repo.reorderMilestone(
        projectId: any(named: 'projectId'),
        milestoneId: any(named: 'milestoneId'),
        previousMilestoneId: any(named: 'previousMilestoneId'),
        nextMilestoneId: any(named: 'nextMilestoneId'),
        expectedOrderVersion: any(named: 'expectedOrderVersion'),
      ),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(
      const ReorderMilestoneParams(
        projectId: 'project-1',
        milestoneId: 'milestone-2',
        previousMilestoneId: 'milestone-1',
        nextMilestoneId: null,
        expectedOrderVersion: 7,
      ),
    );

    expect(result, equals(const Right<dynamic, void>(null)));
    verify(
      () => repo.reorderMilestone(
        projectId: 'project-1',
        milestoneId: 'milestone-2',
        previousMilestoneId: 'milestone-1',
        nextMilestoneId: null,
        expectedOrderVersion: 7,
      ),
    ).called(1);
    verifyNoMoreInteractions(repo);
  });
}
