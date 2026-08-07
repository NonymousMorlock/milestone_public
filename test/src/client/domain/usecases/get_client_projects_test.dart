import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/client/domain/usecases/get_client_projects.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:mocktail/mocktail.dart';

import 'client_repo.mock.dart';

void main() {
  late MockClientRepo repo;
  late GetClientProjects usecase;

  const tClientId = 'Test String';

  const tDetailed = true;

  setUp(() {
    repo = MockClientRepo();
    usecase = GetClientProjects(repo);
    registerFallbackValue(tClientId);
    registerFallbackValue(tDetailed);
  });

  test(
    'should return [List<Project>] from the repo',
    () async {
      when(
        () => repo.getClientProjects(
          clientId: any(named: 'clientId'),
          detailed: any(named: 'detailed'),
        ),
      ).thenAnswer(
        (_) async => const Right([]),
      );

      final result = await usecase(
        const GetClientProjectsParams(
          clientId: tClientId,
          detailed: tDetailed,
        ),
      );
      expect(result, equals(const Right<dynamic, List<Project>>([])));
      verify(
        () => repo.getClientProjects(
          clientId: any(named: 'clientId'),
          detailed: any(named: 'detailed'),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
