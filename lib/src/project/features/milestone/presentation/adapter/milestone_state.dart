part of 'milestone_cubit.dart';

sealed class MilestoneCollectionState extends Equatable {
  const MilestoneCollectionState();

  @override
  List<Object?> get props => const [];
}

final class MilestoneCollectionInitial extends MilestoneCollectionState {
  const MilestoneCollectionInitial();
}

final class MilestoneCollectionLoading extends MilestoneCollectionState {
  const MilestoneCollectionLoading({this.previous});

  final MilestoneCollectionSnapshot? previous;

  @override
  List<Object?> get props => [previous];
}

final class MilestoneCollectionSuccess extends MilestoneCollectionState {
  const MilestoneCollectionSuccess(this.snapshot);

  final MilestoneCollectionSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

final class MilestoneCollectionFailure extends MilestoneCollectionState {
  const MilestoneCollectionFailure({
    required this.title,
    required this.message,
    this.previous,
  });

  final MilestoneCollectionSnapshot? previous;
  final String title;
  final String message;

  @override
  List<Object?> get props => [previous, title, message];
}

sealed class MilestoneDetailState extends Equatable {
  const MilestoneDetailState();

  @override
  List<Object?> get props => const [];
}

final class MilestoneDetailIdle extends MilestoneDetailState {
  const MilestoneDetailIdle();
}

final class MilestoneDetailLoading extends MilestoneDetailState {
  const MilestoneDetailLoading();
}

final class MilestoneDetailSuccess extends MilestoneDetailState {
  const MilestoneDetailSuccess(this.milestone);

  final Milestone milestone;

  @override
  List<Object?> get props => [milestone];
}

final class MilestoneDetailFailure extends MilestoneDetailState {
  const MilestoneDetailFailure({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  List<Object?> get props => [title, message];
}

enum MilestoneMutationType { add, edit, delete, reorder }

sealed class MilestoneMutationState extends Equatable {
  const MilestoneMutationState();

  @override
  List<Object?> get props => const [];
}

final class MilestoneMutationIdle extends MilestoneMutationState {
  const MilestoneMutationIdle();
}

final class MilestoneMutationInFlight extends MilestoneMutationState {
  const MilestoneMutationInFlight({
    required this.type,
    this.affectedMilestoneId,
  });

  final MilestoneMutationType type;
  final String? affectedMilestoneId;

  @override
  List<Object?> get props => [type, affectedMilestoneId];
}

final class MilestoneMutationSuccess extends MilestoneMutationState {
  const MilestoneMutationSuccess({
    required this.type,
    this.affectedMilestoneId,
  });

  final MilestoneMutationType type;
  final String? affectedMilestoneId;

  @override
  List<Object?> get props => [type, affectedMilestoneId];
}

final class MilestoneMutationFailure extends MilestoneMutationState {
  const MilestoneMutationFailure({
    required this.type,
    required this.title,
    required this.message,
    required this.statusCode,
    this.affectedMilestoneId,
  });

  final MilestoneMutationType type;
  final String? affectedMilestoneId;
  final String title;
  final String message;
  final String statusCode;

  @override
  List<Object?> get props => [
    type,
    affectedMilestoneId,
    title,
    message,
    statusCode,
  ];
}

class MilestoneState extends Equatable {
  const MilestoneState({
    this.collection = const MilestoneCollectionInitial(),
    this.detail = const MilestoneDetailIdle(),
    this.mutation = const MilestoneMutationIdle(),
  });

  final MilestoneCollectionState collection;
  final MilestoneDetailState detail;
  final MilestoneMutationState mutation;

  MilestoneCollectionSnapshot? get latestCollectionSnapshot {
    return switch (collection) {
      MilestoneCollectionSuccess(:final snapshot) => snapshot,
      MilestoneCollectionLoading(:final previous) => previous,
      MilestoneCollectionFailure(:final previous) => previous,
      _ => null,
    };
  }

  bool get isMutating => mutation is MilestoneMutationInFlight;

  MilestoneState copyWith({
    MilestoneCollectionState? collection,
    MilestoneDetailState? detail,
    MilestoneMutationState? mutation,
  }) {
    return MilestoneState(
      collection: collection ?? this.collection,
      detail: detail ?? this.detail,
      mutation: mutation ?? this.mutation,
    );
  }

  @override
  List<Object?> get props => [collection, detail, mutation];
}
