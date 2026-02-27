import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/add_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/delete_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/edit_milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestone_by_id.dart';
import 'package:milestone/src/project/features/milestone/domain/usecases/get_milestones.dart';

part 'milestone_state.dart';

class MilestoneCubit extends Cubit<MilestoneState> {
  MilestoneCubit({
    required AddMilestone addMilestone,
    required DeleteMilestone deleteMilestone,
    required EditMilestone editMilestone,
    required GetMilestoneById getMilestoneById,
    required GetMilestones getMilestones,
  })  : _addMilestone = addMilestone,
        _deleteMilestone = deleteMilestone,
        _editMilestone = editMilestone,
        _getMilestoneById = getMilestoneById,
        _getMilestones = getMilestones,
        super(const MilestoneInitial());

  final AddMilestone _addMilestone;
  final DeleteMilestone _deleteMilestone;
  final EditMilestone _editMilestone;
  final GetMilestoneById _getMilestoneById;
  final GetMilestones _getMilestones;

  Future<void> addMilestone(Milestone milestone) async {
    emit(const MilestoneLoading());
    final result = await _addMilestone(milestone);
    result.fold(
      (failure) => emit(
        MilestoneError(
          title: 'Error Adding Milestone',
          message: failure.errorMessage,
        ),
      ),
      (milestoneID) => emit(const MilestoneAdded()),
    );
  }

  Future<void> deleteMilestone({
    required String projectId,
    required String milestoneId,
  }) async {
    emit(const MilestoneLoading());
    final result = await _deleteMilestone(
      DeleteMilestoneParams(projectId: projectId, milestoneId: milestoneId),
    );
    result.fold(
      (failure) => emit(
        MilestoneError(
          title: 'Error Deleting Milestone',
          message: failure.errorMessage,
        ),
      ),
      (_) => emit(const MilestoneDeleted()),
    );
  }

  Future<void> editMilestone({
    required String projectId,
    required String milestoneId,
    required DataMap updatedMilestone,
  }) async {
    emit(const MilestoneLoading());
    final result = await _editMilestone(
      EditMilestoneParams(
        projectId: projectId,
        milestoneId: milestoneId,
        updatedMilestone: updatedMilestone,
      ),
    );
    result.fold(
      (failure) => emit(
        MilestoneError(
          title: 'Error Editing Milestone',
          message: failure.errorMessage,
        ),
      ),
      (_) => emit(const MilestoneUpdated()),
    );
  }

  Future<void> getMilestoneById({
    required String projectId,
    required String milestoneId,
  }) async {
    emit(const MilestoneLoading());
    final result = await _getMilestoneById(
      GetMilestoneByIdParams(projectId: projectId, milestoneId: milestoneId),
    );
    result.fold(
      (failure) => emit(
        MilestoneError(
          title: 'Error Fetching Milestone',
          message: failure.errorMessage,
        ),
      ),
      (milestone) => emit(MilestoneLoaded(milestone)),
    );
  }

  Future<void> getMilestones(String projectId) async {
    emit(const MilestoneLoading());
    final result = await _getMilestones(projectId);
    result.fold(
      (failure) => emit(
        MilestoneError(
          title: 'Error Fetching Milestones',
          message: failure.errorMessage,
        ),
      ),
      (milestones) => emit(MilestonesLoaded(milestones)),
    );
  }
}
