import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/client/domain/usecases/get_client_project_counts.dart';
import 'package:mocktail/mocktail.dart';

import 'client_repo.mock.dart';

void main() {
  late MockClientRepo repo;
  late GetClientProjectCounts usecase;

  setUp(() {
    repo = MockClientRepo();
    usecase = GetClientProjectCounts(repo);
  });

  test('delegates grouped count reads to the client repo', () async {
    when(() => repo.getClientProjectCounts()).thenAnswer(
      (_) async => const Right({'client-1': 2}),
    );

    final result = await usecase();

    expect(
      result,
      equals(const Right<dynamic, Map<String, int>>({'client-1': 2})),
    );
    verify(() => repo.getClientProjectCounts()).called(1);
    verifyNoMoreInteractions(repo);
  });
}
