import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/home/presentation/views/home_page.dart';
import 'package:milestone/src/home/presentation/widgets/draggable_card.dart';
import 'package:milestone/src/home/presentation/widgets/nav_drawer.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_firebase.dart';
import '../../../../helpers/pump_app.dart';

class MockProjectBloc extends MockBloc<ProjectEvent, ProjectState>
    implements ProjectBloc {}

class MockClientCubit extends MockCubit<ClientState> implements ClientCubit {}

void main() {
  late MockProjectBloc projectBloc;
  late MockClientCubit clientCubit;
  late ProjectModel project;
  late MockFirebase mockFirebase;

  setUpAll(() {
    registerFallbackValue(const GetProjectsEvent());
  });

  setUp(() async {
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
    project = ProjectModel.empty().copyWith(
      id: 'project-1',
      projectName: 'Northwind Portal',
      clientName: 'Northwind',
    );
    mockFirebase = MockFirebase();
    await mockFirebase.initAuth();
    await mockFirebase.initFirestore();
    await sl.reset();
    sl
      ..registerLazySingleton<FirebaseAuth>(() => mockFirebase.auth)
      ..registerLazySingleton<FirebaseFirestore>(() => mockFirebase.firestore)
      ..registerFactory<ClientCubit>(() => clientCubit);
    await mockFirebase.firestore
        .collection('users')
        .doc(mockFirebase.auth.currentUser!.uid)
        .set({'totalEarned': 1200});
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'shows the empty-state add-project CTA without overlay nav',
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
          child: const HomePage(),
        ),
      );

      verify(
        () => projectBloc.add(
          const GetProjectsEvent(
            limit: 5,
            excludePendingDeletion: true,
          ),
        ),
      ).called(1);

      expect(find.text('Quick actions'), findsOneWidget);
      expect(find.text('No projects have been created yet.'), findsOneWidget);
      expect(find.text('Add Project'), findsOneWidget);
      expect(find.byType(NavDrawer), findsNothing);
      expect(find.byType(DraggableCard), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );

  testWidgets(
    'shows dashboard sections and recent active project summaries on '
    'wide layouts',
    (
      tester,
    ) async {
      final pendingProject = project.copyWith(
        id: 'project-2',
        projectName: 'Pending cleanup',
        deletionRequestedAt: DateTime(2024, 1, 2),
      );
      when(() => projectBloc.state).thenReturn(
        ProjectsLoaded([pendingProject, project]),
      );
      whenListen(
        projectBloc,
        const Stream<ProjectState>.empty(),
        initialState: ProjectsLoaded([pendingProject, project]),
      );

      await tester.pumpApp(
        BlocProvider<ProjectBloc>.value(
          value: projectBloc,
          child: const HomePage(),
        ),
        surfaceSize: const Size(1280, 900),
      );

      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Quick actions'), findsOneWidget);
      expect(find.text('Recent projects'), findsOneWidget);
      expect(find.text('Northwind Portal'), findsOneWidget);
      expect(find.text('Pending cleanup'), findsNothing);
    },
  );
}
