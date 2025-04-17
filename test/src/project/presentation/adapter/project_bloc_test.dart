import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/domain/usecases/add_project.dart';
import 'package:milestone/src/project/domain/usecases/delete_project.dart';
import 'package:milestone/src/project/domain/usecases/edit_project_details.dart';
import 'package:milestone/src/project/domain/usecases/get_project_by_id.dart';
import 'package:milestone/src/project/domain/usecases/get_projects.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAddProject extends Mock implements AddProject {}

class MockDeleteProject extends Mock implements DeleteProject {}

class MockEditProjectDetails extends Mock implements EditProjectDetails {}

class MockGetProjectById extends Mock implements GetProjectById {}

class MockGetProjects extends Mock implements GetProjects {}

void main() {
  late AddProject addProject;
  late DeleteProject deleteProject;
  late EditProjectDetails editProjectDetails;
  late GetProjectById getProjectById;
  late GetProjects getProjects;
  late ProjectBloc bloc;

  setUp(() {
    addProject = MockAddProject();
    deleteProject = MockDeleteProject();
    editProjectDetails = MockEditProjectDetails();
    getProjectById = MockGetProjectById();
    getProjects = MockGetProjects();
    bloc = ProjectBloc(
      addProject: addProject,
      deleteProject: deleteProject,
      editProjectDetails: editProjectDetails,
      getProjectById: getProjectById,
      getProjects: getProjects,
    );
  });

  const tFailure = ServerFailure(
    message: 'The caller does not have permission',
    statusCode: 'permission-denied',
  );

  test('initial state is ProjectInitial', () {
    expect(bloc.state, const ProjectInitial());
  });

  group('addProject', () {
    final tProject = ProjectModel.empty();
    setUp(() {
      registerFallbackValue(tProject);
    });
    blocTest<ProjectBloc, ProjectState>(
      'should emit [ProjectLoading, ProjectAdded] when addProject is '
      'successful',
      build: () {
        when(() => addProject(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return bloc;
      },
      act: (bloc) => bloc.add($AddProject(tProject)),
      expect: () => [
        const ProjectLoading(),
        const ProjectAdded(),
      ],
      verify: (_) {
        verify(() => addProject(tProject)).called(1);
        verifyNoMoreInteractions(addProject);
      },
    );

    blocTest<ProjectBloc, ProjectState>(
      'should emit [ProjectLoading, ProjectError] when addProject is '
      'unsuccessful',
      build: () {
        when(() => addProject(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return bloc;
      },
      act: (bloc) => bloc.add($AddProject(tProject)),
      expect: () => [
        const ProjectLoading(),
        ProjectError(
          title: 'Error Adding Project',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(() => addProject(tProject)).called(1);
        verifyNoMoreInteractions(addProject);
      },
    );
  });

  group('deleteProject', () {
    const tProjectId = 'project-id';
    blocTest<ProjectBloc, ProjectState>(
      'should emit [ProjectLoading, ProjectDeleted] when deleteProject is '
      'successful',
      build: () {
        when(() => deleteProject(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const $DeleteProject(tProjectId)),
      expect: () => [
        const ProjectLoading(),
        const ProjectDeleted(),
      ],
      verify: (_) {
        verify(() => deleteProject(tProjectId)).called(1);
        verifyNoMoreInteractions(deleteProject);
      },
    );

    blocTest<ProjectBloc, ProjectState>(
      'should emit [ProjectLoading, ProjectError] when deleteProject is '
      'unsuccessful',
      build: () {
        when(() => deleteProject(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const $DeleteProject(tProjectId)),
      expect: () => [
        const ProjectLoading(),
        ProjectError(
          title: 'Error Deleting Project',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(() => deleteProject(tProjectId)).called(1);
        verifyNoMoreInteractions(deleteProject);
      },
    );
  });

  group('editProjectDetails', () {
    const tProjectId = 'project-id';
    setUp(() {
      registerFallbackValue(const EditProjectDetailsParams.empty());
    });
    blocTest<ProjectBloc, ProjectState>(
      'should emit [ProjectLoading, ProjectUpdated] when editProjectDetails is '
      'successful',
      build: () {
        when(() => editProjectDetails(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const $EditProjectDetails(projectId: tProjectId, updatedProject: {}),
      ),
      expect: () => [
        const ProjectLoading(),
        const ProjectUpdated(),
      ],
      verify: (_) {
        verify(
          () => editProjectDetails(
            const EditProjectDetailsParams(
              projectId: tProjectId,
              updatedProject: {},
            ),
          ),
        ).called(1);
        verifyNoMoreInteractions(editProjectDetails);
      },
    );

    blocTest<ProjectBloc, ProjectState>(
      'should emit [ProjectLoading, ProjectError] when editProjectDetails is '
      'unsuccessful',
      build: () {
        when(() => editProjectDetails(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const $EditProjectDetails(projectId: tProjectId, updatedProject: {}),
      ),
      expect: () => [
        const ProjectLoading(),
        ProjectError(
          title: 'Error Editing Project',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(
          () => editProjectDetails(
            const EditProjectDetailsParams(
              projectId: tProjectId,
              updatedProject: {},
            ),
          ),
        ).called(1);
        verifyNoMoreInteractions(editProjectDetails);
      },
    );
  });

  group('getProjectById', () {
    const tProjectId = 'project-id';
    final tProject = ProjectModel.empty();

    blocTest<ProjectBloc, ProjectState>(
      'should emit [ProjectLoading, ProjectLoaded] when getProjectById is '
      'successful',
      build: () {
        when(() => getProjectById(any())).thenAnswer(
          (_) async => Right(tProject),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const $GetProjectById(tProjectId)),
      expect: () => [
        const ProjectLoading(),
        ProjectLoaded(tProject),
      ],
      verify: (_) {
        verify(() => getProjectById(tProjectId)).called(1);
        verifyNoMoreInteractions(getProjectById);
      },
    );

    blocTest<ProjectBloc, ProjectState>(
      'should emit [ProjectLoading, ProjectError] when getProjectById is '
      'unsuccessful',
      build: () {
        when(() => getProjectById(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const $GetProjectById(tProjectId)),
      expect: () => [
        const ProjectLoading(),
        ProjectError(
          title: 'Error Fetching Project',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(() => getProjectById(tProjectId)).called(1);
        verifyNoMoreInteractions(getProjectById);
      },
    );
  });

  // getProjects usecase returns a stream so the test will be different
  group('getProjects', () {
    final tProjects = [ProjectModel.empty()];
    blocTest<ProjectBloc, ProjectState>(
      'should emit [ProjectLoading, ProjectLoaded] when getProjects is '
      'successful',
      build: () {
        when(() => getProjects(any())).thenAnswer(
          (_) => Stream.value(Right(tProjects)),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const $GetProjects()),
      expect: () => [
        const ProjectLoading(),
        ProjectsLoaded(tProjects),
      ],
      verify: (_) {
        verify(() => getProjects(true)).called(1);
        verifyNoMoreInteractions(getProjects);
      },
    );

    blocTest<ProjectBloc, ProjectState>(
      'should emit [ProjectLoading, ProjectError] when getProjects is '
      'unsuccessful',
      build: () {
        when(() => getProjects(any())).thenAnswer(
          (_) => Stream.value(const Left(tFailure)),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const $GetProjects()),
      expect: () => [
        const ProjectLoading(),
        ProjectError(
          title: 'Error Fetching Projects',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(() => getProjects(true)).called(1);
        verifyNoMoreInteractions(getProjects);
      },
    );
  });
}
