import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/edit_milestone.dart';
import 'package:mocktail/mocktail.dart';

import 'milestone_repo.mock.dart';

void main() {
  late MockMilestoneRepo repo;
  late EditMilestone usecase;

  const tMilestoneId = 'Test String';

  const tUpdatedMilestone = <String, dynamic>{};

  setUp(() {
    repo = MockMilestoneRepo();
    usecase = EditMilestone(repo);
    registerFallbackValue(tMilestoneId);
    registerFallbackValue(tMilestoneId);
    registerFallbackValue(tUpdatedMilestone);
  });

  test(
    'should call the [MilestoneRepo.editMilestone]',
    () async {
      when(
        () => repo.editMilestone(
          projectId: any(named: 'projectId'),
          milestoneId: any(named: 'milestoneId'),
          updatedMilestone: any(named: 'updatedMilestone'),
        ),
      ).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await usecase(
        const EditMilestoneParams(
          projectId: tMilestoneId,
          milestoneId: tMilestoneId,
          updatedMilestone: tUpdatedMilestone,
        ),
      );
      expect(result, equals(const Right<dynamic, void>(null)));
      verify(
        () => repo.editMilestone(
          projectId: any(named: 'projectId'),
          milestoneId: any(named: 'milestoneId'),
          updatedMilestone: any(named: 'updatedMilestone'),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
