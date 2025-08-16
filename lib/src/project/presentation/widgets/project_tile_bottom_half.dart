import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milestone/core/extensions/date_extensions.dart';
import 'package:milestone/core/extensions/double_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/app/providers/expandable_card_controller.dart';
import 'package:milestone/src/project/presentation/widgets/project_info_tile.dart';
import 'package:provider/provider.dart';

class ProjectTileBottomHalf extends StatefulWidget {
  ProjectTileBottomHalf(
    this.project, {
    dynamic identifier,
    super.key,
  }) : identifier = identifier ?? project.id;

  final Project project;
  final dynamic identifier;

  @override
  ProjectTileBottomHalfState createState() => ProjectTileBottomHalfState();
}

class ProjectTileBottomHalfState extends State<ProjectTileBottomHalf>
    with TickerProviderStateMixin {
  late AnimationController anim;
  int expanded = 0;

  ExpandableCardController? controller;

  @override
  void initState() {
    super.initState();
    try {
      controller = context.read<ExpandableCardController>();
    } on Exception catch (_) {}

    anim = AnimationController.unbounded(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    anim.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    Color? colour;
    if (widget.project.deadline != null) {
      if (widget.project.deadline!.isBefore(DateTime.now())) {
        colour = Colors.red;
      } else if (widget.project.deadline!
          .isBefore(DateTime.now().add(const Duration(days: 7)))) {
        colour = Colors.yellow;
      } else {
        colour = Colors.green;
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            expanded = (expanded + 1) % 7;
            anim.animateTo(expanded.toDouble(), curve: Curves.ease);
          });
          if (controller != null) {
            if (expanded > 0) {
              controller?.setExpandedIdentifier(widget.identifier);
            } else {
              controller?.setExpandedIdentifier(null);
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blueGrey.shade900,
                Colors.blueGrey.shade700,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSize(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    // currency format with intl package
                    NumberFormat.currency(
                      locale: 'en_US',
                      symbol: r'$',
                    ).format(widget.project.budget),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (expanded > 0)
                    ProjectInfoTile(
                      text: widget.project.shortDescription,
                    ),
                  if (expanded > 1)
                    // total paid so far
                    ProjectInfoTile(
                      text: 'Total Paid: '
                          '${widget.project.totalPaid.currency}',
                    ),
                  if (expanded > 2)
                    ProjectInfoTile(text: widget.project.clientName),
                  if (expanded > 3)
                    ProjectInfoTile(
                      text: 'Fixed',
                      showCheck: true,
                      checked: widget.project.isFixed,
                    ),
                  if (expanded > 4)
                    ProjectInfoTile(
                      text: 'One Time',
                      showCheck: true,
                      checked: widget.project.isOneTime,
                    ),
                  if (expanded > 5)
                    ProjectInfoTile(
                      text: 'Started: ${widget.project.startDate.yMd}',
                    ),
                  if (widget.project.deadline != null)
                    ProjectInfoTile(
                      text: 'Deadline: '
                          '${widget.project.deadline!.yMd}',
                      style: TextStyle(
                        color: colour,
                      ),
                      showCheck: true,
                      icon: widget.project.completed
                          ? null
                          : Icon(
                              Icons.alarm,
                              color: colour,
                            ),
                      checked:
                          widget.project.deadline!.isBefore(DateTime.now()) ||
                              widget.project.completed,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
