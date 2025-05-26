import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/domain/usecases/edit_project_details.dart';
import 'package:mocktail/mocktail.dart';

import 'project_repo.mock.dart';

void main() {
  late MockProjectRepo repo;
  late EditProjectDetails usecase;

  const tProjectId = 'Test String';

  const tUpdatedProject = <String, dynamic>{};

  setUp(() {
    repo = MockProjectRepo();
    usecase = EditProjectDetails(repo);
    registerFallbackValue(tProjectId);
    registerFallbackValue(tUpdatedProject);
  });

  test(
    'should call the [ProjectRepo.editProjectDetails]',
    () async {
      when(
        () => repo.editProjectDetails(
          projectId: any(named: 'projectId'),
          updatedProject: any(named: 'updatedProject'),
        ),
      ).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await usecase(
        const EditProjectDetailsParams(
          projectId: tProjectId,
          updatedProject: tUpdatedProject,
        ),
      );
      expect(result, equals(const Right<dynamic, void>(null)));
      verify(
        () => repo.editProjectDetails(
          projectId: any(named: 'projectId'),
          updatedProject: any(named: 'updatedProject'),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
