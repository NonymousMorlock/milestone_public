import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/delete_milestone.dart';
import 'package:mocktail/mocktail.dart';

import 'milestone_repo.mock.dart';

void main() {
  late MockMilestoneRepo repo;
  late DeleteMilestone usecase;

  const tMilestoneId = 'Test String';

  setUp(() {
    repo = MockMilestoneRepo();
    usecase = DeleteMilestone(repo);
    registerFallbackValue(tMilestoneId);
    registerFallbackValue(tMilestoneId);
  });

  test(
    'should call the [MilestoneRepo.deleteMilestone]',
    () async {
      when(
        () => repo.deleteMilestone(
          projectId: any(named: 'projectId'),
          milestoneId: any(named: 'milestoneId'),
        ),
      ).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await usecase(
        const DeleteMilestoneParams(
          projectId: tMilestoneId,
          milestoneId: tMilestoneId,
        ),
      );
      expect(result, equals(const Right<dynamic, void>(null)));
      verify(
        () => repo.deleteMilestone(
          projectId: any(named: 'projectId'),
          milestoneId: any(named: 'milestoneId'),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
