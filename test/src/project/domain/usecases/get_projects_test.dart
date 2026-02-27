import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/usecases/get_projects.dart';
import 'package:mocktail/mocktail.dart';

import 'project_repo.mock.dart';

void main() {
  late MockProjectRepo repo;
  late GetProjects usecase;

  setUp(() {
    repo = MockProjectRepo();
    usecase = GetProjects(repo);
  });

  test(
    'should emit [List<Project>] from the repo',
    () async {
      when(
        () => repo.getProjects(detailed: any(named: 'detailed')),
      ).thenAnswer((_) => Stream.value(const Right([])));

      final stream = usecase(true);
      expect(stream, emits(const Right<dynamic, List<Project>>([])));
      verify(
        () => repo.getProjects(detailed: true),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
