import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/client/domain/usecases/delete_client.dart';
import 'package:mocktail/mocktail.dart';

import 'client_repo.mock.dart';

void main() {
  late MockClientRepo repo;
  late DeleteClient usecase;

  const tClientId = 'Test String';

  setUp(() {
    repo = MockClientRepo();
    usecase = DeleteClient(repo);
    registerFallbackValue(tClientId);
  });

  test(
    'should call the [ClientRepo.deleteClient]',
    () async {
      when(
        () => repo.deleteClient(
          any(),
        ),
      ).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await usecase(tClientId);
      expect(result, equals(const Right<dynamic, void>(null)));
      verify(
        () => repo.deleteClient(
          any(),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
