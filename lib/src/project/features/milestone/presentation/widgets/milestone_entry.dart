import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
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
  const MilestoneEntry(this.milestone, {this.isLast = false, super.key});

  /// Indicates whether this is the last milestone in the list.
  final bool isLast;

  /// The milestone to display.
  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Node(),
              if (!isLast) const Expanded(child: Connector()),
            ],
          ),
          const Gap(10),
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: GoogleFonts.roboto(fontSize: 16),
                ),
                const Gap(2),
                if (milestone.shortDescription != null)
                  Text(
                    milestone.shortDescription!,
                    style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
                  ),
                const Gap(2),
                // start - end date if available, else just start date if
                // available, else just end date if available, else date created
                Builder(
                  builder: (_) {
                    final dateBuilder = StringBuffer();
                    if (milestone.startDate != null) {
                      dateBuilder.write(milestone.startDate!.yMd);
                    }
                    if (milestone.endDate != null) {
                      dateBuilder
                        ..write(' - ')
                        ..write(milestone.endDate!.yMd);
                    }
                    if (dateBuilder.isEmpty) {
                      dateBuilder.write(milestone.dateCreated.yMd);
                    }
                    return Text(
                      dateBuilder.toString(),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
