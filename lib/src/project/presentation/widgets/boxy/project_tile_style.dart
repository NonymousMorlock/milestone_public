import 'package:equatable/equatable.dart';

class ProjectTileStyle extends Equatable {
  const ProjectTileStyle({
    this.clientInset = 16.0,
    this.gapHeight = 8.0,
  });

  /// How far to the left the seller is inset
  final double clientInset;

  /// The size of the gap between the title and description
  final double gapHeight;

  @override
  List<Object?> get props => [clientInset, gapHeight];
}
