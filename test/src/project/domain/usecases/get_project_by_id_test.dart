import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/usecases/get_project_by_id.dart';
import 'package:mocktail/mocktail.dart';

import 'project_repo.mock.dart';

void main() {
  late MockProjectRepo repo;
  late GetProjectById usecase;

  const tProjectId = 'Test String';
  final tProject = Project.empty();

  setUp(() {
    repo = MockProjectRepo();
    usecase = GetProjectById(repo);
    registerFallbackValue(tProjectId);
  });

  test(
    'should return [Project] from the repo',
    () async {
      when(
        () => repo.getProjectById(any()),
      ).thenAnswer(
        (_) async => Right(tProject),
      );

      final result = await usecase(tProjectId);
      expect(result, equals(Right<dynamic, Project>(tProject)));
      verify(
        () => repo.getProjectById(any()),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
