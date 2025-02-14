import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/domain/entities/client.dart';

class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.name,
    required super.totalSpent,
    required super.dateCreated,
    super.lastUpdated,
    super.image,
    super.imageIsFile,
  });

  ClientModel.empty()
      : this(
          id: 'Test String',
          name: 'Test String',
          totalSpent: 1,
          image: 'Test String',
          dateCreated: DateTime.now(),
        );

  ClientModel.fromMap(DataMap map)
      : this(
          id: map['id'] as String,
          name: map['name'] as String,
          totalSpent: (map['totalSpent'] as num).toDouble(),
          dateCreated: (map['dateCreated'] as Timestamp).toDate(),
          lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
          image: map['image'] as String?,
        );

  ClientModel copyWith({
    String? id,
    String? name,
    double? totalSpent,
    String? image,
    DateTime? dateCreated,
    bool? imageIsFile,
    DateTime? lastUpdated,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      totalSpent: totalSpent ?? this.totalSpent,
      image: image ?? this.image,
      dateCreated: dateCreated ?? this.dateCreated,
      imageIsFile: imageIsFile ?? this.imageIsFile,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'totalSpent': totalSpent,
      'image': image,
      'dateCreated': FieldValue.serverTimestamp(),
    };
  }
}
