import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/client/domain/usecases/add_client.dart';
import 'package:milestone/src/client/domain/usecases/delete_client.dart';
import 'package:milestone/src/client/domain/usecases/edit_client.dart';
import 'package:milestone/src/client/domain/usecases/get_client_by_id.dart';
import 'package:milestone/src/client/domain/usecases/get_client_project_counts.dart';
import 'package:milestone/src/client/domain/usecases/get_client_projects.dart';
import 'package:milestone/src/client/domain/usecases/get_clients.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/layout/client_workspace_snapshot_layout.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:mocktail/mocktail.dart';

class MockAddClient extends Mock implements AddClient {}

class MockDeleteClient extends Mock implements DeleteClient {}

class MockEditClient extends Mock implements EditClient {}

class MockGetClientById extends Mock implements GetClientById {}

class MockGetClientProjectCounts extends Mock
    implements GetClientProjectCounts {}

class MockGetClientProjects extends Mock implements GetClientProjects {}

class MockGetClients extends Mock implements GetClients {}

void main() {
  late MockAddClient mockAddClient;
  late MockDeleteClient mockDeleteClient;
  late MockEditClient mockEditClient;
  late MockGetClientById mockGetClientById;
  late MockGetClientProjectCounts mockGetClientProjectCounts;
  late MockGetClientProjects mockGetClientProjects;
  late MockGetClients mockGetClients;
  late ClientCubit cubit;

  const failure = ServerFailure(
    message: 'Permission denied',
    statusCode: 'permission-denied',
  );

  setUp(() {
    mockAddClient = MockAddClient();
    mockDeleteClient = MockDeleteClient();
    mockEditClient = MockEditClient();
    mockGetClientById = MockGetClientById();
    mockGetClientProjectCounts = MockGetClientProjectCounts();
    mockGetClientProjects = MockGetClientProjects();
    mockGetClients = MockGetClients();
    registerFallbackValue(const GetClientProjectsParams.empty());
    cubit = ClientCubit(
      addClient: mockAddClient,
      deleteClient: mockDeleteClient,
      editClient: mockEditClient,
      getClientById: mockGetClientById,
      getClientProjectCounts: mockGetClientProjectCounts,
      getClientProjects: mockGetClientProjects,
      getClients: mockGetClients,
    );
  });

  test('initial state is ClientInitial', () {
    expect(cubit.state, const ClientInitial());
  });

  group('getClientWorkspaceList', () {
    final client = ClientModel.empty().copyWith(
      id: 'client-1',
      name: 'Acme',
      totalSpent: 1200,
    );

    blocTest<ClientCubit, ClientState>(
      'emits workspace summaries when clients and grouped counts succeed',
      build: () {
        when(() => mockGetClients()).thenAnswer((_) async => Right([client]));
        when(
          () => mockGetClientProjectCounts(),
        ).thenAnswer((_) async => const Right({'client-1': 2}));
        return cubit;
      },
      act: (cubit) => cubit.getClientWorkspaceList(),
      expect: () => [
        const ClientWorkspaceListLoading(),
        const ClientWorkspaceListLoaded([
          ClientWorkspaceSnapshotLayout(
            clientId: 'client-1',
            clientName: 'Acme',
            totalSpent: 1200,
            projectCount: 2,
            clientImage: 'Test String',
          ),
        ]),
      ],
    );

    blocTest<ClientCubit, ClientState>(
      'emits ClientError when grouped counts fail',
      build: () {
        when(() => mockGetClients()).thenAnswer((_) async => Right([client]));
        when(
          () => mockGetClientProjectCounts(),
        ).thenAnswer((_) async => const Left(failure));
        return cubit;
      },
      act: (cubit) => cubit.getClientWorkspaceList(),
      expect: () => [
        const ClientWorkspaceListLoading(),
        const ClientError(
          title: 'Error Fetching Client Summaries',
          message: '[permission-denied] Permission denied',
          statusCode: 'permission-denied',
        ),
      ],
    );
  });

  group('bootstrapClientEdit', () {
    final client = ClientModel.empty().copyWith(id: 'client-1', name: 'Acme');

    blocTest<ClientCubit, ClientState>(
      'emits ClientEditLoaded on successful bootstrap',
      build: () {
        when(() => mockGetClientById(any())).thenAnswer(
          (_) async => Right(client),
        );
        return cubit;
      },
      act: (cubit) => cubit.bootstrapClientEdit('client-1'),
      expect: () => [
        const ClientLoading(),
        ClientEditLoaded(client: client, isSaving: false),
      ],
    );
  });

  group('saveClientEdit', () {
    final client = ClientModel.empty().copyWith(id: 'client-1', name: 'Acme');

    setUp(() {
      registerFallbackValue(EditClientParams.empty());
    });

    blocTest<ClientCubit, ClientState>(
      'preserves the seeded edit state when save fails',
      build: () {
        when(() => mockEditClient(any())).thenAnswer(
          (_) async => const Left(failure),
        );
        return cubit;
      },
      seed: () => ClientEditLoaded(client: client, isSaving: false),
      act: (cubit) => cubit.saveClientEdit(
        clientId: 'client-1',
        updatedClient: const {'name': 'Acme Studio'},
      ),
      expect: () => [
        ClientEditLoaded(client: client, isSaving: true),
        ClientEditLoaded(
          client: client,
          isSaving: false,
          actionFailure: const ClientEditActionFailure(
            title: 'Error Editing Client',
            message: '[permission-denied] Permission denied',
            statusCode: 'permission-denied',
          ),
        ),
      ],
    );
  });

  group('deleteClient', () {
    const snapshot = ClientWorkspaceSnapshotLayout(
      clientId: 'client-1',
      clientName: 'Acme',
      totalSpent: 1200,
      projectCount: 1,
    );
    final project = ProjectModel.empty().copyWith(
      clientId: 'client-1',
      clientName: 'Acme',
      projectName: 'Website',
    );
    final client = ClientModel.empty().copyWith(id: 'client-1', name: 'Acme');

    blocTest<ClientCubit, ClientState>(
      'refreshes canonical workspace after delete conflict',
      build: () {
        when(() => mockDeleteClient('client-1')).thenAnswer(
          (_) async => const Left(
            ServerFailure(
              message: 'Move linked projects first',
              statusCode: 'client-linked-projects-conflict',
            ),
          ),
        );
        when(() => mockGetClientById('client-1')).thenAnswer(
          (_) async => Right(client),
        );
        when(() => mockGetClientProjects(any())).thenAnswer(
          (_) async => Right([project]),
        );
        return cubit;
      },
      seed: () => const ClientWorkspaceLoaded(
        snapshot: snapshot,
        projects: [],
        isDeleting: false,
        isRefreshing: false,
      ),
      act: (cubit) => cubit.deleteClient('client-1'),
      expect: () => [
        const ClientWorkspaceLoaded(
          snapshot: snapshot,
          projects: [],
          isDeleting: true,
          isRefreshing: false,
        ),
        const ClientWorkspaceLoaded(
          snapshot: snapshot,
          projects: [],
          isDeleting: false,
          isRefreshing: true,
        ),
        ClientWorkspaceLoaded(
          snapshot: const ClientWorkspaceSnapshotLayout(
            clientId: 'client-1',
            clientName: 'Acme',
            totalSpent: 1,
            projectCount: 1,
            clientImage: 'Test String',
          ),
          projects: [project],
          isDeleting: false,
          isRefreshing: false,
          actionFailure: const ClientWorkspaceActionFailure(
            title: 'Error Deleting Client',
            message:
                '[client-linked-projects-conflict] Move linked projects first',
            statusCode: 'client-linked-projects-conflict',
          ),
        ),
      ],
    );
  });
}
