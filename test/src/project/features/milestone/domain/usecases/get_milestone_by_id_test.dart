import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestone_by_id.dart';
import 'package:mocktail/mocktail.dart';

import 'milestone_repo.mock.dart';

void main() {
  late MockMilestoneRepo repo;
  late GetMilestoneById usecase;

  const tMilestoneId = 'Test String';

  final tResult = Milestone.empty();

  setUp(() {
    repo = MockMilestoneRepo();
    usecase = GetMilestoneById(repo);
    registerFallbackValue(tMilestoneId);
    registerFallbackValue(tMilestoneId);
  });

  test(
    'should return [Milestone] from the repo',
    () async {
      when(
        () => repo.getMilestoneById(
          projectId: any(named: 'projectId'),
          milestoneId: any(named: 'milestoneId'),
        ),
      ).thenAnswer(
        (_) async => Right(tResult),
      );

      final result = await usecase(
        const GetMilestoneByIdParams(
          projectId: tMilestoneId,
          milestoneId: tMilestoneId,
        ),
      );
      expect(result, equals(Right<dynamic, Milestone>(tResult)));
      verify(
        () => repo.getMilestoneById(
          projectId: any(named: 'projectId'),
          milestoneId: any(named: 'milestoneId'),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
