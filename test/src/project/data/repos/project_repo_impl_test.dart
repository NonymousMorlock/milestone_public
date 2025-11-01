import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/project/data/datasources/project_remote_data_src.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/data/repos/project_repo_impl.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectRemoteDataSrc extends Mock implements ProjectRemoteDataSrc {}

void main() {
  late ProjectRemoteDataSrc remoteDataSrc;
  late ProjectRepoImpl repoImpl;

  final tProject = ProjectModel.empty();

  setUp(() {
    remoteDataSrc = MockProjectRemoteDataSrc();
    repoImpl = ProjectRepoImpl(remoteDataSrc);
    registerFallbackValue(tProject);
  });

  const tException = ServerException(
    message: 'message',
    statusCode: 'statusCode',
  );

  group('addProject', () {
    test(
      'should complete successfully when call to remote source is '
      'successful',
      () async {
        when(() => remoteDataSrc.addProject(any())).thenAnswer(
          (_) async => Future.value(),
        );

        final result = await repoImpl.addProject(tProject);
        expect(result, equals(const Right<Failure, void>(null)));
        verify(() => remoteDataSrc.addProject(tProject)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );

    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(() => remoteDataSrc.addProject(any())).thenThrow(tException);

        final result = await repoImpl.addProject(tProject);

        expect(
          result,
          equals(
            Left<Failure, void>(ServerFailure.fromException(tException)),
          ),
        );

        verify(() => remoteDataSrc.addProject(tProject)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('editProjectDetails', () {
    test(
        'should complete successfully when call to remote source is successful',
        () async {
      when(
        () => remoteDataSrc.editProjectDetails(
          projectId: any(named: 'projectId'),
          updatedProject: any(named: 'updatedProject'),
        ),
      ).thenAnswer((_) async => Future.value());

      final result = await repoImpl.editProjectDetails(
        projectId: tProject.id,
        updatedProject: {},
      );

      expect(result, equals(const Right<Failure, void>(null)));
      verify(
        () => remoteDataSrc.editProjectDetails(
          projectId: tProject.id,
          updatedProject: {},
        ),
      );
      verifyNoMoreInteractions(remoteDataSrc);
    });

    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(
          () => remoteDataSrc.editProjectDetails(
            projectId: any(named: 'projectId'),
            updatedProject: any(named: 'updatedProject'),
          ),
        ).thenThrow(tException);

        final result = await repoImpl.editProjectDetails(
          projectId: tProject.id,
          updatedProject: {},
        );

        expect(
          result,
          equals(
            Left<Failure, void>(ServerFailure.fromException(tException)),
          ),
        );
        verify(
          () => remoteDataSrc.editProjectDetails(
            projectId: tProject.id,
            updatedProject: {},
          ),
        );
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('deleteProject', () {
    test(
      'should complete successfully when call to remote source is '
      'successful',
      () async {
        when(() => remoteDataSrc.deleteProject(any())).thenAnswer(
          (_) async => Future.value(),
        );

        final result = await repoImpl.deleteProject(tProject.id);
        expect(result, equals(const Right<Failure, void>(null)));
        verify(() => remoteDataSrc.deleteProject(tProject.id)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );

    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(() => remoteDataSrc.deleteProject(any())).thenThrow(tException);

        final result = await repoImpl.deleteProject(tProject.id);

        expect(
          result,
          equals(
            Left<Failure, void>(ServerFailure.fromException(tException)),
          ),
        );

        verify(() => remoteDataSrc.deleteProject(tProject.id)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('getProjects', () {
    test(
      'should emit [Right(List<Project>)] when call to remote source '
      'is successful',
      () {
        final expectedProjects = [tProject];
        when(
          () => remoteDataSrc.getProjects(detailed: any(named: 'detailed')),
        ).thenAnswer((_) => Stream.value(expectedProjects));

        final stream = repoImpl.getProjects(detailed: true);

        expect(
          stream,
          emits(Right<Failure, List<Project>>(expectedProjects)),
        );

        verify(() => remoteDataSrc.getProjects(detailed: true)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );

    test(
      'should emit [Left(ServerFailure)] when call to remote source '
      'is successful',
      () {
        when(
          () => remoteDataSrc.getProjects(detailed: any(named: 'detailed')),
        ).thenAnswer((_) => Stream.error(tException));

        final stream = repoImpl.getProjects(detailed: true);

        expect(
          stream,
          emits(
            Left<Failure, List<Project>>(
              ServerFailure.fromException(tException),
            ),
          ),
        );
        verify(() => remoteDataSrc.getProjects(detailed: true)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('getProjectById', () {
    test(
      'should return [Project] when call to remote source is successful',
      () async {
        when(() => remoteDataSrc.getProjectById(any())).thenAnswer(
          (_) async => tProject,
        );

        final result = await repoImpl.getProjectById(tProject.id);

        expect(result, equals(Right<Failure, Project>(tProject)));
        verify(() => remoteDataSrc.getProjectById(tProject.id)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(() => remoteDataSrc.getProjectById(any())).thenThrow(tException);
        final result = await repoImpl.getProjectById(tProject.id);
        expect(
          result,
          equals(
            Left<Failure, Project>(ServerFailure.fromException(tException)),
          ),
        );
        verify(() => remoteDataSrc.getProjectById(tProject.id)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });
}
