import 'package:equatable/equatable.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

enum ProjectWorkspaceStatusTone { neutral, positive, warning, critical }

class ProjectWorkspaceStatusLayout extends Equatable {
  const ProjectWorkspaceStatusLayout({
    required this.label,
    required this.supportingCopy,
    required this.semanticTone,
  });

  factory ProjectWorkspaceStatusLayout.fromProject(
    Project project, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    if (project.isPendingDeletion) {
      return const ProjectWorkspaceStatusLayout(
        label: 'Pending deletion',
        supportingCopy:
            'This project is locked while milestones, rollups, and owned media'
            ' finish cleaning up.',
        semanticTone: .warning,
      );
    }

    final endDate = project.endDate;
    if (endDate != null && !_isAfterCalendarDay(endDate, effectiveNow)) {
      return const ProjectWorkspaceStatusLayout(
        label: 'Completed',
        supportingCopy:
            'Delivery is complete. The workspace now reflects the finished'
            ' engagement record.',
        semanticTone: .positive,
      );
    }

    if (endDate != null && _isAfterCalendarDay(endDate, effectiveNow)) {
      return const ProjectWorkspaceStatusLayout(
        label: 'Scheduled end',
        supportingCopy:
            'A project end date is already booked, so this engagement is'
            ' moving toward a planned close-out.',
        semanticTone: .neutral,
      );
    }

    final deadline = project.deadline;
    if (deadline != null && !_isAfterCalendarDay(deadline, effectiveNow)) {
      return const ProjectWorkspaceStatusLayout(
        label: 'Overdue',
        supportingCopy:
            'The deadline has passed. Review delivery risk and milestone'
            ' follow-through now.',
        semanticTone: .critical,
      );
    }

    if (deadline != null &&
        deadline.difference(_startOfDay(effectiveNow)).inDays <= 7) {
      return const ProjectWorkspaceStatusLayout(
        label: 'Due soon',
        supportingCopy:
            'The deadline is within the next week. Keep payment and delivery'
            ' checkpoints in view.',
        semanticTone: .warning,
      );
    }

    if (!project.isOneTime) {
      return const ProjectWorkspaceStatusLayout(
        label: 'Ongoing',
        supportingCopy:
            'This is a continuous engagement without a fixed one-off finish.'
            ' Track delivery and payment cadence together.',
        semanticTone: .neutral,
      );
    }

    return const ProjectWorkspaceStatusLayout(
      label: 'Active',
      supportingCopy:
          'This engagement is in motion. Track delivery, finance, and context'
          ' from one workspace.',
      semanticTone: .neutral,
    );
  }

  final String label;
  final String supportingCopy;
  final ProjectWorkspaceStatusTone semanticTone;

  static DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isAfterCalendarDay(DateTime value, DateTime reference) {
    return _startOfDay(value).isAfter(_startOfDay(reference));
  }

  @override
  List<Object?> get props => [label, supportingCopy, semanticTone];
}
