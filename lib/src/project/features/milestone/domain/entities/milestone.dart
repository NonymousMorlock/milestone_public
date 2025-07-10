import 'package:equatable/equatable.dart';

class Milestone extends Equatable {
  const Milestone({
    required this.id,
    required this.title,
    required this.projectId,
    required this.dateCreated,
    this.index = -1,
    this.amountPaid,
    this.startDate,
    this.endDate,
    this.lastUpdated,
    this.notes = const [],
    this.shortDescription,
  });

  Milestone.empty()
      : this(
          id: 'Test String',
          title: 'Test String',
          projectId: 'Test String',
          shortDescription: 'Test String',
          amountPaid: 1,
          dateCreated: DateTime.now(),
        );

  @override
  String toString() {
    return 'Milestone{id: $id, projectId: $projectId, title: $title, '
        'shortDescription: $shortDescription, notes: $notes, '
        'amountPaid: $amountPaid, date: $dateCreated, '
        'lastUpdated: $lastUpdated}';
  }

  /// The unique identifier for this milestone.
  final String id;

  /// The unique identifier for the project this milestone belongs to.
  final String projectId;

  /// The title of this milestone.
  final String title;

  /// A short description of this milestone.
  final String? shortDescription;

  /// Notes for this milestone.
  final List<String> notes;

  /// A user-defined ordering field that you control manually through
  /// reordering.
  final num index;

  /// The actual intended start date of this milestone.
  ///
  /// Key for chronological ordering and tracking.
  final DateTime? startDate;

  /// The actual intended end date of this milestone.
  ///
  /// Key for chronological ordering and tracking.
  ///
  /// If this is null, the milestone is ongoing.
  final DateTime? endDate;

  /// The amount paid for this milestone.
  final double? amountPaid;

  /// When the milestone was created in the system. Useful for tracking
  /// activity.
  final DateTime dateCreated;

  /// Last modified date, useful for auditing or logging changes.
  final DateTime? lastUpdated;

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        shortDescription,
        ...notes,
        index,
        startDate,
        endDate,
        amountPaid,
        dateCreated,
        lastUpdated,
      ];
}
