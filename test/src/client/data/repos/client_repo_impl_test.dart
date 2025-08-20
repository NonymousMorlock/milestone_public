import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/client/data/datasources/client_remote_data_src.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/client/data/repos/client_repo_impl.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:mocktail/mocktail.dart';

class MockClientRemoteDataSrc extends Mock implements ClientRemoteDataSrc {}

void main() {
  late ClientRemoteDataSrc remoteDataSrc;
  late ClientRepoImpl repoImpl;

  final tClient = ClientModel.empty();

  setUp(() {
    remoteDataSrc = MockClientRemoteDataSrc();
    repoImpl = ClientRepoImpl(remoteDataSrc);
    registerFallbackValue(tClient);
  });

  const tException = ServerException(
    message: 'message',
    statusCode: 'statusCode',
  );

  group('addClient', () {
    test(
      'should complete successfully when call to remote source is '
      'successful',
      () async {
        when(() => remoteDataSrc.addClient(any())).thenAnswer(
          (_) async => tClient,
        );

        final result = await repoImpl.addClient(tClient);

        expect(result, equals(Right<Failure, Client>(tClient)));
        verify(() => remoteDataSrc.addClient(tClient)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );

    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(() => remoteDataSrc.addClient(any())).thenThrow(tException);

        final result = await repoImpl.addClient(tClient);

        expect(
          result,
          equals(
            Left<Failure, String>(ServerFailure.fromException(tException)),
          ),
        );
        verify(() => remoteDataSrc.addClient(tClient)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('editClient', () {
    test(
      'should complete successfully when call to remote source is '
      'successful',
      () async {
        when(
          () => remoteDataSrc.editClient(
            clientId: any(named: 'clientId'),
            updatedClient: any(named: 'updatedClient'),
          ),
        ).thenAnswer((_) async => Future.value());

        final result = await repoImpl.editClient(
          clientId: tClient.id,
          updatedClient: {},
        );

        expect(result, equals(const Right<Failure, void>(null)));
        verify(
          () => remoteDataSrc.editClient(
            clientId: tClient.id,
            updatedClient: {},
          ),
        ).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );

    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(
          () => remoteDataSrc.editClient(
            clientId: any(named: 'clientId'),
            updatedClient: any(named: 'updatedClient'),
          ),
        ).thenThrow(tException);

        final result = await repoImpl.editClient(
          clientId: tClient.id,
          updatedClient: {},
        );

        expect(
          result,
          equals(
            Left<Failure, String>(ServerFailure.fromException(tException)),
          ),
        );
        verify(
          () => remoteDataSrc.editClient(
            clientId: tClient.id,
            updatedClient: {},
          ),
        ).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('deleteClient', () {
    test(
      'should complete successfully when call to remote source is '
      'successful',
      () async {
        when(() => remoteDataSrc.deleteClient(any())).thenAnswer(
          (_) async => Future.value(),
        );
        final result = await repoImpl.deleteClient(tClient.id);

        expect(result, equals(const Right<Failure, void>(null)));

        verify(() => remoteDataSrc.deleteClient(tClient.id)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );

    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(() => remoteDataSrc.deleteClient(any())).thenThrow(tException);

        final result = await repoImpl.deleteClient(tClient.id);

        expect(
          result,
          equals(
            Left<Failure, void>(ServerFailure.fromException(tException)),
          ),
        );

        verify(() => remoteDataSrc.deleteClient(tClient.id)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('getClientById', () {
    test(
      'should return [Client] when call to remote source is successful',
      () async {
        when(() => remoteDataSrc.getClientById(any())).thenAnswer(
          (_) async => tClient,
        );
        final result = await repoImpl.getClientById(tClient.id);

        expect(result, equals(Right<Failure, Client>(tClient)));

        verify(() => remoteDataSrc.getClientById(tClient.id)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(() => remoteDataSrc.getClientById(any())).thenThrow(tException);
        final result = await repoImpl.getClientById(tClient.id);

        expect(
          result,
          equals(
            Left<Failure, Client>(ServerFailure.fromException(tException)),
          ),
        );

        verify(() => remoteDataSrc.getClientById(tClient.id)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('getClients', () {
    test(
      'should return [List<Client>] when call to remote source is successful',
      () async {
        final expectedClients = [tClient];
        when(() => remoteDataSrc.getClients()).thenAnswer(
          (_) async => expectedClients,
        );

        final result = await repoImpl.getClients();

        expect(result, equals(Right<Failure, List<Client>>(expectedClients)));

        verify(() => remoteDataSrc.getClients()).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(() => remoteDataSrc.getClients()).thenThrow(tException);

        final result = await repoImpl.getClients();

        expect(
          result,
          equals(
            Left<Failure, List<Client>>(
              ServerFailure.fromException(tException),
            ),
          ),
        );

        verify(() => remoteDataSrc.getClients()).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('getClientProjects', () {
    test(
      'should return [List<Project>] when call to remote source is successful',
      () async {
        final expectedProjects = [ProjectModel.empty()];
        when(
          () => remoteDataSrc.getClientProjects(
            clientId: any(named: 'clientId'),
            detailed: any(named: 'detailed'),
          ),
        ).thenAnswer((_) async => expectedProjects);

        final result = await repoImpl.getClientProjects(
          clientId: tClient.id,
          detailed: true,
        );

        expect(result, equals(Right<Failure, List<Project>>(expectedProjects)));

        verify(
          () => remoteDataSrc.getClientProjects(
            clientId: tClient.id,
            detailed: true,
          ),
        ).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(
          () => remoteDataSrc.getClientProjects(
            clientId: any(named: 'clientId'),
            detailed: any(named: 'detailed'),
          ),
        ).thenThrow(tException);

        final result = await repoImpl.getClientProjects(
          clientId: tClient.id,
          detailed: true,
        );

        expect(
          result,
          equals(
            Left<Failure, List<Project>>(
              ServerFailure.fromException(tException),
            ),
          ),
        );

        verify(
          () => remoteDataSrc.getClientProjects(
            clientId: tClient.id,
            detailed: true,
          ),
        ).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });
}
