import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/add_milestone.dart';
import 'package:mocktail/mocktail.dart';

import 'milestone_repo.mock.dart';

void main() {
  late MockMilestoneRepo repo;
  late AddMilestone usecase;

  final tMilestone = Milestone.empty();

  setUp(() {
    repo = MockMilestoneRepo();
    usecase = AddMilestone(repo);
    registerFallbackValue(tMilestone);
  });

  test(
    'should call the [MilestoneRepo.addMilestone]',
    () async {
      when(
        () => repo.addMilestone(
          any(),
        ),
      ).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await usecase(tMilestone);
      expect(result, equals(const Right<dynamic, void>(null)));
      verify(
        () => repo.addMilestone(
          any(),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
