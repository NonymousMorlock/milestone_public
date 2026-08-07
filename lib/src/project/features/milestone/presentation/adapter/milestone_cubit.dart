import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone_collection_snapshot.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/add_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/delete_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/edit_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestone_by_id.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestones.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/reorder_milestone.dart';

part 'milestone_state.dart';

class MilestoneCubit extends Cubit<MilestoneState> {
  MilestoneCubit({
    required AddMilestone addMilestone,
    required DeleteMilestone deleteMilestone,
    required EditMilestone editMilestone,
    required ReorderMilestone reorderMilestone,
    required GetMilestoneById getMilestoneById,
    required GetMilestones getMilestones,
  }) : _addMilestone = addMilestone,
       _deleteMilestone = deleteMilestone,
       _editMilestone = editMilestone,
       _reorderMilestone = reorderMilestone,
       _getMilestoneById = getMilestoneById,
       _getMilestones = getMilestones,
       super(const MilestoneState());

  final AddMilestone _addMilestone;
  final DeleteMilestone _deleteMilestone;
  final EditMilestone _editMilestone;
  final ReorderMilestone _reorderMilestone;
  final GetMilestoneById _getMilestoneById;
  final GetMilestones _getMilestones;

  Future<void> addMilestone(Milestone milestone) async {
    emit(
      state.copyWith(
        mutation: const MilestoneMutationInFlight(
          type: MilestoneMutationType.add,
        ),
      ),
    );

    final result = await _addMilestone(milestone);
    result.fold(
      (failure) => emit(
        state.copyWith(
          mutation: MilestoneMutationFailure(
            type: MilestoneMutationType.add,
            title: 'Error Adding Milestone',
            message: failure.errorMessage,
            statusCode: failure.statusCode,
          ),
        ),
      ),
      (_) => emit(
        state.copyWith(
          mutation: const MilestoneMutationSuccess(
            type: MilestoneMutationType.add,
          ),
        ),
      ),
    );
  }

  Future<void> deleteMilestone({
    required String projectId,
    required String milestoneId,
  }) async {
    emit(
      state.copyWith(
        mutation: MilestoneMutationInFlight(
          type: MilestoneMutationType.delete,
          affectedMilestoneId: milestoneId,
        ),
      ),
    );
    final result = await _deleteMilestone(
      DeleteMilestoneParams(projectId: projectId, milestoneId: milestoneId),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          mutation: MilestoneMutationFailure(
            type: MilestoneMutationType.delete,
            affectedMilestoneId: milestoneId,
            title: 'Error Deleting Milestone',
            message: failure.errorMessage,
            statusCode: failure.statusCode,
          ),
        ),
      ),
      (_) => emit(
        state.copyWith(
          mutation: MilestoneMutationSuccess(
            type: MilestoneMutationType.delete,
            affectedMilestoneId: milestoneId,
          ),
        ),
      ),
    );
  }

  Future<void> editMilestone({
    required String projectId,
    required String milestoneId,
    required DataMap updatedMilestone,
  }) async {
    emit(
      state.copyWith(
        mutation: MilestoneMutationInFlight(
          type: MilestoneMutationType.edit,
          affectedMilestoneId: milestoneId,
        ),
      ),
    );

    final result = await _editMilestone(
      EditMilestoneParams(
        projectId: projectId,
        milestoneId: milestoneId,
        updatedMilestone: updatedMilestone,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          mutation: MilestoneMutationFailure(
            type: MilestoneMutationType.edit,
            affectedMilestoneId: milestoneId,
            title: 'Error Editing Milestone',
            message: failure.errorMessage,
            statusCode: failure.statusCode,
          ),
        ),
      ),
      (_) => emit(
        state.copyWith(
          mutation: MilestoneMutationSuccess(
            type: MilestoneMutationType.edit,
            affectedMilestoneId: milestoneId,
          ),
        ),
      ),
    );
  }

  Future<void> getMilestoneById({
    required String projectId,
    required String milestoneId,
  }) async {
    emit(
      state.copyWith(
        detail: const MilestoneDetailLoading(),
      ),
    );
    final result = await _getMilestoneById(
      GetMilestoneByIdParams(projectId: projectId, milestoneId: milestoneId),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          detail: MilestoneDetailFailure(
            title: 'Error Fetching Milestone',
            message: failure.errorMessage,
          ),
        ),
      ),
      (milestone) => emit(
        state.copyWith(
          detail: MilestoneDetailSuccess(milestone),
        ),
      ),
    );
  }

  Future<void> getMilestones(String projectId) async {
    final previousSnapshot = state.latestCollectionSnapshot;
    emit(
      state.copyWith(
        collection: MilestoneCollectionLoading(previous: previousSnapshot),
      ),
    );
    final result = await _getMilestones(projectId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          collection: MilestoneCollectionFailure(
            previous: state.latestCollectionSnapshot,
            title: 'Error Fetching Milestones',
            message: failure.errorMessage,
          ),
        ),
      ),
      (snapshot) => emit(
        state.copyWith(
          collection: MilestoneCollectionSuccess(snapshot),
        ),
      ),
    );
  }

  Future<void> reorderMilestone({
    required String projectId,
    required String milestoneId,
    required String? previousMilestoneId,
    required String? nextMilestoneId,
    required int expectedOrderVersion,
  }) async {
    emit(
      state.copyWith(
        mutation: MilestoneMutationInFlight(
          type: MilestoneMutationType.reorder,
          affectedMilestoneId: milestoneId,
        ),
      ),
    );

    final result = await _reorderMilestone(
      ReorderMilestoneParams(
        projectId: projectId,
        milestoneId: milestoneId,
        previousMilestoneId: previousMilestoneId,
        nextMilestoneId: nextMilestoneId,
        expectedOrderVersion: expectedOrderVersion,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          mutation: MilestoneMutationFailure(
            type: MilestoneMutationType.reorder,
            affectedMilestoneId: milestoneId,
            title: failure.statusCode == 'milestone-order-stale'
                ? 'Milestone order changed'
                : 'Error Reordering Milestone',
            message: failure.errorMessage,
            statusCode: failure.statusCode,
          ),
        ),
      ),
      (_) => emit(
        state.copyWith(
          mutation: MilestoneMutationSuccess(
            type: MilestoneMutationType.reorder,
            affectedMilestoneId: milestoneId,
          ),
        ),
      ),
    );
  }

  void clearMutationFeedback() {
    emit(state.copyWith(mutation: const MilestoneMutationIdle()));
  }

  @override
  void emit(MilestoneState state) {
    if (isClosed) return;
    super.emit(state);
  }
}
