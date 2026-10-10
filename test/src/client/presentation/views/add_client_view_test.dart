import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/app/routing/client_editor_recovery_store.dart';
import 'package:milestone/app/routing/client_editor_route_registry.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/l10n/arb/app_localizations.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/add_client_form.dart';
import 'package:milestone/src/client/presentation/layout/client_route_success_mode.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';
import 'package:milestone/src/client/presentation/views/add_client_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestClientCubit extends Cubit<ClientState> implements ClientCubit {
  TestClientCubit(super.initialState);

  @override
  Future<void> addClient(Client client) async {}

  @override
  Future<void> bootstrapClientEdit(String clientId) async {}

  @override
  Future<void> deleteClient(String clientID) async {}

  @override
  Future<void> editClient({
    required String clientId,
    required Map<String, dynamic> updatedClient,
  }) async {}

  @override
  Future<void> getClientById(String clientId) async {}

  @override
  Future<void> getClientProjects({
    required String clientId,
    required bool detailed,
  }) async {}

  @override
  Future<void> getClients() async {}

  @override
  Future<void> getClientWorkspace(String clientId) async {}

  @override
  Future<void> getClientWorkspaceList() async {}

  @override
  Future<void> saveClientEdit({
    required String clientId,
    required Map<String, dynamic> updatedClient,
  }) async {}
}

void main() {
  late TestClientCubit clientCubit;
  late ClientEditorRouteSession session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    final prefs = await SharedPreferences.getInstance();
    sl
      ..registerLazySingleton(() => prefs)
      ..registerLazySingleton(() => ClientEditorRecoveryStore(prefs: sl()))
      ..registerLazySingleton(ClientEditorRouteRegistry.new);
  });

  tearDown(() async {
    await sl.reset();
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) {
            return Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => context.push(AddClientView.path),
                      child: const Text('Open Add Client'),
                    ),
                  ),
                );
              },
            );
          },
        ),
        GoRoute(
          path: AddClientView.path,
          builder: (_, _) {
            return Provider<ClientEditorRouteSession>.value(
              value: session,
              child: ChangeNotifierProvider(
                create: (_) => ClientFormController(),
                child: BlocProvider<ClientCubit>.value(
                  value: clientCubit,
                  child: const AddClientView(
                    successMode: AddClientRouteSuccessMode.goToClients(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> pumpRoute(
    WidgetTester tester, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: buildRouter(),
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.text('Open Add Client'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  ClientEditorRouteSession buildSession() {
    return ClientEditorRouteSession(
      sessionKey: 'session-1',
      mode: ClientEditorRouteMode.add,
      recoveryRecord: const ClientEditorRecoveryRecord(
        ownerUserId: 'user-1',
        operationId: 'operation-1',
        mode: ClientEditorRouteMode.add,
        sessionKey: 'session-1',
        clientId: 'client-1',
        targetLocation: '/clients',
        disposition: ClientEditorRecoveryDisposition.refreshClientList,
        addRecoveryClaimKey: 'claim-1',
        addSuccessMode: AddClientRouteSuccessMode.goToClients(),
        status: ClientEditorRecoveryStatus.draft,
      ),
      cubit: clientCubit,
      formController: ClientFormController(),
    );
  }

  testWidgets('shows a back affordance when the pushed route is idle', (
    tester,
  ) async {
    clientCubit = TestClientCubit(const ClientInitial());
    session = buildSession();

    await pumpRoute(tester);

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets(
    'blocks pop while create is in flight',
    (tester) async {
      clientCubit = TestClientCubit(const ClientLoading());
      session = buildSession();

      await pumpRoute(tester, settle: false);

      expect(find.byType(BackButton), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.byType(AddClientView), findsOneWidget);
    },
  );

  testWidgets('renders the sectioned add-client form', (tester) async {
    clientCubit = TestClientCubit(const ClientInitial());
    session = buildSession();

    await pumpRoute(tester);

    expect(find.text('Client basics'), findsOneWidget);
    expect(find.text('Financial context'), findsOneWidget);
    expect(find.byType(AddClientForm), findsOneWidget);
  });
}
