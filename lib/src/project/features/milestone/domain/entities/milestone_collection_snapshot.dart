import 'package:equatable/equatable.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';

class MilestoneCollectionSnapshot extends Equatable {
  const MilestoneCollectionSnapshot({
    required this.milestones,
    required this.orderVersion,
  });

  final List<Milestone> milestones;
  final int orderVersion;

  @override
  List<Object?> get props => [orderVersion, ...milestones];
}
