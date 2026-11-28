import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/usecases/add_project.dart';
import 'package:mocktail/mocktail.dart';

import 'project_repo.mock.dart';

void main() {
  late MockProjectRepo repo;
  late AddProject usecase;

  final tProject = Project.empty();

  setUp(() {
    repo = MockProjectRepo();
    usecase = AddProject(repo);
    registerFallbackValue(tProject);
  });

  test(
    'should call the [ProjectRepo.addProject]',
    () async {
      when(
        () => repo.addProject(
          any(),
        ),
      ).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await usecase(tProject);
      expect(result, equals(const Right<dynamic, void>(null)));
      verify(
        () => repo.addProject(
          any(),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
