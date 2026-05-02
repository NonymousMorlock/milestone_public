import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone_collection_snapshot.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/add_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/delete_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/edit_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestone_by_id.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestones.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/reorder_milestone.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAddMilestone extends Mock implements AddMilestone {}

class MockDeleteMilestone extends Mock implements DeleteMilestone {}

class MockEditMilestone extends Mock implements EditMilestone {}

class MockReorderMilestone extends Mock implements ReorderMilestone {}

class MockGetMilestoneById extends Mock implements GetMilestoneById {}

class MockGetMilestones extends Mock implements GetMilestones {}

void main() {
  late MockAddMilestone mockAddMilestone;
  late MockDeleteMilestone mockDeleteMilestone;
  late MockEditMilestone mockEditMilestone;
  late MockReorderMilestone mockReorderMilestone;
  late MockGetMilestoneById mockGetMilestoneById;
  late MockGetMilestones mockGetMilestones;
  late MilestoneCubit cubit;

  const tFailure = ServerFailure(
    message: 'The caller does not have permission',
    statusCode: 'permission-denied',
  );

  final tMilestone = MilestoneModel.empty().copyWith(
    id: 'milestone-1',
    projectId: 'project-1',
    title: 'Discovery',
    notes: const ['Ship wireframes'],
  );
  final tMilestones = [
    tMilestone,
    tMilestone.copyWith(
      id: 'milestone-2',
      title: 'Build',
      rank: 1024,
    ),
  ];
  final tSnapshot = MilestoneCollectionSnapshot(
    milestones: tMilestones,
    orderVersion: 3,
  );

  setUpAll(() {
    registerFallbackValue(tMilestone);
    registerFallbackValue(const DeleteMilestoneParams.empty());
    registerFallbackValue(EditMilestoneParams.empty());
    registerFallbackValue(const GetMilestoneByIdParams.empty());
    registerFallbackValue(const ReorderMilestoneParams.empty());
  });

  setUp(() {
    mockAddMilestone = MockAddMilestone();
    mockDeleteMilestone = MockDeleteMilestone();
    mockEditMilestone = MockEditMilestone();
    mockReorderMilestone = MockReorderMilestone();
    mockGetMilestoneById = MockGetMilestoneById();
    mockGetMilestones = MockGetMilestones();
    cubit = MilestoneCubit(
      addMilestone: mockAddMilestone,
      deleteMilestone: mockDeleteMilestone,
      editMilestone: mockEditMilestone,
      reorderMilestone: mockReorderMilestone,
      getMilestoneById: mockGetMilestoneById,
      getMilestones: mockGetMilestones,
    );
  });

  test('initial state should be the default milestone state', () {
    expect(cubit.state, const MilestoneState());
  });

  blocTest<MilestoneCubit, MilestoneState>(
    'getMilestones preserves the current snapshot while it reloads',
    build: () {
      when(() => mockGetMilestones(any())).thenAnswer(
        (_) async => Right(tSnapshot),
      );
      return cubit;
    },
    seed: () => MilestoneState(
      collection: MilestoneCollectionSuccess(tSnapshot),
    ),
    act: (cubit) => cubit.getMilestones('project-1'),
    expect: () => [
      MilestoneState(
        collection: MilestoneCollectionLoading(previous: tSnapshot),
      ),
      MilestoneState(
        collection: MilestoneCollectionSuccess(tSnapshot),
      ),
    ],
    verify: (_) {
      verify(() => mockGetMilestones('project-1')).called(1);
    },
  );

  blocTest<MilestoneCubit, MilestoneState>(
    'getMilestones keeps the last loaded snapshot visible when refresh fails',
    build: () {
      when(() => mockGetMilestones(any())).thenAnswer(
        (_) async => const Left(tFailure),
      );
      return cubit;
    },
    seed: () => MilestoneState(
      collection: MilestoneCollectionSuccess(tSnapshot),
    ),
    act: (cubit) => cubit.getMilestones('project-1'),
    expect: () => [
      MilestoneState(
        collection: MilestoneCollectionLoading(previous: tSnapshot),
      ),
      MilestoneState(
        collection: MilestoneCollectionFailure(
          previous: tSnapshot,
          title: 'Error Fetching Milestones',
          message: tFailure.errorMessage,
        ),
      ),
    ],
  );

  blocTest<MilestoneCubit, MilestoneState>(
    'getMilestoneById emits detail loading then success',
    build: () {
      when(() => mockGetMilestoneById(any())).thenAnswer(
        (_) async => Right(tMilestone),
      );
      return cubit;
    },
    act: (cubit) => cubit.getMilestoneById(
      projectId: 'project-1',
      milestoneId: 'milestone-1',
    ),
    expect: () => [
      const MilestoneState(
        detail: MilestoneDetailLoading(),
      ),
      MilestoneState(
        detail: MilestoneDetailSuccess(tMilestone),
      ),
    ],
  );

  blocTest<MilestoneCubit, MilestoneState>(
    'deleteMilestone keeps the visible snapshot while'
    ' the mutation is in flight',
    build: () {
      when(() => mockDeleteMilestone(any())).thenAnswer(
        (_) async => const Right(null),
      );
      return cubit;
    },
    seed: () => MilestoneState(
      collection: MilestoneCollectionSuccess(tSnapshot),
    ),
    act: (cubit) => cubit.deleteMilestone(
      projectId: 'project-1',
      milestoneId: 'milestone-2',
    ),
    expect: () => [
      MilestoneState(
        collection: MilestoneCollectionSuccess(tSnapshot),
        mutation: const MilestoneMutationInFlight(
          type: MilestoneMutationType.delete,
          affectedMilestoneId: 'milestone-2',
        ),
      ),
      MilestoneState(
        collection: MilestoneCollectionSuccess(tSnapshot),
        mutation: const MilestoneMutationSuccess(
          type: MilestoneMutationType.delete,
          affectedMilestoneId: 'milestone-2',
        ),
      ),
    ],
  );

  blocTest<MilestoneCubit, MilestoneState>(
    'reorderMilestone uses the explicit reorder use case',
    build: () {
      when(() => mockReorderMilestone(any())).thenAnswer(
        (_) async => const Right(null),
      );
      return cubit;
    },
    seed: () => MilestoneState(
      collection: MilestoneCollectionSuccess(tSnapshot),
    ),
    act: (cubit) => cubit.reorderMilestone(
      projectId: 'project-1',
      milestoneId: 'milestone-2',
      previousMilestoneId: 'milestone-1',
      nextMilestoneId: null,
      expectedOrderVersion: tSnapshot.orderVersion,
    ),
    expect: () => [
      MilestoneState(
        collection: MilestoneCollectionSuccess(tSnapshot),
        mutation: const MilestoneMutationInFlight(
          type: MilestoneMutationType.reorder,
          affectedMilestoneId: 'milestone-2',
        ),
      ),
      MilestoneState(
        collection: MilestoneCollectionSuccess(tSnapshot),
        mutation: const MilestoneMutationSuccess(
          type: MilestoneMutationType.reorder,
          affectedMilestoneId: 'milestone-2',
        ),
      ),
    ],
    verify: (_) {
      verify(
        () => mockReorderMilestone(
          const ReorderMilestoneParams(
            projectId: 'project-1',
            milestoneId: 'milestone-2',
            previousMilestoneId: 'milestone-1',
            nextMilestoneId: null,
            expectedOrderVersion: 3,
          ),
        ),
      ).called(1);
      verifyNever(() => mockEditMilestone(any()));
    },
  );

  blocTest<MilestoneCubit, MilestoneState>(
    'collection failure does not overwrite an existing'
    ' mutation failure payload',
    build: () {
      when(() => mockGetMilestones(any())).thenAnswer(
        (_) async => const Left(tFailure),
      );
      return cubit;
    },
    seed: () => MilestoneState(
      collection: MilestoneCollectionSuccess(tSnapshot),
      mutation: const MilestoneMutationFailure(
        type: MilestoneMutationType.reorder,
        affectedMilestoneId: 'milestone-2',
        title: 'Milestone order changed',
        message: '[milestone-order-stale] Milestone order changed',
        statusCode: 'milestone-order-stale',
      ),
    ),
    act: (cubit) => cubit.getMilestones('project-1'),
    expect: () => [
      MilestoneState(
        collection: MilestoneCollectionLoading(previous: tSnapshot),
        mutation: const MilestoneMutationFailure(
          type: MilestoneMutationType.reorder,
          affectedMilestoneId: 'milestone-2',
          title: 'Milestone order changed',
          message: '[milestone-order-stale] Milestone order changed',
          statusCode: 'milestone-order-stale',
        ),
      ),
      MilestoneState(
        collection: MilestoneCollectionFailure(
          previous: tSnapshot,
          title: 'Error Fetching Milestones',
          message: tFailure.errorMessage,
        ),
        mutation: const MilestoneMutationFailure(
          type: MilestoneMutationType.reorder,
          affectedMilestoneId: 'milestone-2',
          title: 'Milestone order changed',
          message: '[milestone-order-stale] Milestone order changed',
          statusCode: 'milestone-order-stale',
        ),
      ),
    ],
  );

  test(
    'addMilestone does not emit a late success after the cubit closes',
    () async {
      final completer = Completer<Either<Failure, void>>();
      when(() => mockAddMilestone(any())).thenAnswer((_) => completer.future);
      final emittedStates = <MilestoneState>[];
      final subscription = cubit.stream.listen(emittedStates.add);

      final addFuture = cubit.addMilestone(tMilestone);
      await pumpEventQueue();

      expect(
        emittedStates,
        [
          const MilestoneState(
            mutation: MilestoneMutationInFlight(
              type: MilestoneMutationType.add,
            ),
          ),
        ],
      );

      await cubit.close();
      completer.complete(const Right(null));
      await addFuture;
      await pumpEventQueue();

      expect(
        emittedStates,
        [
          const MilestoneState(
            mutation: MilestoneMutationInFlight(
              type: MilestoneMutationType.add,
            ),
          ),
        ],
      );

      await subscription.cancel();
    },
  );

  test(
    'getMilestoneById does not emit a late detail state after the cubit closes',
    () async {
      final completer = Completer<Either<Failure, Milestone>>();
      when(
        () => mockGetMilestoneById(any()),
      ).thenAnswer((_) => completer.future);
      final emittedStates = <MilestoneState>[];
      final subscription = cubit.stream.listen(emittedStates.add);

      final loadFuture = cubit.getMilestoneById(
        projectId: 'project-1',
        milestoneId: 'milestone-1',
      );
      await pumpEventQueue();

      expect(
        emittedStates,
        [
          const MilestoneState(
            detail: MilestoneDetailLoading(),
          ),
        ],
      );

      await cubit.close();
      completer.complete(Right(tMilestone));
      await loadFuture;
      await pumpEventQueue();

      expect(
        emittedStates,
        [
          const MilestoneState(
            detail: MilestoneDetailLoading(),
          ),
        ],
      );

      await subscription.cancel();
    },
  );
}
