// addClient, deleteClient, editClient, getClientById, getClientProjects,
// getClients

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/client/domain/usecases/add_client.dart';
import 'package:milestone/src/client/domain/usecases/delete_client.dart';
import 'package:milestone/src/client/domain/usecases/edit_client.dart';
import 'package:milestone/src/client/domain/usecases/get_client_by_id.dart';
import 'package:milestone/src/client/domain/usecases/get_client_projects.dart';
import 'package:milestone/src/client/domain/usecases/get_clients.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:mocktail/mocktail.dart';

class MockAddClient extends Mock implements AddClient {}

class MockDeleteClient extends Mock implements DeleteClient {}

class MockEditClient extends Mock implements EditClient {}

class MockGetClientById extends Mock implements GetClientById {}

class MockGetClientProjects extends Mock implements GetClientProjects {}

class MockGetClients extends Mock implements GetClients {}

void main() {
  late MockAddClient mockAddClient;
  late MockDeleteClient mockDeleteClient;
  late MockEditClient mockEditClient;
  late MockGetClientById mockGetClientById;
  late MockGetClientProjects mockGetClientProjects;
  late MockGetClients mockGetClients;
  late ClientCubit cubit;

  setUp(() {
    mockAddClient = MockAddClient();
    mockDeleteClient = MockDeleteClient();
    mockEditClient = MockEditClient();
    mockGetClientById = MockGetClientById();
    mockGetClientProjects = MockGetClientProjects();
    mockGetClients = MockGetClients();
    cubit = ClientCubit(
      addClient: mockAddClient,
      deleteClient: mockDeleteClient,
      editClient: mockEditClient,
      getClientById: mockGetClientById,
      getClientProjects: mockGetClientProjects,
      getClients: mockGetClients,
    );
  });

  const tFailure = ServerFailure(
    message: 'The caller does not have permission',
    statusCode: 'permission-denied',
  );

  test('initial state is ClientInitial', () {
    expect(cubit.state, const ClientInitial());
  });

  group('addClient', () {
    final tClient = ClientModel.empty();
    setUp(() {
      registerFallbackValue(tClient);
    });
    blocTest<ClientCubit, ClientState>(
      'should emit [ClientLoading, ClientAdded] when addClient is '
      'successful',
      build: () {
        when(() => mockAddClient(any())).thenAnswer(
          (_) async => Right(tClient),
        );
        return cubit;
      },
      act: (cubit) => cubit.addClient(tClient),
      expect: () => [
        const ClientLoading(),
        // because we don't know the random clientID from firestore
        isA<ClientAdded>(),
      ],
      verify: (_) {
        verify(() => mockAddClient(tClient)).called(1);
        verifyNoMoreInteractions(mockAddClient);
      },
    );

    blocTest<ClientCubit, ClientState>(
      'should emit [ClientLoading, ClientError] when addClient is '
      'unsuccessful',
      build: () {
        when(() => mockAddClient(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.addClient(tClient),
      expect: () => [
        const ClientLoading(),
        ClientError(
          title: 'Error Adding Client',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(() => mockAddClient(tClient)).called(1);
        verifyNoMoreInteractions(mockAddClient);
      },
    );
  });

  group('deleteClient', () {
    const tClientID = 'clientID';
    blocTest<ClientCubit, ClientState>(
      'should emit [ClientLoading, ClientDeleted] when deleteClient is '
      'successful',
      build: () {
        when(() => mockDeleteClient(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return cubit;
      },
      act: (cubit) => cubit.deleteClient(tClientID),
      expect: () => [
        const ClientLoading(),
        const ClientDeleted(),
      ],
      verify: (_) {
        verify(() => mockDeleteClient(tClientID)).called(1);
        verifyNoMoreInteractions(mockDeleteClient);
      },
    );

    blocTest<ClientCubit, ClientState>(
      'should emit [ClientLoading, ClientError] when deleteClient is '
      'unsuccessful',
      build: () {
        when(() => mockDeleteClient(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.deleteClient(tClientID),
      expect: () => [
        const ClientLoading(),
        ClientError(
          title: 'Error Deleting Client',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(() => mockDeleteClient(tClientID)).called(1);
        verifyNoMoreInteractions(mockDeleteClient);
      },
    );
  });

  group('editClient', () {
    const tClientID = 'clientID';
    const tUpdatedClient = {'name': 'new name'};

    setUp(() {
      registerFallbackValue(EditClientParams.empty());
    });
    blocTest<ClientCubit, ClientState>(
      'should emit [ClientLoading, ClientEdited] when editClient is '
      'successful',
      build: () {
        when(() => mockEditClient(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return cubit;
      },
      act: (cubit) => cubit.editClient(
        clientId: tClientID,
        updatedClient: tUpdatedClient,
      ),
      expect: () => [
        const ClientLoading(),
        const ClientUpdated(),
      ],
      verify: (_) {
        verify(
          () => mockEditClient(
            const EditClientParams(
              clientId: tClientID,
              updatedClient: tUpdatedClient,
            ),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockEditClient);
      },
    );

    blocTest<ClientCubit, ClientState>(
      'should emit [ClientLoading, ClientError] when editClient is '
      'unsuccessful',
      build: () {
        when(() => mockEditClient(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.editClient(
        clientId: tClientID,
        updatedClient: tUpdatedClient,
      ),
      expect: () => [
        const ClientLoading(),
        ClientError(
          title: 'Error Editing Client',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(
          () => mockEditClient(
            const EditClientParams(
              clientId: tClientID,
              updatedClient: tUpdatedClient,
            ),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockEditClient);
      },
    );
  });

  group('getClientById', () {
    const tClientID = 'clientID';
    final tClient = ClientModel.empty();
    setUp(() {
      registerFallbackValue(tClient);
    });
    blocTest<ClientCubit, ClientState>(
      'should emit [ClientLoading, ClientLoaded] when getClientById is '
      'successful',
      build: () {
        when(() => mockGetClientById(any())).thenAnswer(
          (_) async => Right(tClient),
        );
        return cubit;
      },
      act: (cubit) => cubit.getClientById(tClientID),
      expect: () => [
        const ClientLoading(),
        ClientLoaded(tClient),
      ],
      verify: (_) {
        verify(() => mockGetClientById(tClientID)).called(1);
        verifyNoMoreInteractions(mockGetClientById);
      },
    );

    blocTest<ClientCubit, ClientState>(
      'should emit [ClientLoading, ClientError] when getClientById is '
      'unsuccessful',
      build: () {
        when(() => mockGetClientById(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.getClientById(tClientID),
      expect: () => [
        const ClientLoading(),
        ClientError(
          title: 'Error Fetching Client',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(() => mockGetClientById(tClientID)).called(1);
        verifyNoMoreInteractions(mockGetClientById);
      },
    );
  });

  group('getClientProjects', () {
    const tClientID = 'clientID';
    final tProjects = <ProjectModel>[];
    setUp(() {
      registerFallbackValue(const GetClientProjectsParams.empty());
    });
    blocTest<ClientCubit, ClientState>(
      'should emit [ClientProjectsLoading, ClientProjectsLoaded] when '
      'getClientProjects is successful',
      build: () {
        when(() => mockGetClientProjects(any())).thenAnswer(
          (_) async => Right(tProjects),
        );
        return cubit;
      },
      act: (cubit) => cubit.getClientProjects(
        clientId: tClientID,
        detailed: false,
      ),
      expect: () => [
        const ClientProjectsLoading(),
        ClientProjectsLoaded(tProjects),
      ],
      verify: (_) {
        verify(
          () => mockGetClientProjects(
            const GetClientProjectsParams(clientId: tClientID, detailed: false),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockGetClientProjects);
      },
    );

    blocTest<ClientCubit, ClientState>(
      'should emit [ClientProjectsLoading, ClientError] when getClientProjects '
      'is unsuccessful',
      build: () {
        when(() => mockGetClientProjects(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.getClientProjects(
        clientId: tClientID,
        detailed: false,
      ),
      expect: () => [
        const ClientProjectsLoading(),
        ClientError(
          title: 'Error Fetching Client Projects',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(
          () => mockGetClientProjects(
            const GetClientProjectsParams(clientId: tClientID, detailed: false),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockGetClientProjects);
      },
    );
  });

  group('getClients', () {
    final tClients = <ClientModel>[];
    blocTest<ClientCubit, ClientState>(
      'should emit [ClientLoading, ClientsLoaded] when getClients is '
      'successful',
      build: () {
        when(() => mockGetClients()).thenAnswer(
          (_) async => Right(tClients),
        );
        return cubit;
      },
      act: (cubit) => cubit.getClients(),
      expect: () => [
        const ClientLoading(),
        ClientsLoaded(tClients),
      ],
      verify: (_) {
        verify(() => mockGetClients()).called(1);
        verifyNoMoreInteractions(mockGetClients);
      },
    );

    blocTest<ClientCubit, ClientState>(
      'should emit [ClientLoading, ClientError] when getClients is '
      'unsuccessful',
      build: () {
        when(() => mockGetClients()).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.getClients(),
      expect: () => [
        const ClientLoading(),
        ClientError(
          title: 'Error Fetching Clients',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(() => mockGetClients()).called(1);
        verifyNoMoreInteractions(mockGetClients);
      },
    );
  });
}
