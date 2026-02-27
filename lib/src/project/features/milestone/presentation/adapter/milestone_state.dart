part of 'milestone_cubit.dart';

abstract class MilestoneState extends Equatable {
  const MilestoneState();

  @override
  List<Object> get props => [];
}

class MilestoneInitial extends MilestoneState {
  const MilestoneInitial();
}

// This state would work when we go to a project details page, and we are
// fetching the project details, and the milestones simultaneously.
// We will be able to show a separate loading state for the milestones.

// It would also work when we are fetching a milestone's details, and we are
// just on the milestone details page, so there's no need for a separate
// loading state for getMilestoneById.

// It would also work for add, delete, and edit milestone, as these things
// will happen independently of any other state.
// For example, adding a new milestone will happen in a project details page,
// and we will be able to show a separate loading state for the
// milestones section.
class MilestoneLoading extends MilestoneState {
  const MilestoneLoading();
}

class MilestoneLoaded extends MilestoneState {
  const MilestoneLoaded(this.milestone);

  final Milestone milestone;

  @override
  List<Object> get props => [milestone];
}

class MilestonesLoaded extends MilestoneState {
  const MilestonesLoaded(this.milestones);

  final List<Milestone> milestones;

  @override
  List<Object> get props => [milestones];
}

class MilestoneAdded extends MilestoneState {
  const MilestoneAdded();
}

class MilestoneDeleted extends MilestoneState {
  const MilestoneDeleted();
}

class MilestoneUpdated extends MilestoneState {
  const MilestoneUpdated();
}

class MilestoneError extends MilestoneState {
  const MilestoneError({required this.message, required this.title});

  final String message;
  final String title;

  @override
  List<Object> get props => [title, message];
}
