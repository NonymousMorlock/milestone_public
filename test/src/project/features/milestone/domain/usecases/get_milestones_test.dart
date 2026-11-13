import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone_collection_snapshot.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestones.dart';
import 'package:mocktail/mocktail.dart';

import 'milestone_repo.mock.dart';

void main() {
  late MockMilestoneRepo repo;
  late GetMilestones usecase;

  const tMilestoneId = 'Test String';
  const tSnapshot = MilestoneCollectionSnapshot(
    milestones: [],
    orderVersion: 0,
  );

  setUp(() {
    repo = MockMilestoneRepo();
    usecase = GetMilestones(repo);
    registerFallbackValue(tMilestoneId);
  });

  test(
    'should return [MilestoneCollectionSnapshot] from the repo',
    () async {
      when(
        () => repo.getMilestones(
          any(),
        ),
      ).thenAnswer(
        (_) async => const Right(tSnapshot),
      );

      final result = await usecase(tMilestoneId);
      expect(
        result,
        equals(const Right<dynamic, MilestoneCollectionSnapshot>(tSnapshot)),
      );
      verify(
        () => repo.getMilestones(
          any(),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
