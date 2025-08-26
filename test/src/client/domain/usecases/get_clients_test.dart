import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/domain/usecases/get_clients.dart';
import 'package:mocktail/mocktail.dart';

import 'client_repo.mock.dart';

void main() {
  late MockClientRepo repo;
  late GetClients usecase;

  setUp(() {
    repo = MockClientRepo();
    usecase = GetClients(repo);
  });

  test(
    'should return [List<Client>] from the repo',
    () async {
      when(
        () => repo.getClients(),
      ).thenAnswer(
        (_) async => const Right([]),
      );

      final result = await usecase();
      expect(result, equals(const Right<dynamic, List<Client>>([])));
      verify(
        () => repo.getClients(),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
