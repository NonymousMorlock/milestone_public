import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/date_extensions.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/presentation/widgets/connector.dart';
import 'package:milestone/src/project/features/milestone/presentation/widgets/node.dart';

/// A widget that represents a node in a graphical interface.
///
/// This widget is a small circular container with a fixed size and red color.
/// It can be used to represent a point or node in a layout.
class MilestoneEntry extends StatelessWidget {
  /// Creates a [MilestoneEntry] widget.
  ///
  /// The [milestone] parameter is required and represents the milestone to
  /// display.
  ///
  /// The [isLast] parameter is optional and indicates whether this is the
  /// last milestone in the list.
  const MilestoneEntry({
    required this.milestone,
    required this.sequence,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.showDragHandle,
    super.key,
    this.isLast = false,
    this.onEdit,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  final Milestone milestone;
  final int sequence;
  final bool isLast;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool showDragHandle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  String _dateSummary() {
    if (milestone.startDate != null && milestone.endDate != null) {
      return '${milestone.startDate!.yMd} - ${milestone.endDate!.yMd}';
    }
    if (milestone.startDate != null) {
      return 'Starts ${milestone.startDate!.yMd}';
    }
    if (milestone.endDate != null) {
      return 'Ends ${milestone.endDate!.yMd}';
    }
    return 'Created ${milestone.dateCreated.yMd}';
  }

  @override
  Widget build(BuildContext context) {
    final moneyFormat = NumberFormat.simpleCurrency();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: .start,
        spacing: 10,
        children: [
          Column(
            mainAxisSize: .min,
            children: [
              const Baseline(
                baseline: 39,
                baselineType: .alphabetic,
                child: Node(),
              ),
              if (!isLast) const Expanded(child: Connector()),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                // Toolbar
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: .center,
                  children: [
                    if (showDragHandle)
                      Tooltip(
                        message: 'Drag to reorder',
                        child: ReorderableDragStartListener(
                          index: sequence - 1,
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: canMoveUp ? onMoveUp : null,
                      tooltip: 'Move up',
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                    IconButton(
                      onPressed: canMoveDown ? onMoveDown : null,
                      tooltip: 'Move down',
                      icon: const Icon(Icons.arrow_downward_rounded),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit milestone',
                      icon: const Icon(Icons.edit_rounded),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Delete milestone',
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          '#$sequence',
                          style: context.textTheme.labelLarge?.copyWith(
                            color: context.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      milestone.title,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: .w600,
                      ),
                    ),
                    if (milestone.shortDescription case final description?)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          description,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const Gap(10),
                Text(
                  _dateSummary(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        milestone.amountPaid != null
                            ? moneyFormat.format(milestone.amountPaid)
                            : 'No payment recorded',
                      ),
                    ),
                    if (milestone.notes.isNotEmpty)
                      Chip(
                        label: Text('${milestone.notes.length} notes'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
