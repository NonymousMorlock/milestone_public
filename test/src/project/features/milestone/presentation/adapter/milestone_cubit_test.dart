// addMilestone, deleteMilestone, editMilestone, getMilestoneById,
// getMilestones

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/add_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/delete_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/edit_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestone_by_id.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestones.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAddMilestone extends Mock implements AddMilestone {}

class MockDeleteMilestone extends Mock implements DeleteMilestone {}

class MockEditMilestone extends Mock implements EditMilestone {}

class MockGetMilestoneById extends Mock implements GetMilestoneById {}

class MockGetMilestones extends Mock implements GetMilestones {}

void main() {
  late MockAddMilestone mockAddMilestone;
  late MockDeleteMilestone mockDeleteMilestone;
  late MockEditMilestone mockEditMilestone;
  late MockGetMilestoneById mockGetMilestoneById;
  late MockGetMilestones mockGetMilestones;
  late MilestoneCubit cubit;

  setUp(() {
    mockAddMilestone = MockAddMilestone();
    mockDeleteMilestone = MockDeleteMilestone();
    mockEditMilestone = MockEditMilestone();
    mockGetMilestoneById = MockGetMilestoneById();
    mockGetMilestones = MockGetMilestones();
    cubit = MilestoneCubit(
      addMilestone: mockAddMilestone,
      deleteMilestone: mockDeleteMilestone,
      editMilestone: mockEditMilestone,
      getMilestoneById: mockGetMilestoneById,
      getMilestones: mockGetMilestones,
    );
  });

  const tFailure = ServerFailure(
    message: 'The caller does not have permission',
    statusCode: 'permission-denied',
  );

  test('initial state should be MilestoneInitial', () {
    expect(cubit.state, const MilestoneInitial());
  });

  group('addMilestone', () {
    final tMilestone = MilestoneModel.empty();
    setUp(() {
      registerFallbackValue(tMilestone);
    });
    blocTest<MilestoneCubit, MilestoneState>(
      'should emit [MilestoneLoading, MilestoneAdded] when addMilestone is '
      'successful',
      build: () {
        when(() => mockAddMilestone(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return cubit;
      },
      act: (cubit) => cubit.addMilestone(tMilestone),
      expect: () => [
        const MilestoneLoading(),
        // because we don't know the random milestoneID from firestore
        isA<MilestoneAdded>(),
      ],
      verify: (_) {
        verify(() => mockAddMilestone(tMilestone)).called(1);
        verifyNoMoreInteractions(mockAddMilestone);
      },
    );

    blocTest<MilestoneCubit, MilestoneState>(
      'should emit [MilestoneLoading, MilestoneError] when addMilestone is '
      'unsuccessful',
      build: () {
        when(() => mockAddMilestone(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.addMilestone(tMilestone),
      expect: () => [
        const MilestoneLoading(),
        MilestoneError(
          title: 'Error Adding Milestone',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(() => mockAddMilestone(tMilestone)).called(1);
        verifyNoMoreInteractions(mockAddMilestone);
      },
    );
  });

  group('deleteMilestone', () {
    const tProjectId = 'project-id';
    const tMilestoneId = 'milestone-id';

    setUp(() {
      registerFallbackValue(const DeleteMilestoneParams.empty());
    });
    blocTest<MilestoneCubit, MilestoneState>(
      'should emit [MilestoneLoading, MilestoneDeleted] when '
      'deleteMilestone is successful',
      build: () {
        when(() => mockDeleteMilestone(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return cubit;
      },
      act: (cubit) => cubit.deleteMilestone(
        projectId: tProjectId,
        milestoneId: tMilestoneId,
      ),
      expect: () => [
        const MilestoneLoading(),
        const MilestoneDeleted(),
      ],
      verify: (_) {
        verify(
          () => mockDeleteMilestone(
            const DeleteMilestoneParams(
              projectId: tProjectId,
              milestoneId: tMilestoneId,
            ),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockDeleteMilestone);
      },
    );

    blocTest<MilestoneCubit, MilestoneState>(
      'should emit [MilestoneLoading, MilestoneError] when deleteMilestone is '
      'unsuccessful',
      build: () {
        when(() => mockDeleteMilestone(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.deleteMilestone(
        projectId: tProjectId,
        milestoneId: tMilestoneId,
      ),
      expect: () => [
        const MilestoneLoading(),
        MilestoneError(
          title: 'Error Deleting Milestone',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(
          () => mockDeleteMilestone(
            const DeleteMilestoneParams(
              projectId: tProjectId,
              milestoneId: tMilestoneId,
            ),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockDeleteMilestone);
      },
    );
  });

  group('editMilestone', () {
    const tProjectId = 'project-id';
    const tMilestoneId = 'milestone-id';
    const tUpdatedMilestone = {'name': 'new name'};

    setUp(() {
      registerFallbackValue(EditMilestoneParams.empty());
    });
    blocTest<MilestoneCubit, MilestoneState>(
      'should emit [MilestoneLoading, MilestoneEdited] when editMilestone is '
      'successful',
      build: () {
        when(() => mockEditMilestone(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return cubit;
      },
      act: (cubit) => cubit.editMilestone(
        projectId: tProjectId,
        milestoneId: tMilestoneId,
        updatedMilestone: tUpdatedMilestone,
      ),
      expect: () => [
        const MilestoneLoading(),
        const MilestoneUpdated(),
      ],
      verify: (_) {
        verify(
          () => mockEditMilestone(
            const EditMilestoneParams(
              projectId: tProjectId,
              milestoneId: tMilestoneId,
              updatedMilestone: tUpdatedMilestone,
            ),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockEditMilestone);
      },
    );

    blocTest<MilestoneCubit, MilestoneState>(
      'should emit [MilestoneLoading, MilestoneError] when editMilestone is '
      'unsuccessful',
      build: () {
        when(() => mockEditMilestone(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.editMilestone(
        projectId: tProjectId,
        milestoneId: tMilestoneId,
        updatedMilestone: tUpdatedMilestone,
      ),
      expect: () => [
        const MilestoneLoading(),
        MilestoneError(
          title: 'Error Editing Milestone',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(
          () => mockEditMilestone(
            const EditMilestoneParams(
              projectId: tProjectId,
              milestoneId: tMilestoneId,
              updatedMilestone: tUpdatedMilestone,
            ),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockEditMilestone);
      },
    );
  });

  group('getMilestoneById', () {
    const tProjectId = 'project-id';
    const tMilestoneId = 'milestone-id';
    final tMilestone = MilestoneModel.empty();

    setUp(() {
      registerFallbackValue(const GetMilestoneByIdParams.empty());
    });
    blocTest<MilestoneCubit, MilestoneState>(
      'should emit [MilestoneLoading, MilestoneLoaded] when '
      'getMilestoneById is successful',
      build: () {
        when(() => mockGetMilestoneById(any())).thenAnswer(
          (_) async => Right(tMilestone),
        );
        return cubit;
      },
      act: (cubit) => cubit.getMilestoneById(
        projectId: tProjectId,
        milestoneId: tMilestoneId,
      ),
      expect: () => [
        const MilestoneLoading(),
        MilestoneLoaded(tMilestone),
      ],
      verify: (_) {
        verify(
          () => mockGetMilestoneById(
            const GetMilestoneByIdParams(
              projectId: tProjectId,
              milestoneId: tMilestoneId,
            ),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockGetMilestoneById);
      },
    );

    blocTest<MilestoneCubit, MilestoneState>(
      'should emit [MilestoneLoading, MilestoneError] when getMilestoneById is '
      'unsuccessful',
      build: () {
        when(() => mockGetMilestoneById(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.getMilestoneById(
        projectId: tProjectId,
        milestoneId: tMilestoneId,
      ),
      expect: () => [
        const MilestoneLoading(),
        MilestoneError(
          title: 'Error Fetching Milestone',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(
          () => mockGetMilestoneById(
            const GetMilestoneByIdParams(
              projectId: tProjectId,
              milestoneId: tMilestoneId,
            ),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockGetMilestoneById);
      },
    );
  });

  group('getMilestones', () {
    const tProjectId = 'project-id';
    final tMilestones = [MilestoneModel.empty()];

    blocTest<MilestoneCubit, MilestoneState>(
      'should emit [MilestoneLoading, MilestonesLoaded] when getMilestones is '
      'successful',
      build: () {
        when(() => mockGetMilestones(any())).thenAnswer(
          (_) async => Right(tMilestones),
        );
        return cubit;
      },
      act: (cubit) => cubit.getMilestones(tProjectId),
      expect: () => [
        const MilestoneLoading(),
        MilestonesLoaded(tMilestones),
      ],
      verify: (_) {
        verify(() => mockGetMilestones(tProjectId)).called(1);
        verifyNoMoreInteractions(mockGetMilestones);
      },
    );

    blocTest<MilestoneCubit, MilestoneState>(
      'should emit [MilestoneLoading, MilestoneError] when getMilestones is '
      'unsuccessful',
      build: () {
        when(() => mockGetMilestones(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );
        return cubit;
      },
      act: (cubit) => cubit.getMilestones(tProjectId),
      expect: () => [
        const MilestoneLoading(),
        MilestoneError(
          title: 'Error Fetching Milestones',
          message: tFailure.errorMessage,
        ),
      ],
      verify: (_) {
        verify(() => mockGetMilestones(tProjectId)).called(1);
        verifyNoMoreInteractions(mockGetMilestones);
      },
    );
  });
}
