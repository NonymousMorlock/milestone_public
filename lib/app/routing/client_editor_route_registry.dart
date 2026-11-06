import 'package:milestone/app/routing/client_editor_recovery_store.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';

class ClientEditorRouteSession {
  ClientEditorRouteSession({
    required this.sessionKey,
    required this.mode,
    required this.recoveryRecord,
    required this.cubit,
    required this.formController,
    this.clientId,
  });

  final String sessionKey;
  final ClientEditorRouteMode mode;
  final String? clientId;
  final ClientEditorRecoveryRecord recoveryRecord;
  final ClientCubit cubit;
  final ClientFormController formController;

  bool _disposed = false;

  bool get isMutating => switch (mode) {
    ClientEditorRouteMode.add => cubit.state is ClientLoading,
    ClientEditorRouteMode.edit => switch (cubit.state) {
      ClientEditLoaded(:final isSaving) => isSaving,
      _ => false,
    },
  };

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    await cubit.close();
    formController.dispose();
  }
}

class ClientEditorRouteRegistry {
  final Map<String, ClientEditorRouteSession> _active = {};
  final Map<String, ClientEditorRouteSession> _pendingDisposal = {};
  final Map<String, ClientEditorRouteSession> _detachedAwaitingOutcome = {};

  ClientEditorRouteSession ensureSession({
    required String sessionKey,
    required ClientEditorRouteSession Function() create,
  }) {
    return _active.putIfAbsent(sessionKey, create);
  }

  ClientEditorRouteSession? sessionFor(String sessionKey) {
    return _active[sessionKey] ??
        _pendingDisposal[sessionKey] ??
        _detachedAwaitingOutcome[sessionKey];
  }

  void releaseAfterAllowedExit(String sessionKey) {
    final session = _active.remove(sessionKey);
    if (session == null) {
      return;
    }

    _pendingDisposal[sessionKey] = session;
  }

  void detachAwaitingMutationOutcome(String sessionKey) {
    final session = _active.remove(sessionKey);
    if (session == null) {
      return;
    }

    _detachedAwaitingOutcome[sessionKey] = session;
  }

  Future<void> handleRouteHostDispose(String sessionKey) async {
    final pending = _pendingDisposal.remove(sessionKey);
    if (pending != null) {
      await pending.dispose();
      return;
    }

    if (_detachedAwaitingOutcome.containsKey(sessionKey)) {
      return;
    }

    final active = _active.remove(sessionKey);
    await active?.dispose();
  }

  Future<void> disposeDetachedOutcomeSession(String sessionKey) async {
    final detached = _detachedAwaitingOutcome.remove(sessionKey);
    await detached?.dispose();
  }

  Future<void> disposeAll() async {
    final sessions = [
      ..._active.values,
      ..._pendingDisposal.values,
      ..._detachedAwaitingOutcome.values,
    ];

    _active.clear();
    _pendingDisposal.clear();
    _detachedAwaitingOutcome.clear();

    for (final session in sessions) {
      await session.dispose();
    }
  }
}
