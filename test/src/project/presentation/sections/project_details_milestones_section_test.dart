import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:milestone/app/routing/router.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone_collection_snapshot.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:milestone/src/project/features/milestone/presentation/widgets/milestone_entry.dart';
import 'package:milestone/src/project/presentation/sections/project_details_milestones_section.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockMilestoneCubit extends MockCubit<MilestoneState>
    implements MilestoneCubit {}

void main() {
  late MockMilestoneCubit milestoneCubit;
  late StreamController<MilestoneState> stateController;

  final tMilestones = [
    MilestoneModel.empty().copyWith(
      id: 'milestone-1',
      projectId: 'project-1',
      title: 'Discovery',
      rank: 0,
    ),
    MilestoneModel.empty().copyWith(
      id: 'milestone-2',
      projectId: 'project-1',
      title: 'Build',
      rank: 1024,
    ),
    MilestoneModel.empty().copyWith(
      id: 'milestone-3',
      projectId: 'project-1',
      title: 'Launch',
      rank: 2048,
    ),
  ];
  final tSnapshot = MilestoneCollectionSnapshot(
    milestones: tMilestones,
    orderVersion: 7,
  );
  final tInitialState = MilestoneState(
    collection: MilestoneCollectionSuccess(tSnapshot),
  );

  setUp(() {
    milestoneCubit = MockMilestoneCubit();
    stateController = StreamController<MilestoneState>();
    when(() => milestoneCubit.state).thenReturn(tInitialState);
    whenListen(
      milestoneCubit,
      stateController.stream,
      initialState: tInitialState,
    );
    when(() => milestoneCubit.getMilestones(any())).thenAnswer((_) async {});
    when(
      () => milestoneCubit.reorderMilestone(
        projectId: any(named: 'projectId'),
        milestoneId: any(named: 'milestoneId'),
        previousMilestoneId: any(named: 'previousMilestoneId'),
        nextMilestoneId: any(named: 'nextMilestoneId'),
        expectedOrderVersion: any(named: 'expectedOrderVersion'),
      ),
    ).thenAnswer((_) async {});
    when(() => milestoneCubit.clearMutationFeedback()).thenReturn(null);
  });

  tearDown(() async {
    await stateController.close();
  });

  Future<void> pumpSection(WidgetTester tester) async {
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
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          theme: AppTheme.lightTheme,
          home: BlocProvider<MilestoneCubit>.value(
            value: milestoneCubit,
            child: const Scaffold(
              body: ProjectDetailsMilestonesSection(
                projectId: 'project-1',
                projectName: 'Northwind Portal',
              ),
            ),
          ),
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

  List<String> visibleTitles(WidgetTester tester) {
    return tester
        .widgetList<MilestoneEntry>(find.byType(MilestoneEntry))
        .map((entry) => entry.milestone.title)
        .toList();
  }

  testWidgets('drag reorder computes target anchors from the visible list', (
    tester,
  ) async {
    await pumpSection(tester);

    final listView = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    listView.onReorder(2, 1);
    await tester.pump();

    verify(
      () => milestoneCubit.reorderMilestone(
        projectId: 'project-1',
        milestoneId: 'milestone-3',
        previousMilestoneId: 'milestone-1',
        nextMilestoneId: 'milestone-2',
        expectedOrderVersion: 7,
      ),
    ).called(1);
  });

  testWidgets('same-position drag does not dispatch a reorder mutation', (
    tester,
  ) async {
    await pumpSection(tester);

    final listView = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    listView.onReorder(1, 2);
    await tester.pump();

    verifyNever(
      () => milestoneCubit.reorderMilestone(
        projectId: any(named: 'projectId'),
        milestoneId: any(named: 'milestoneId'),
        previousMilestoneId: any(named: 'previousMilestoneId'),
        nextMilestoneId: any(named: 'nextMilestoneId'),
        expectedOrderVersion: any(named: 'expectedOrderVersion'),
      ),
    );
  });

  testWidgets(
    'reorder failure rolls the local list back to the last server order',
    (
      tester,
    ) async {
      await pumpSection(tester);

      final listView = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      listView.onReorder(2, 1);
      await tester.pump();

      expect(visibleTitles(tester), ['Discovery', 'Launch', 'Build']);

      stateController.add(
        MilestoneState(
          collection: MilestoneCollectionSuccess(tSnapshot),
          mutation: const MilestoneMutationFailure(
            type: MilestoneMutationType.reorder,
            affectedMilestoneId: 'milestone-3',
            title: 'Error Reordering Milestone',
            message: '[permission-denied] Reorder failed',
            statusCode: 'permission-denied',
          ),
        ),
      );
      await tester.pump();

      expect(visibleTitles(tester), ['Discovery', 'Build', 'Launch']);
      verify(() => milestoneCubit.clearMutationFeedback()).called(1);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    },
  );

  testWidgets(
    'reorder success is consumed once even when a collection refresh follows',
    (tester) async {
      await pumpSection(tester);

      stateController.add(
        MilestoneState(
          collection: MilestoneCollectionSuccess(tSnapshot),
          mutation: const MilestoneMutationSuccess(
            type: MilestoneMutationType.reorder,
            affectedMilestoneId: 'milestone-3',
          ),
        ),
      );
      await tester.pump();

      stateController.add(
        MilestoneState(
          collection: MilestoneCollectionLoading(previous: tSnapshot),
          mutation: const MilestoneMutationSuccess(
            type: MilestoneMutationType.reorder,
            affectedMilestoneId: 'milestone-3',
          ),
        ),
      );
      await tester.pump();

      verify(() => milestoneCubit.clearMutationFeedback()).called(2);
      verify(() => milestoneCubit.getMilestones('project-1')).called(3);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    },
  );
}
