import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/app/routing/milestone_editor_route_registry.dart';
import 'package:milestone/app/routing/milestone_editor_route_session_host.dart';
import 'package:milestone/app/routing/router.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/l10n/arb/app_localizations.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/add_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/delete_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/edit_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestone_by_id.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestones.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/reorder_milestone.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:milestone/src/project/features/milestone/presentation/providers/milestone_form_controller.dart';
import 'package:milestone/src/project/features/milestone/presentation/views/add_or_edit_milestone_view.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAddMilestone extends Mock implements AddMilestone {}

class MockDeleteMilestone extends Mock implements DeleteMilestone {}

class MockEditMilestone extends Mock implements EditMilestone {}

class MockReorderMilestone extends Mock implements ReorderMilestone {}

class MockGetMilestoneById extends Mock implements GetMilestoneById {}

class MockGetMilestones extends Mock implements GetMilestones {}

class MilestoneRouteLauncher extends StatefulWidget {
  const MilestoneRouteLauncher({
    required this.isEdit,
    this.seedMilestone,
    super.key,
  });

  final bool isEdit;
  final Milestone? seedMilestone;

  @override
  State<MilestoneRouteLauncher> createState() => _MilestoneRouteLauncherState();
}

class _MilestoneRouteLauncherState extends State<MilestoneRouteLauncher> {
  String _result = 'none';

  Future<void> _openRoute() async {
    final result = widget.isEdit
        ? await context.push<MilestoneRouteResult>(
            AppRoutes.editProjectMilestone(
              projectId: 'project-1',
              milestoneId: 'milestone-1',
            ),
            extra: widget.seedMilestone,
          )
        : await context.push<MilestoneRouteResult>(
            AppRoutes.addProjectMilestone(projectId: 'project-1'),
          );
    if (!mounted) {
      return;
    }

    setState(() {
      _result = result?.name ?? 'none';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _openRoute,
              child: Text(
                widget.isEdit ? 'Open Edit Route' : 'Open Add Route',
              ),
            ),
            Text('Result: $_result'),
          ],
        ),
      ),
    );
  }
}

void main() {
  late MockAddMilestone addMilestone;
  late MockDeleteMilestone deleteMilestone;
  late MockEditMilestone editMilestone;
  late MockReorderMilestone reorderMilestone;
  late MockGetMilestoneById getMilestoneById;
  late MockGetMilestones getMilestones;
  late MilestoneCubit milestoneCubit;
  late MilestoneEditorRouteRegistry registry;
  late String? lastSessionKey;
  late bool signedInToMilestoneEditor;

  final tMilestone = MilestoneModel.empty().copyWith(
    id: 'milestone-1',
    projectId: 'project-1',
    title: 'Discovery',
    notes: const ['Seed note'],
  );

  setUpAll(() {
    registerFallbackValue(tMilestone);
    registerFallbackValue(const DeleteMilestoneParams.empty());
    registerFallbackValue(EditMilestoneParams.empty());
    registerFallbackValue(const GetMilestoneByIdParams.empty());
  });

  setUp(() {
    addMilestone = MockAddMilestone();
    deleteMilestone = MockDeleteMilestone();
    editMilestone = MockEditMilestone();
    reorderMilestone = MockReorderMilestone();
    getMilestoneById = MockGetMilestoneById();
    getMilestones = MockGetMilestones();
    milestoneCubit = MilestoneCubit(
      addMilestone: addMilestone,
      deleteMilestone: deleteMilestone,
      editMilestone: editMilestone,
      reorderMilestone: reorderMilestone,
      getMilestoneById: getMilestoneById,
      getMilestones: getMilestones,
    );
    registry = MilestoneEditorRouteRegistry();
    lastSessionKey = null;
    signedInToMilestoneEditor = true;
  });

  tearDown(() async {
    await registry.disposeAll();
  });

  Future<void> pumpRouter(
    WidgetTester tester, {
    required GoRouter router,
  }) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final toast = FToast();
    await tester.pumpWidget(
      Provider<FToast>.value(
        value: toast,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            toast.init(context);
            return FToastBuilder()(context, child);
          },
        ),
      ),
    );
    await tester.pump();
    if (rootNavigatorKey.currentContext case final overlayContext?) {
      toast.init(overlayContext);
    }
    await tester.pumpAndSettle();
  }

  String sessionKeyForState(GoRouterState state) => state.pageKey.value;

  MilestoneEditorRouteSession ensureSession({
    required GoRouterState state,
    required String projectId,
    required bool isEdit,
    String? milestoneId,
  }) {
    final sessionKey = sessionKeyForState(state);
    lastSessionKey = sessionKey;
    return registry.ensureSession(
      sessionKey: sessionKey,
      create: () {
        return MilestoneEditorRouteSession(
          sessionKey: sessionKey,
          projectId: projectId,
          isEdit: isEdit,
          milestoneId: milestoneId,
          cubit: milestoneCubit,
          formController: MilestoneFormController(),
        );
      },
    );
  }

  FutureOr<bool> handleExit(BuildContext _, GoRouterState state) {
    final sessionKey = sessionKeyForState(state);
    final session = registry.sessionFor(sessionKey);
    if (session == null) {
      return true;
    }

    if (!signedInToMilestoneEditor) {
      registry.releaseAfterAllowedExit(sessionKey);
      return true;
    }

    if (session.cubit.state.isMutating) {
      CoreUtils.showSnackBar(
        title: 'Milestone save in progress',
        message: 'Please wait for the milestone save to finish.',
        logLevel: LogLevel.warning,
      );
      return false;
    }

    registry.releaseAfterAllowedExit(sessionKey);
    return true;
  }

  GoRouter buildRouter({
    required Widget home,
    required String initialLocation,
  }) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => home,
        ),
        GoRoute(
          path: '/projects/:projectId',
          builder: (_, state) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Project page: ${state.pathParameters['projectId']}',
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/projects/:projectId/add-milestone',
          onExit: handleExit,
          pageBuilder: (_, state) {
            final session = ensureSession(
              state: state,
              projectId: state.pathParameters['projectId']!,
              isEdit: false,
            );
            return MaterialPage<void>(
              key: state.pageKey,
              child: MilestoneEditorRouteSessionHost(
                registry: registry,
                sessionKey: session.sessionKey,
                child: ChangeNotifierProvider<MilestoneFormController>.value(
                  value: session.formController,
                  child: BlocProvider<MilestoneCubit>.value(
                    value: session.cubit,
                    child: AddOrEditMilestoneView.add(
                      projectId: state.pathParameters['projectId']!,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/projects/:projectId/milestones/:milestoneId/edit',
          onExit: handleExit,
          pageBuilder: (_, state) {
            final session = ensureSession(
              state: state,
              projectId: state.pathParameters['projectId']!,
              milestoneId: state.pathParameters['milestoneId'],
              isEdit: true,
            );
            return MaterialPage<void>(
              key: state.pageKey,
              child: MilestoneEditorRouteSessionHost(
                registry: registry,
                sessionKey: session.sessionKey,
                child: ChangeNotifierProvider<MilestoneFormController>.value(
                  value: session.formController,
                  child: BlocProvider<MilestoneCubit>.value(
                    value: session.cubit,
                    child: AddOrEditMilestoneView.edit(
                      projectId: state.pathParameters['projectId']!,
                      milestoneId: state.pathParameters['milestoneId'],
                      seedMilestone: state.extra as Milestone?,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  testWidgets('add success pops a typed added result and cleans the session', (
    tester,
  ) async {
    when(() => addMilestone(any())).thenAnswer((_) async => const Right(null));

    await pumpRouter(
      tester,
      router: buildRouter(
        home: const MilestoneRouteLauncher(isEdit: false),
        initialLocation: '/',
      ),
    );

    await tester.tap(find.text('Open Add Route'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Draft milestone');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Milestone'));
    await tester.pumpAndSettle();

    expect(find.text('Result: added'), findsOneWidget);
    expect(lastSessionKey, isNotNull);
    expect(registry.containsActiveSession(lastSessionKey!), isFalse);
    expect(registry.sessionFor(lastSessionKey!), isNull);
    verify(() => addMilestone(any())).called(1);
  });

  testWidgets('edit route bootstraps by id before becoming interactive', (
    tester,
  ) async {
    when(
      () => getMilestoneById(any()),
    ).thenAnswer((_) async => Right(tMilestone));
    when(() => editMilestone(any())).thenAnswer((_) async => const Right(null));

    await pumpRouter(
      tester,
      router: buildRouter(
        home: const MilestoneRouteLauncher(isEdit: true),
        initialLocation: '/',
      ),
    );

    await tester.tap(find.text('Open Edit Route'));
    await tester.pumpAndSettle();
    expect(find.text('Discovery'), findsOneWidget);

    verify(() => getMilestoneById(any())).called(1);
    expect(
      find.widgetWithText(FilledButton, 'Update Milestone'),
      findsOneWidget,
    );
  });

  testWidgets(
    'direct entry success falls back to the project page'
    ' when there is no route to pop',
    (tester) async {
      when(
        () => addMilestone(any()),
      ).thenAnswer((_) async => const Right(null));

      await pumpRouter(
        tester,
        router: buildRouter(
          home: const SizedBox.shrink(),
          initialLocation: AppRoutes.addProjectMilestone(
            projectId: 'project-1',
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Direct route');
      await tester.tap(find.widgetWithText(FilledButton, 'Add Milestone'));
      await tester.pumpAndSettle();

      expect(find.text('Project page: project-1'), findsOneWidget);
    },
  );

  testWidgets('handlePopRoute is blocked while submit is in flight', (
    tester,
  ) async {
    final completer = Completer<Either<Failure, void>>();
    when(() => addMilestone(any())).thenAnswer((_) => completer.future);

    await pumpRouter(
      tester,
      router: buildRouter(
        home: const MilestoneRouteLauncher(isEdit: false),
        initialLocation: '/',
      ),
    );

    await tester.tap(find.text('Open Add Route'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Pending save');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Milestone'));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AddOrEditMilestoneView), findsOneWidget);
    expect(find.text('Milestone save in progress'), findsOneWidget);
    expect(
      find.text('Please wait for the milestone save to finish.'),
      findsOneWidget,
    );

    completer.complete(const Right(null));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
    'route back button is blocked while submit is in flight with feedback',
    (tester) async {
      final completer = Completer<Either<Failure, void>>();
      when(() => addMilestone(any())).thenAnswer((_) => completer.future);

      await pumpRouter(
        tester,
        router: buildRouter(
          home: const MilestoneRouteLauncher(isEdit: false),
          initialLocation: '/',
        ),
      );

      await tester.tap(find.text('Open Add Route'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Pending save');
      await tester.tap(find.widgetWithText(FilledButton, 'Add Milestone'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AddOrEditMilestoneView), findsOneWidget);
      expect(find.text('Milestone save in progress'), findsOneWidget);
      expect(
        find.text('Please wait for the milestone save to finish.'),
        findsOneWidget,
      );

      completer.complete(const Right(null));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('preserves draft values when submit fails', (tester) async {
    const failure = ServerFailure(
      message: 'Permission denied',
      statusCode: 'permission-denied',
    );
    when(
      () => addMilestone(any()),
    ).thenAnswer((_) async => const Left(failure));

    await pumpRouter(
      tester,
      router: buildRouter(
        home: const MilestoneRouteLauncher(isEdit: false),
        initialLocation: '/',
      ),
    );

    await tester.tap(find.text('Open Add Route'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Draft milestone');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Milestone'));
    await tester.pumpAndSettle();

    expect(find.byType(AddOrEditMilestoneView), findsOneWidget);
    expect(find.text('Draft milestone'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
