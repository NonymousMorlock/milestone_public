import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/routing/milestone_editor_route_registry.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/add_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/delete_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/edit_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestone_by_id.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestones.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/reorder_milestone.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:milestone/src/project/features/milestone/presentation/providers/milestone_form_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockAddMilestone extends Mock implements AddMilestone {}

class MockDeleteMilestone extends Mock implements DeleteMilestone {}

class MockEditMilestone extends Mock implements EditMilestone {}

class MockReorderMilestone extends Mock implements ReorderMilestone {}

class MockGetMilestoneById extends Mock implements GetMilestoneById {}

class MockGetMilestones extends Mock implements GetMilestones {}

class TrackingMilestoneFormController extends MilestoneFormController {
  int disposeCount = 0;

  @override
  void dispose() {
    disposeCount += 1;
    super.dispose();
  }
}

void main() {
  late MilestoneEditorRouteRegistry registry;

  MilestoneCubit buildCubit() {
    return MilestoneCubit(
      addMilestone: MockAddMilestone(),
      deleteMilestone: MockDeleteMilestone(),
      editMilestone: MockEditMilestone(),
      reorderMilestone: MockReorderMilestone(),
      getMilestoneById: MockGetMilestoneById(),
      getMilestones: MockGetMilestones(),
    );
  }

  MilestoneEditorRouteSession buildSession(
    String sessionKey, {
    TrackingMilestoneFormController? formController,
  }) {
    return MilestoneEditorRouteSession(
      sessionKey: sessionKey,
      projectId: 'project-1',
      isEdit: false,
      cubit: buildCubit(),
      formController: formController ?? TrackingMilestoneFormController(),
    );
  }

  setUp(() {
    registry = MilestoneEditorRouteRegistry();
  });

  tearDown(() async {
    await registry.disposeAll();
  });

  test('ensureSession reuses the active session for the same key', () {
    final first = registry.ensureSession(
      sessionKey: 'session-1',
      create: () => buildSession('session-1'),
    );
    final second = registry.ensureSession(
      sessionKey: 'session-1',
      create: () => buildSession('session-1'),
    );

    expect(identical(first, second), isTrue);
    expect(registry.containsActiveSession('session-1'), isTrue);
    expect(registry.sessionFor('session-1'), same(first));
  });

  test('ensureSession creates a distinct session for a different key', () {
    final first = registry.ensureSession(
      sessionKey: 'session-1',
      create: () => buildSession('session-1'),
    );
    final second = registry.ensureSession(
      sessionKey: 'session-2',
      create: () => buildSession('session-2'),
    );

    expect(identical(first, second), isFalse);
    expect(registry.sessionFor('session-1'), same(first));
    expect(registry.sessionFor('session-2'), same(second));
  });

  test('releaseAfterAllowedExit removes the active entry immediately', () {
    final session = registry.ensureSession(
      sessionKey: 'session-1',
      create: () => buildSession('session-1'),
    );

    registry.releaseAfterAllowedExit('session-1');

    expect(registry.containsActiveSession('session-1'), isFalse);
    expect(registry.sessionFor('session-1'), same(session));
  });

  test('disposeSession disposes a released session once', () async {
    final formController = TrackingMilestoneFormController();
    final session = registry.ensureSession(
      sessionKey: 'session-1',
      create: () => buildSession(
        'session-1',
        formController: formController,
      ),
    );

    registry.releaseAfterAllowedExit('session-1');
    await registry.disposeSession('session-1');

    expect(registry.sessionFor('session-1'), isNull);
    expect(session.cubit.isClosed, isTrue);
    expect(formController.disposeCount, 1);
  });

  test('duplicate releaseAfterAllowedExit is harmless', () async {
    final formController = TrackingMilestoneFormController();
    final session = registry.ensureSession(
      sessionKey: 'session-1',
      create: () => buildSession(
        'session-1',
        formController: formController,
      ),
    );

    registry
      ..releaseAfterAllowedExit('session-1')
      ..releaseAfterAllowedExit('session-1');
    await registry.disposeSession('session-1');
    await registry.disposeSession('session-1');

    expect(registry.sessionFor('session-1'), isNull);
    expect(session.cubit.isClosed, isTrue);
    expect(formController.disposeCount, 1);
  });
}
