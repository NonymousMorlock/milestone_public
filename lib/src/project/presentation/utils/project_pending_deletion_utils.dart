import 'package:milestone/src/project/domain/entities/project.dart';

Project markProjectAsPendingDeletion(
  Project baseline, {
  DateTime? deletionRequestedAt,
}) {
  final effectiveDeletionRequestedAt =
      deletionRequestedAt ?? baseline.deletionRequestedAt ?? DateTime.now();

  return baseline.copyWith(deletionRequestedAt: effectiveDeletionRequestedAt);
}
