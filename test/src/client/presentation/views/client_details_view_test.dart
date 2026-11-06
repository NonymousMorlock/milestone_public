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
import 'package:milestone/src/client/presentation/views/client_details_view.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
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
        child: const ClientDetailsView(clientId: 'client-1'),
      ),
    );
  }

  testWidgets('renders linked projects for a loaded client workspace', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        ClientWorkspaceLoaded(
          snapshot: const ClientWorkspaceSnapshotLayout(
            clientId: 'client-1',
            clientName: 'Acme',
            totalSpent: 1200,
            projectCount: 1,
          ),
          projects: [ProjectModel.empty().copyWith(projectName: 'Website')],
          isDeleting: false,
          isRefreshing: false,
        ),
      ),
    );

    expect(find.text('Website'), findsOneWidget);
  });

  testWidgets('renders the no-projects state when no linked projects exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const ClientWorkspaceLoaded(
          snapshot: ClientWorkspaceSnapshotLayout(
            clientId: 'client-1',
            clientName: 'Acme',
            totalSpent: 1200,
            projectCount: 0,
          ),
          projects: [],
          isDeleting: false,
          isRefreshing: false,
        ),
      ),
    );

    expect(find.text('No projects for this client yet.'), findsOneWidget);
  });

  testWidgets('disables edit and delete while refresh is in flight', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const ClientWorkspaceLoaded(
          snapshot: ClientWorkspaceSnapshotLayout(
            clientId: 'client-1',
            clientName: 'Acme',
            totalSpent: 1200,
            projectCount: 0,
          ),
          projects: [],
          isDeleting: false,
          isRefreshing: true,
        ),
      ),
    );

    final editButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Edit Client'),
    );
    final deleteButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Delete Client'),
    );

    expect(editButton.onPressed, isNull);
    expect(deleteButton.onPressed, isNull);
  });
}
