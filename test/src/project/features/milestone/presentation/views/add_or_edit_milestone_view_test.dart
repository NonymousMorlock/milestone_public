import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/l10n/arb/app_localizations.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:milestone/src/project/features/milestone/presentation/providers/milestone_form_controller.dart';
import 'package:milestone/src/project/features/milestone/presentation/views/add_or_edit_milestone_view.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockProjectBloc extends MockBloc<ProjectEvent, ProjectState>
    implements ProjectBloc {}

class MockMilestoneCubit extends MockCubit<MilestoneState>
    implements MilestoneCubit {}

void main() {
  late MockProjectBloc projectBloc;
  late MockMilestoneCubit milestoneCubit;

  Widget buildSubject() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) {
            return ChangeNotifierProvider(
              create: (_) => MilestoneFormController(),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<ProjectBloc>.value(value: projectBloc),
                  BlocProvider<MilestoneCubit>.value(value: milestoneCubit),
                ],
                child: const AddOrEditMilestoneView.add(projectId: 'project-1'),
              ),
            );
          },
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  setUpAll(() {
    registerFallbackValue(const GetProjectByIdEvent('fallback'));
  });

  setUp(() {
    projectBloc = MockProjectBloc();
    milestoneCubit = MockMilestoneCubit();
    when(() => projectBloc.add(any())).thenReturn(null);
    when(() => milestoneCubit.state).thenReturn(const MilestoneState());
    whenListen(
      milestoneCubit,
      const Stream<MilestoneState>.empty(),
      initialState: const MilestoneState(),
    );
  });

  testWidgets('blocks the route when the parent project is pending deletion', (
    tester,
  ) async {
    final pendingProject = ProjectModel.empty().copyWith(
      id: 'project-1',
      projectName: 'Northwind Portal',
      deletionRequestedAt: DateTime(2024, 1, 2),
    );
    when(() => projectBloc.state).thenReturn(ProjectLoaded(pendingProject));
    whenListen(
      projectBloc,
      const Stream<ProjectState>.empty(),
      initialState: ProjectLoaded(pendingProject),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Project deletion in progress'), findsOneWidget);
    expect(find.text('Finish Delete'), findsOneWidget);
  });
}
