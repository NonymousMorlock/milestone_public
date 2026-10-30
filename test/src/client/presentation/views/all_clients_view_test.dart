import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/app/routing/client_editor_recovery_store.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/l10n/arb/app_localizations.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/layout/client_workspace_snapshot_layout.dart';
import 'package:milestone/src/client/presentation/views/all_clients_view.dart';
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    final prefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => ClientEditorRecoveryStore(prefs: prefs));
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildSubject(ClientState state) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<ClientCubit>.value(
        value: _TestClientCubit(state),
        child: const AllClientsView(),
      ),
    );
  }

  testWidgets('renders the empty state when no client summaries exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(const ClientWorkspaceListLoaded([])),
    );

    expect(find.text('No clients yet.'), findsOneWidget);
  });

  testWidgets('renders loaded client summaries', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const ClientWorkspaceListLoaded([
          ClientWorkspaceSnapshotLayout(
            clientId: 'client-1',
            clientName: 'Acme',
            totalSpent: 1200,
            projectCount: 2,
          ),
        ]),
      ),
    );

    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('2 linked projects'), findsOneWidget);
  });
}
