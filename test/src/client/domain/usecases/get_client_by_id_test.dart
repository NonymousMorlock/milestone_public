import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/domain/usecases/get_client_by_id.dart';
import 'package:mocktail/mocktail.dart';

import 'client_repo.mock.dart';

void main() {
  late MockClientRepo repo;
  late GetClientById usecase;

  const tClientId = 'Test String';

  final tResult = Client.empty();

  setUp(() {
    repo = MockClientRepo();
    usecase = GetClientById(repo);
    registerFallbackValue(tClientId);
  });

  test(
    'should return [Client] from the repo',
    () async {
      when(
        () => repo.getClientById(
          any(),
        ),
      ).thenAnswer(
        (_) async => Right(tResult),
      );

      final result = await usecase(tClientId);
      expect(result, equals(Right<dynamic, Client>(tResult)));
      verify(
        () => repo.getClientById(
          any(),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
