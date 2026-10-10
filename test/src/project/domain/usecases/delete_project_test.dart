import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/domain/usecases/delete_project.dart';
import 'package:mocktail/mocktail.dart';

import 'project_repo.mock.dart';

void main() {
  late MockProjectRepo repo;
  late DeleteProject usecase;

  const tProjectId = 'Test String';

  setUp(() {
    repo = MockProjectRepo();
    usecase = DeleteProject(repo);
    registerFallbackValue(tProjectId);
  });

  test(
    'should call the [ProjectRepo.deleteProject]',
    () async {
      when(
        () => repo.deleteProject(
          any(),
        ),
      ).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await usecase(tProjectId);
      expect(result, equals(const Right<dynamic, void>(null)));
      verify(
        () => repo.deleteProject(
          any(),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
