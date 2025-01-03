import 'package:equatable/equatable.dart';

class Client extends Equatable {
  const Client({
    required this.id,
    required this.name,
    required this.totalSpent,
    required this.dateCreated,
    this.lastUpdated,
    this.imageIsFile = false,
    this.image,
  });

  Client.empty()
      : this(
          id: 'Test String',
          name: 'Test String',
          totalSpent: 1,
          dateCreated: DateTime.now(),
        );

  @override
  String toString() {
    return 'Client{id: $id, name: $name, totalSpent: $totalSpent, '
        'imageIsFile: $imageIsFile, image: $image, '
        'dateCreated: $dateCreated, lastUpdated: $lastUpdated}';
  }

  final String id;
  final String name;
  final double totalSpent;
  final bool imageIsFile;
  final String? image;
  final DateTime dateCreated;
  final DateTime? lastUpdated;

  @override
  List<Object?> get props => [id, name];
}
