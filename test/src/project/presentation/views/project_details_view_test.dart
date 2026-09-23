import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/routing/router.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/l10n/arb/app_localizations.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone_collection_snapshot.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/add_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/delete_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/edit_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestone_by_id.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestones.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/reorder_milestone.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/views/project_details_view.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockProjectBloc extends MockBloc<ProjectEvent, ProjectState>
    implements ProjectBloc {}

class MockAddMilestone extends Mock implements AddMilestone {}

class MockDeleteMilestone extends Mock implements DeleteMilestone {}

class MockEditMilestone extends Mock implements EditMilestone {}

class MockReorderMilestone extends Mock implements ReorderMilestone {}

class MockGetMilestoneById extends Mock implements GetMilestoneById {}

class MockGetMilestones extends Mock implements GetMilestones {}

void main() {
  late MockProjectBloc projectBloc;
  late MilestoneCubit milestoneCubit;
  late ProjectModel project;

  setUpAll(() {
    registerFallbackValue(const GetProjectByIdEvent('fallback'));
  });

  setUp(() {
    projectBloc = MockProjectBloc();
    when(() => projectBloc.add(any())).thenReturn(null);
    final addMilestone = MockAddMilestone();
    final deleteMilestone = MockDeleteMilestone();
    final editMilestone = MockEditMilestone();
    final reorderMilestone = MockReorderMilestone();
    final getMilestoneById = MockGetMilestoneById();
    final getMilestones = MockGetMilestones();
    when(() => getMilestones(any())).thenAnswer(
      (_) async => const Right(
        MilestoneCollectionSnapshot(milestones: [], orderVersion: 0),
      ),
    );
    milestoneCubit = MilestoneCubit(
      addMilestone: addMilestone,
      deleteMilestone: deleteMilestone,
      editMilestone: editMilestone,
      reorderMilestone: reorderMilestone,
      getMilestoneById: getMilestoneById,
      getMilestones: getMilestones,
    );
    project = ProjectModel.empty().copyWith(
      id: 'project-1',
      projectName: 'Northwind Portal',
      clientName: 'Northwind',
      urls: const [],
      notes: const [],
      images: const [],
      featureImageStoragePath: 'projects/user/project-1/feature_image',
      ownedStoragePaths: const ['projects/user/project-1/feature_image'],
    );
  });

  Future<void> pumpDetailsView(
    WidgetTester tester, {
    required Stream<ProjectState> projectStates,
    required ProjectState initialState,
    bool settle = true,
  }) async {
    when(() => projectBloc.state).thenReturn(initialState);
    whenListen(
      projectBloc,
      projectStates,
      initialState: initialState,
    );

    final toast = FToast();
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) {
            return ChangeNotifierProvider(
              create: (_) => ProjectFormController(),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<ProjectBloc>.value(value: projectBloc),
                  BlocProvider<MilestoneCubit>.value(value: milestoneCubit),
                ],
                child: const ProjectDetailsView(projectId: 'project-1'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/projects',
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/projects/:projectId/edit',
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );

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
    if (settle) {
      await tester.pumpAndSettle();
    }
  }

  testWidgets('renders operations-first section titles and delete action', (
    tester,
  ) async {
    await pumpDetailsView(
      tester,
      initialState: const ProjectInitial(),
      projectStates: Stream<ProjectState>.fromIterable([
        ProjectLoaded(project),
      ]),
    );

    expect(find.text('Edit Project'), findsOneWidget);
    expect(find.text('Delete Project'), findsOneWidget);
    expect(find.text('Workspace header'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Schedule and status'), findsOneWidget);
    expect(find.text('Descriptions'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Links'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Milestones'), findsNWidgets(2));
  });

  testWidgets('renders the blocking pending-delete component', (tester) async {
    await pumpDetailsView(
      tester,
      initialState: const ProjectInitial(),
      projectStates: Stream<ProjectState>.fromIterable([
        ProjectLoaded(
          project.copyWith(deletionRequestedAt: DateTime(2024, 1, 2)),
        ),
      ]),
    );

    expect(find.text('Project deletion in progress'), findsOneWidget);
    expect(find.text('Finish Delete'), findsOneWidget);
    expect(find.text('Back to Projects'), findsOneWidget);
    expect(find.text('Finance'), findsNothing);
  });

  testWidgets(
    'keeps the last loaded project visible when a refresh fails after mutation',
    (tester) async {
      final states = StreamController<ProjectState>();

      await pumpDetailsView(
        tester,
        initialState: const ProjectInitial(),
        projectStates: states.stream,
        settle: false,
      );

      states.add(ProjectLoaded(project));
      await tester.pump();
      states.add(const ProjectLoading());
      await tester.pump();
      states.add(
        const ProjectError(
          title: 'Error Fetching Project',
          message: 'Network timeout',
          statusCode: 'timeout',
        ),
      );
      await tester.pump();

      expect(find.text('Northwind Portal'), findsWidgets);
      expect(
        find.text(
          'Showing last confirmed project data while the latest refresh is'
          ' retried.',
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 6));
      await states.close();
    },
  );
}
