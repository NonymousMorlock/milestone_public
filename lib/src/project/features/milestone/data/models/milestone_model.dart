import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';

class MilestoneModel extends Milestone {
  const MilestoneModel({
    required super.id,
    required super.title,
    required super.projectId,
    required super.dateCreated,
    super.index,
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
          amountPaid: (map['amountPaid'] as num).toDouble(),
          startDate: (map['startDate'] as Timestamp?)?.toDate(),
          index: map['index'] as num,
          endDate: (map['endDate'] as Timestamp?)?.toDate(),
          dateCreated: (map['dateCreated'] as Timestamp).toDate(),
          lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
        );

  MilestoneModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? shortDescription,
    DateTime? startDate,
    DateTime? endDate,
    num? index,
    List<String>? notes,
    double? amountPaid,
    DateTime? dateCreated,
    DateTime? lastUpdated,
  }) {
    return MilestoneModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      notes: notes ?? this.notes,
      amountPaid: amountPaid ?? this.amountPaid,
      dateCreated: dateCreated ?? this.dateCreated,
      index: index ?? this.index,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'projectId': projectId,
      'title': title,
      'shortDescription': shortDescription,
      'index': index,
      'startDate': startDate,
      'endDate': endDate,
      'notes': notes,
      'amountPaid': amountPaid,
      'dateCreated': dateCreated,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
