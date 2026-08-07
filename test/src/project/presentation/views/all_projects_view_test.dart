import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/views/all_projects_view.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockProjectBloc extends MockBloc<ProjectEvent, ProjectState>
    implements ProjectBloc {}

class MockClientCubit extends MockCubit<ClientState> implements ClientCubit {}

void main() {
  late MockProjectBloc projectBloc;
  late MockClientCubit clientCubit;
  late ProjectModel project;

  setUpAll(() {
    registerFallbackValue(const GetProjectsEvent());
  });

  setUp(() {
    projectBloc = MockProjectBloc();
    clientCubit = MockClientCubit();
    when(() => projectBloc.add(any())).thenReturn(null);
    when(() => clientCubit.state).thenReturn(const ClientInitial());
    when(() => clientCubit.getClientById(any())).thenAnswer((_) async {});
    whenListen(
      clientCubit,
      const Stream<ClientState>.empty(),
      initialState: const ClientInitial(),
    );
    sl.registerFactory<ClientCubit>(() => clientCubit);
    project = ProjectModel.empty().copyWith(
      id: 'project-1',
      projectName: 'Northwind Portal',
      clientName: 'Northwind',
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'renders structured empty state inside the projects page scaffold',
    (
      tester,
    ) async {
      when(() => projectBloc.state).thenReturn(const ProjectsLoaded([]));
      whenListen(
        projectBloc,
        const Stream<ProjectState>.empty(),
        initialState: const ProjectsLoaded([]),
      );

      await tester.pumpApp(
        BlocProvider<ProjectBloc>.value(
          value: projectBloc,
          child: const AllProjectsView(),
        ),
      );

      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Project library'), findsOneWidget);
      expect(find.text('No projects yet.'), findsOneWidget);
      expect(find.text('Add Project'), findsOneWidget);
    },
  );

  testWidgets('renders stable project cards on wide layouts', (tester) async {
    final pendingDeletionProject = project.copyWith(
      id: 'project-2',
      projectName: 'Pending cleanup',
      deletionRequestedAt: DateTime(2024, 1, 2),
    );
    when(
      () => projectBloc.state,
    ).thenReturn(ProjectsLoaded([project, pendingDeletionProject]));
    whenListen(
      projectBloc,
      const Stream<ProjectState>.empty(),
      initialState: ProjectsLoaded([project, pendingDeletionProject]),
    );

    await tester.pumpApp(
      BlocProvider<ProjectBloc>.value(
        value: projectBloc,
        child: const AllProjectsView(),
      ),
      surfaceSize: const Size(1280, 900),
    );

    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Project library'), findsOneWidget);
    expect(find.text('Northwind Portal'), findsOneWidget);
    expect(find.text('Pending deletion'), findsAtLeastNWidgets(1));
    expect(find.text('Pending cleanup'), findsOneWidget);
  });
}
