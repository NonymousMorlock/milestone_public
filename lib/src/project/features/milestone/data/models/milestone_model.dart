import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';

class MilestoneModel extends Milestone {
  const MilestoneModel({
    required super.id,
    required super.title,
    required super.projectId,
    required super.dateCreated,
    super.rank,
    super.amountPaid,
    super.startDate,
    super.endDate,
    super.lastUpdated,
    super.notes,
    super.shortDescription,
  });

  MilestoneModel.empty()
    : this(
        id: 'Test String',
        projectId: 'Test String',
        title: 'Test String',
        shortDescription: 'Test String',
        amountPaid: 1,
        dateCreated: DateTime.now(),
      );

  MilestoneModel.fromMap(DataMap map)
    : this(
        id: map['id'] as String,
        projectId: map['projectId'] as String,
        title: map['title'] as String,
        shortDescription: map['shortDescription'] as String?,
        notes: map['notes'] != null
            ? List<String>.from(map['notes'] as List<dynamic>)
            : [],
        amountPaid: (map['amountPaid'] as num?)?.toDouble(),
        startDate: (map['startDate'] as Timestamp?)?.toDate(),
        rank: (map['rank'] as num?)?.toDouble() ?? 0.0,
        endDate: (map['endDate'] as Timestamp?)?.toDate(),
        dateCreated: (map['dateCreated'] as Timestamp).toDate(),
        lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
      );
  static const _sentinel = Object();

  MilestoneModel copyWith({
    String? id,
    String? projectId,
    String? title,
    double? rank,
    DateTime? dateCreated,
    Object? shortDescription = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    Object? notes = _sentinel,
    Object? amountPaid = _sentinel,
    Object? lastUpdated = _sentinel,
  }) {
    return MilestoneModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      shortDescription: identical(shortDescription, _sentinel)
          ? this.shortDescription
          : shortDescription as String?,
      notes: identical(notes, _sentinel) ? this.notes : notes! as List<String>,
      amountPaid: identical(amountPaid, _sentinel)
          ? this.amountPaid
          : (amountPaid as num?)?.toDouble(),
      dateCreated: dateCreated ?? this.dateCreated,
      rank: rank ?? this.rank,
      startDate: identical(startDate, _sentinel)
          ? this.startDate
          : startDate as DateTime?,
      endDate: identical(endDate, _sentinel)
          ? this.endDate
          : endDate as DateTime?,
      lastUpdated: identical(lastUpdated, _sentinel)
          ? this.lastUpdated
          : lastUpdated as DateTime?,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'projectId': projectId,
      'title': title,
      'shortDescription': shortDescription,
      'rank': rank,
      'startDate': startDate,
      'endDate': endDate,
      'notes': notes,
      'amountPaid': amountPaid,
      'dateCreated': dateCreated,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
