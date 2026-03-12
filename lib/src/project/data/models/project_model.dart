import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/data/models/u_r_l_model.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/entities/u_r_l.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.userId,
    required super.projectName,
    required super.clientName,
    required super.shortDescription,
    required super.budget,
    required super.projectType,
    required super.totalPaid,
    required super.numberOfMilestonesSoFar,
    required super.clientId,
    required super.startDate,
    super.imageIsFile = false,
    super.longDescription,
    super.notes,
    super.urls,
    super.isFixed,
    super.isOneTime,
    super.imagesModeRegistry,
    super.tools,
    super.image,
    super.images,
    super.deadline,
    super.endDate,
    super.lastUpdated,
  });

  ProjectModel.empty()
      : this(
          id: 'Test String',
          userId: 'Test String',
          projectName: 'Test String',
          clientName: 'Test String',
          shortDescription: 'Test String',
          longDescription: 'Test String',
          notes: [],
          urls: [],
          budget: 1,
          isFixed: true,
          isOneTime: true,
          projectType: 'Test String',
          tools: [],
          totalPaid: 1,
          numberOfMilestonesSoFar: 1,
          images: [],
          clientId: 'Test String',
          startDate: DateTime.now(),
        );

  ProjectModel.fromMap(DataMap map)
      : this(
          id: map['id'] as String,
          userId: map['userId'] as String,
          projectName: map['projectName'] as String,
          clientName: map['clientName'] as String,
          shortDescription: map['shortDescription'] as String,
          longDescription: map['longDescription'] as String?,
          notes: map['notes'] != null
              ? List<String>.from(map['notes'] as List<dynamic>)
              : [],
          urls: map['urls'] != null
              ? List<DataMap>.from(map['urls'] as List<dynamic>)
                  .map(URLModel.fromMap)
                  .toList()
              : [],
          budget: (map['budget'] as num).toDouble(),
          isFixed: map['isFixed'] as bool? ?? true,
          isOneTime: map['isOneTime'] as bool? ?? true,
          projectType: map['projectType'] as String,
          tools: map['tools'] != null
              ? List<String>.from(map['tools'] as List<dynamic>)
              : [],
          totalPaid: (map['totalPaid'] as num).toDouble(),
          numberOfMilestonesSoFar:
              (map['numberOfMilestonesSoFar'] as num).toInt(),
          image: map['image'] as String?,
          images: map['images'] != null
              ? List<String>.from(map['images'] as List<dynamic>)
              : [],
          imagesModeRegistry: map['images'] != null
              ? (map['images'] as List).map((_) => false).toList()
              : [],
          clientId: map['clientId'] as String,
          startDate: (map['startDate'] as Timestamp).toDate(),
          deadline: (map['deadline'] as Timestamp?)?.toDate(),
          endDate: (map['endDate'] as Timestamp?)?.toDate(),
          lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
        );

  ProjectModel copyWith({
    String? id,
    String? userId,
    String? projectName,
    String? clientName,
    String? shortDescription,
    String? longDescription,
    List<String>? notes,
    bool? imageIsFile,
    List<bool>? imagesModeRegistry,
    List<URL>? urls,
    double? budget,
    bool? isFixed,
    bool? isOneTime,
    String? projectType,
    List<String>? tools,
    double? totalPaid,
    int? numberOfMilestonesSoFar,
    String? image,
    List<String>? images,
    String? clientId,
    DateTime? startDate,
    DateTime? deadline,
    DateTime? endDate,
    DateTime? lastUpdated,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectName: projectName ?? this.projectName,
      clientName: clientName ?? this.clientName,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      notes: notes ?? this.notes,
      imageIsFile: imageIsFile ?? this.imageIsFile,
      urls: urls ?? this.urls,
      budget: budget ?? this.budget,
      imagesModeRegistry: imagesModeRegistry ?? this.imagesModeRegistry,
      isFixed: isFixed ?? this.isFixed,
      isOneTime: isOneTime ?? this.isOneTime,
      projectType: projectType ?? this.projectType,
      tools: tools ?? this.tools,
      totalPaid: totalPaid ?? this.totalPaid,
      numberOfMilestonesSoFar:
          numberOfMilestonesSoFar ?? this.numberOfMilestonesSoFar,
      image: image ?? this.image,
      images: images ?? this.images,
      clientId: clientId ?? this.clientId,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      endDate: endDate ?? this.endDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'projectName': projectName,
      'clientName': clientName,
      'shortDescription': shortDescription,
      'longDescription': longDescription,
      'notes': notes,
      'urls': urls.map((url) => (url as URLModel).toMap()).toList(),
      'budget': budget,
      'isFixed': isFixed,
      'isOneTime': isOneTime,
      'projectType': projectType,
      'tools': tools,
      'totalPaid': totalPaid,
      'numberOfMilestonesSoFar': numberOfMilestonesSoFar,
      'image': image,
      'images': images,
      'clientId': clientId,
      'startDate': Timestamp.fromDate(startDate),
      if (deadline != null) 'deadline': Timestamp.fromDate(deadline!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
    };
  }
}
