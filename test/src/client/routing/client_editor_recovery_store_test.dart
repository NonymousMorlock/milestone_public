import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/routing/client_editor_recovery_store.dart';
import 'package:milestone/src/client/presentation/layout/client_route_success_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ClientEditorRecoveryStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = ClientEditorRecoveryStore(prefs: prefs);
  });

  test('add draft reuses reserved client id when reclaimed by claim key', () {
    final initial = store.ensureAddDraftForRouteEntry(
      ownerUserId: 'user-1',
      sessionKey: 'session-1',
      successMode: const AddClientRouteSuccessMode.goToClients(),
    );

    final rebound = store.ensureAddDraftForRouteEntry(
      ownerUserId: 'user-1',
      sessionKey: 'session-2',
      successMode: const AddClientRouteSuccessMode.goToClients(),
    );

    expect(rebound.clientId, initial.clientId);
    expect(rebound.sessionKey, 'session-2');
  });

  test('committed lookup is scoped to owner and target', () async {
    final record = store.ensureEditDraft(
      ownerUserId: 'user-1',
      sessionKey: 'session-1',
      clientId: 'client-1',
      successMode: const EditClientRouteSuccessMode.returnUpdatedFlag(
        recoveryTargetLocation: '/clients/client-1',
      ),
    );

    await store.markCommitted(
      ownerUserId: 'user-1',
      operationId: record.operationId,
    );

    expect(
      store.readCommittedForTarget(
        ownerUserId: 'user-1',
        targetLocation: '/clients/client-1',
      ),
      isNotNull,
    );
    expect(
      store.readCommittedForTarget(
        ownerUserId: 'user-2',
        targetLocation: '/clients/client-1',
      ),
      isNull,
    );
  });

  test('clearForSession removes draft recovery', () async {
    final record = store.ensureEditDraft(
      ownerUserId: 'user-1',
      sessionKey: 'session-1',
      clientId: 'client-1',
      successMode: const EditClientRouteSuccessMode.returnUpdatedFlag(
        recoveryTargetLocation: '/clients/client-1',
      ),
    );

    await store.clearForSession(
      ownerUserId: 'user-1',
      sessionKey: 'session-1',
    );

    expect(
      store.readBySession(ownerUserId: 'user-1', sessionKey: 'session-1'),
      isNull,
    );
    expect(
      store.readCommittedForTarget(
        ownerUserId: 'user-1',
        targetLocation: record.targetLocation,
      ),
      isNull,
    );
  });
}
