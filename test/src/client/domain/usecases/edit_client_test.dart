import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/client/domain/usecases/edit_client.dart';
import 'package:mocktail/mocktail.dart';

import 'client_repo.mock.dart';

void main() {
  late MockClientRepo repo;
  late EditClient usecase;

  const tClientId = 'Test String';

  const tUpdatedClient = <String, dynamic>{};

  setUp(() {
    repo = MockClientRepo();
    usecase = EditClient(repo);
    registerFallbackValue(tClientId);
    registerFallbackValue(tUpdatedClient);
  });

  test(
    'should call the [ClientRepo.editClient]',
    () async {
      when(
        () => repo.editClient(
          clientId: any(named: 'clientId'),
          updatedClient: any(named: 'updatedClient'),
        ),
      ).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await usecase(
        const EditClientParams(
          clientId: tClientId,
          updatedClient: tUpdatedClient,
        ),
      );
      expect(result, equals(const Right<dynamic, void>(null)));
      verify(
        () => repo.editClient(
          clientId: any(named: 'clientId'),
          updatedClient: any(named: 'updatedClient'),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
