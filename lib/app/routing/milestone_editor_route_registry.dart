import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:milestone/src/project/features/milestone/presentation/providers/milestone_form_controller.dart';

class MilestoneEditorRouteSession {
  MilestoneEditorRouteSession({
    required this.sessionKey,
    required this.projectId,
    required this.isEdit,
    required this.cubit,
    required this.formController,
    this.milestoneId,
  });

  final String sessionKey;
  final String projectId;
  final bool isEdit;
  final String? milestoneId;
  final MilestoneCubit cubit;
  final MilestoneFormController formController;

  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    await cubit.close();
    formController.dispose();
  }
}

class MilestoneEditorRouteRegistry {
  final Map<String, MilestoneEditorRouteSession> _active = {};
  final Map<String, MilestoneEditorRouteSession> _pendingDisposal = {};

  MilestoneEditorRouteSession ensureSession({
    required String sessionKey,
    required MilestoneEditorRouteSession Function() create,
  }) {
    return _active.putIfAbsent(sessionKey, create);
  }

  MilestoneEditorRouteSession? sessionFor(String sessionKey) {
    return _active[sessionKey] ?? _pendingDisposal[sessionKey];
  }

  bool containsActiveSession(String sessionKey) {
    return _active.containsKey(sessionKey);
  }

  void releaseAfterAllowedExit(String sessionKey) {
    final session = _active.remove(sessionKey);
    if (session == null) {
      return;
    }

    _pendingDisposal[sessionKey] = session;
  }

  Future<void> disposeSession(String sessionKey) async {
    final session =
        _pendingDisposal.remove(sessionKey) ?? _active.remove(sessionKey);
    await session?.dispose();
  }

  Future<void> disposeAll() async {
    final sessions = [
      ..._active.values,
      ..._pendingDisposal.values,
    ];

    _active.clear();
    _pendingDisposal.clear();

    for (final session in sessions) {
      await session.dispose();
    }
  }
}
