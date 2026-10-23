import 'package:equatable/equatable.dart';

class ClientWorkspaceSnapshotLayout extends Equatable {
  const ClientWorkspaceSnapshotLayout({
    required this.clientId,
    required this.clientName,
    required this.totalSpent,
    required this.projectCount,
    this.clientImage,
  });

  final String clientId;
  final String clientName;
  final double totalSpent;
  final int projectCount;
  final String? clientImage;

  @override
  List<Object?> get props => [
    clientId,
    clientName,
    totalSpent,
    projectCount,
    clientImage,
  ];
}
