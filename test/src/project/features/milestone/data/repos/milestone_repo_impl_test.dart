import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/project/features/milestone/data/datasources/milestone_remote_data_src.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';
import 'package:milestone/src/project/features/milestone/data/repos/milestone_repo_impl.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:mocktail/mocktail.dart';

class MockMilestoneRemoteDataSrc extends Mock
    implements MilestoneRemoteDataSrc {}

void main() {
  late MilestoneRemoteDataSrc remoteDataSrc;
  late MilestoneRepoImpl repoImpl;

  final tMilestone = MilestoneModel.empty();
  const tProjectId = 'Test Id';

  setUp(() {
    remoteDataSrc = MockMilestoneRemoteDataSrc();
    repoImpl = MilestoneRepoImpl(remoteDataSrc);
    registerFallbackValue(tMilestone);
  });

  const tException = ServerException(
    message: 'message',
    statusCode: 'statusCode',
  );

  group('addMilestone', () {
    test(
      'should complete successfully when call to remote source is successful',
      () async {
        when(() => remoteDataSrc.addMilestone(any())).thenAnswer(
          (_) async => Future.value(),
        );

        final result = await repoImpl.addMilestone(tMilestone);

        expect(result, equals(const Right<Failure, void>(null)));

        verify(() => remoteDataSrc.addMilestone(tMilestone)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(() => remoteDataSrc.addMilestone(any())).thenThrow(tException);

        final result = await repoImpl.addMilestone(tMilestone);

        expect(
          result,
          equals(
            Left<Failure, void>(ServerFailure.fromException(tException)),
          ),
        );

        verify(() => remoteDataSrc.addMilestone(tMilestone)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('editMilestone', () {
    test(
      'should complete successfully when call to remote source is successful',
      () async {
        when(
          () => remoteDataSrc.editMilestone(
            projectId: any(named: 'projectId'),
            milestoneId: any(named: 'milestoneId'),
            updatedMilestone: any(named: 'updatedMilestone'),
          ),
        ).thenAnswer((_) async => Future.value());

        final result = await repoImpl.editMilestone(
          projectId: tProjectId,
          milestoneId: tMilestone.id,
          updatedMilestone: {},
        );

        expect(result, equals(const Right<Failure, void>(null)));

        verify(
          () => remoteDataSrc.editMilestone(
            projectId: tProjectId,
            milestoneId: tMilestone.id,
            updatedMilestone: {},
          ),
        ).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(
          () => remoteDataSrc.editMilestone(
            projectId: any(named: 'projectId'),
            milestoneId: any(named: 'milestoneId'),
            updatedMilestone: any(named: 'updatedMilestone'),
          ),
        ).thenThrow(tException);

        final result = await repoImpl.editMilestone(
          projectId: tProjectId,
          milestoneId: tMilestone.id,
          updatedMilestone: {},
        );

        expect(
          result,
          equals(
            Left<Failure, void>(ServerFailure.fromException(tException)),
          ),
        );

        verify(
          () => remoteDataSrc.editMilestone(
            projectId: tProjectId,
            milestoneId: tMilestone.id,
            updatedMilestone: {},
          ),
        ).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('getMilestones', () {
    test(
      'should return [List<Milestone>] when call to remote source is '
      'successful',
      () async {
        final expectedMilestones = [tMilestone];
        when(() => remoteDataSrc.getMilestones(any())).thenAnswer(
          (_) async => expectedMilestones,
        );

        final result = await repoImpl.getMilestones(tProjectId);

        expect(
          result,
          equals(Right<Failure, List<Milestone>>(expectedMilestones)),
        );

        verify(() => remoteDataSrc.getMilestones(tProjectId)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(() => remoteDataSrc.getMilestones(any())).thenThrow(tException);

        final result = await repoImpl.getMilestones(tProjectId);

        expect(
          result,
          equals(
            Left<Failure, List<Milestone>>(
              ServerFailure.fromException(tException),
            ),
          ),
        );

        verify(() => remoteDataSrc.getMilestones(tProjectId)).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('deleteMilestone', () {
    test(
      'should complete successfully when call to remote source is successful',
      () async {
        when(
          () => remoteDataSrc.deleteMilestone(
            projectId: any(named: 'projectId'),
            milestoneId: any(named: 'milestoneId'),
          ),
        ).thenAnswer((_) async => Future.value());

        final result = await repoImpl.deleteMilestone(
          projectId: tProjectId,
          milestoneId: tMilestone.id,
        );

        expect(result, equals(const Right<Failure, void>(null)));

        verify(
          () => remoteDataSrc.deleteMilestone(
            projectId: tProjectId,
            milestoneId: tMilestone.id,
          ),
        ).called(1);

        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(
          () => remoteDataSrc.deleteMilestone(
            projectId: any(named: 'projectId'),
            milestoneId: any(named: 'milestoneId'),
          ),
        ).thenThrow(tException);

        final result = await repoImpl.deleteMilestone(
          projectId: tProjectId,
          milestoneId: tMilestone.id,
        );

        expect(
          result,
          equals(Left<Failure, void>(ServerFailure.fromException(tException))),
        );

        verify(
          () => remoteDataSrc.deleteMilestone(
            projectId: tProjectId,
            milestoneId: tMilestone.id,
          ),
        ).called(1);

        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });

  group('getMilestoneById', () {
    test(
      'should return [Milestone] when call to remote source is successful',
      () async {
        when(
          () => remoteDataSrc.getMilestoneById(
            projectId: any(named: 'projectId'),
            milestoneId: any(named: 'milestoneId'),
          ),
        ).thenAnswer((_) async => tMilestone);

        final result = await repoImpl.getMilestoneById(
          projectId: tProjectId,
          milestoneId: tMilestone.id,
        );

        expect(result, equals(Right<Failure, Milestone>(tMilestone)));

        verify(
          () => remoteDataSrc.getMilestoneById(
            projectId: tProjectId,
            milestoneId: tMilestone.id,
          ),
        ).called(1);

        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
    test(
      'should return [ServerFailure] when call to remote source '
      'is unsuccessful',
      () async {
        when(
          () => remoteDataSrc.getMilestoneById(
            projectId: any(named: 'projectId'),
            milestoneId: any(named: 'milestoneId'),
          ),
        ).thenThrow(tException);

        final result = await repoImpl.getMilestoneById(
          projectId: tProjectId,
          milestoneId: tMilestone.id,
        );

        expect(
          result,
          equals(
            Left<Failure, Milestone>(ServerFailure.fromException(tException)),
          ),
        );

        verify(
          () => remoteDataSrc.getMilestoneById(
            projectId: tProjectId,
            milestoneId: tMilestone.id,
          ),
        ).called(1);

        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });
}
