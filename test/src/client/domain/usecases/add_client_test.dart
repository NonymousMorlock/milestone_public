import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/domain/usecases/add_client.dart';
import 'package:mocktail/mocktail.dart';

import 'client_repo.mock.dart';

void main() {
  late MockClientRepo repo;
  late AddClient usecase;

  final tClient = Client.empty();

  setUp(() {
    repo = MockClientRepo();
    usecase = AddClient(repo);
    registerFallbackValue(tClient);
  });

  test(
    'should call the [ClientRepo.addClient]',
    () async {
      when(
        () => repo.addClient(
          any(),
        ),
      ).thenAnswer(
        (_) async => Right(tClient),
      );

      final result = await usecase(tClient);
      expect(result, equals(Right<dynamic, Client>(tClient)));
      verify(
        () => repo.addClient(
          any(),
        ),
      ).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
