import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/routing/client_editor_recovery_store.dart';
import 'package:milestone/app/routing/client_editor_route_registry.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/layout/client_route_success_mode.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockClientCubit extends Mock implements ClientCubit {}

void main() {
  late ClientEditorRouteRegistry registry;
  late _MockClientCubit cubit;
  late ClientEditorRouteSession session;

  setUp(() {
    registry = ClientEditorRouteRegistry();
    cubit = _MockClientCubit();
    when(() => cubit.state).thenReturn(const ClientInitial());
    when(() => cubit.close()).thenAnswer((_) async {});
    session = ClientEditorRouteSession(
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
      cubit: cubit,
      formController: ClientFormController(),
    );
  });

  test('releaseAfterAllowedExit keeps session accessible until disposal', () {
    registry
      ..ensureSession(
        sessionKey: session.sessionKey,
        create: () => session,
      )
      ..releaseAfterAllowedExit(session.sessionKey);

    expect(registry.sessionFor(session.sessionKey), same(session));
  });

  test('detachAwaitingMutationOutcome keeps session accessible', () {
    registry
      ..ensureSession(
        sessionKey: session.sessionKey,
        create: () => session,
      )
      ..detachAwaitingMutationOutcome(session.sessionKey);

    expect(registry.sessionFor(session.sessionKey), same(session));
  });

  test('disposeDetachedOutcomeSession disposes the detached session', () async {
    registry
      ..ensureSession(
        sessionKey: session.sessionKey,
        create: () => session,
      )
      ..detachAwaitingMutationOutcome(session.sessionKey);

    await registry.disposeDetachedOutcomeSession(session.sessionKey);

    verify(() => cubit.close()).called(1);
  });
}
