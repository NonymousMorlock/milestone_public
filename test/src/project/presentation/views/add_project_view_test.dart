import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/l10n/arb/app_localizations.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/views/add_or_edit_project_view.dart';
import 'package:milestone/src/project/presentation/widgets/add_or_edit_project_form.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockProjectBloc extends MockBloc<ProjectEvent, ProjectState>
    implements ProjectBloc {}

class MockClientCubit extends MockCubit<ClientState> implements ClientCubit {}

void main() {
  late MockProjectBloc projectBloc;
  late MockClientCubit clientCubit;
  late Project seedProject;

  Widget buildSubject({Project? seedProject}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) {
            return ChangeNotifierProvider(
              create: (_) => ProjectFormController(),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<ProjectBloc>.value(value: projectBloc),
                  BlocProvider<ClientCubit>.value(value: clientCubit),
                ],
                child: AddOrEditProjectView(
                  isEdit: true,
                  projectId: 'project-1',
                  seedProject: seedProject,
                ),
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    final prefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => prefs);

    projectBloc = MockProjectBloc();
    clientCubit = MockClientCubit();
    seedProject = Project(
      id: 'project-1',
      userId: 'user-1',
      projectName: 'Seed Project',
      clientName: 'Seed Client',
      shortDescription: 'Seed description',
      budget: 1,
      projectType: 'Mobile',
      totalPaid: 0,
      numberOfMilestonesSoFar: 0,
      startDate: DateTime(2024),
      clientId: 'client-1',
    );
    when(() => clientCubit.state).thenReturn(const ClientInitial());
    when(() => clientCubit.getClients()).thenAnswer((_) async {});
    whenListen(
      clientCubit,
      const Stream<ClientState>.empty(),
      initialState: const ClientInitial(),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'shows loading chrome during the initial ProjectInitial bootstrap frame',
    (tester) async {
      when(() => projectBloc.state).thenReturn(const ProjectInitial());
      whenListen(
        projectBloc,
        const Stream<ProjectState>.empty(),
        initialState: const ProjectInitial(),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      expect(find.byType(AddOrEditProjectForm), findsNothing);
      verify(
        () => projectBloc.add(const GetProjectByIdEvent('project-1')),
      ).called(1);
    },
  );

  testWidgets(
    'seedProject no longer bypasses authoritative lifecycle fetch',
    (tester) async {
      when(() => projectBloc.state).thenReturn(const ProjectInitial());
      whenListen(
        projectBloc,
        const Stream<ProjectState>.empty(),
        initialState: const ProjectInitial(),
      );

      await tester.pumpWidget(buildSubject(seedProject: seedProject));

      expect(find.byType(AddOrEditProjectForm), findsNothing);
      verify(
        () => projectBloc.add(const GetProjectByIdEvent('project-1')),
      ).called(1);
    },
  );

  testWidgets(
    'renders the pending-delete block for deleting projects',
    (tester) async {
      final pendingProject = ProjectModel.empty().copyWith(
        id: 'project-1',
        projectName: 'Seed Project',
        deletionRequestedAt: DateTime(2024, 1, 2),
      );
      when(() => projectBloc.state).thenReturn(ProjectLoaded(pendingProject));
      whenListen(
        projectBloc,
        const Stream<ProjectState>.empty(),
        initialState: ProjectLoaded(pendingProject),
      );

      await tester.pumpWidget(buildSubject(seedProject: seedProject));
      await tester.pumpAndSettle();

      expect(find.text('Project deletion in progress'), findsOneWidget);
      expect(find.byType(AddOrEditProjectForm), findsNothing);
    },
  );
}
