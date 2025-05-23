import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestones.dart';
import 'package:mocktail/mocktail.dart';

import 'milestone_repo.mock.dart';

void main() {
  late MockMilestoneRepo repo;
  late GetMilestones usecase;

  const tMilestoneId = 'Test String';

  setUp(() {
    repo = MockMilestoneRepo();
    usecase = GetMilestones(repo);
    registerFallbackValue(tMilestoneId);
  });

  test(
    'should return [List<Milestone>] from the repo',
    () async {
      when(
        () => repo.getMilestones(
          any(),
        ),
      ).thenAnswer(
        (_) async => const Right([]),
      );

      final result = await usecase(tMilestoneId);
      expect(result, equals(const Right<dynamic, List<Milestone>>([])));
      verify(
        () => repo.getMilestones(
          any(),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
