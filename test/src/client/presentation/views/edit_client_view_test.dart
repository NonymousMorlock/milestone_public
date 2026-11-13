import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/app/routing/client_editor_recovery_store.dart';
import 'package:milestone/app/routing/client_editor_route_registry.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/l10n/arb/app_localizations.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/layout/client_route_success_mode.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';
import 'package:milestone/src/client/presentation/views/edit_client_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestClientCubit extends Cubit<ClientState> implements ClientCubit {
  _TestClientCubit(super.initialState);

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
  late _TestClientCubit clientCubit;
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

  Widget buildSubject(ClientState state) {
    clientCubit = _TestClientCubit(state);
    session = ClientEditorRouteSession(
      sessionKey: 'session-1',
      mode: ClientEditorRouteMode.edit,
      recoveryRecord: const ClientEditorRecoveryRecord(
        ownerUserId: 'user-1',
        operationId: 'operation-1',
        mode: ClientEditorRouteMode.edit,
        sessionKey: 'session-1',
        clientId: 'client-1',
        targetLocation: '/clients/client-1',
        disposition: ClientEditorRecoveryDisposition.refreshClientDetail,
        editSuccessMode: EditClientRouteSuccessMode.returnUpdatedFlag(
          recoveryTargetLocation: '/clients/client-1',
        ),
        status: ClientEditorRecoveryStatus.draft,
      ),
      cubit: clientCubit,
      formController: ClientFormController(),
    );

    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Provider<ClientEditorRouteSession>.value(
        value: session,
        child: ChangeNotifierProvider(
          create: (_) => ClientFormController(),
          child: BlocProvider<ClientCubit>.value(
            value: clientCubit,
            child: const EditClientView(
              clientId: 'client-1',
              successMode: EditClientRouteSuccessMode.returnUpdatedFlag(
                recoveryTargetLocation: '/clients/client-1',
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the seeded edit form', (tester) async {
    final client = Client(
      id: 'client-1',
      name: 'Acme',
      totalSpent: 1200,
      dateCreated: DateTime(2024),
    );

    await tester.pumpWidget(
      buildSubject(
        ClientEditLoaded(client: client, isSaving: false),
      ),
    );
    await tester.pump();

    expect(find.text('Save Client'), findsOneWidget);
    expect(find.textContaining('create-only'), findsOneWidget);
  });

  testWidgets('renders not-found bootstrap state', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const ClientError(
          title: 'Error Fetching Client',
          message: 'missing',
          statusCode: 'CLIENT_NOT_FOUND',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Client unavailable'), findsOneWidget);
  });
}
