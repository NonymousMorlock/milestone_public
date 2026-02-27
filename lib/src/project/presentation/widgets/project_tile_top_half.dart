import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/res/res.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/app/providers/expandable_card_controller.dart';

class ProjectTileTopHalf extends StatefulWidget {
  ProjectTileTopHalf(
    this.project, {
    dynamic identifier,
    this.expandable = false,
    this.navigateOnTap = true,
    this.onTap,
    this.margin,
  })  : identifier = identifier ?? project.id,
        super(key: ValueKey(Tuple2(#clientTitle, identifier)));

  final dynamic identifier;
  final Project project;
  final VoidCallback? onTap;
  final bool expandable;
  final bool navigateOnTap;
  final EdgeInsetsGeometry? margin;

  @override
  State<ProjectTileTopHalf> createState() => ProjectTileTopHalfState();
}

class ProjectTileTopHalfState extends State<ProjectTileTopHalf> {
  bool expanded = false;

  ExpandableCardController? controller;

  @override
  void initState() {
    super.initState();
    try {
      controller = context.read<ExpandableCardController>()
        ..addListener(() {
          if (!mounted) return;
          setState(() {
            expanded = controller!.expandedIdentifier == widget.identifier;
          });
        });

      expanded = controller!.expandedIdentifier == widget.identifier;
    } on Exception catch (e) {
      final lowerCaseErrorMessage = e.toString().toLowerCase();
      final containsMessage = lowerCaseErrorMessage.contains(
        'could not find the correct',
      );

      final providerIsExpandableCardController =
          lowerCaseErrorMessage.contains('expandablecardcontroller');
      if (containsMessage && providerIsExpandableCardController) {
        if (widget.expandable) {
          throw Exception(
            'You need to inject an ExpandableCardController '
            'in the parent widget or set expandable to false',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final margin =
        expanded || widget.margin == null ? EdgeInsets.zero : widget.margin!;
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            margin: margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueGrey.shade900,
                  Colors.blueGrey.shade800,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
            margin: margin,
            padding: EdgeInsets.only(bottom: expanded ? 0 : 60),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: widget.project.image != null
                  ? Image.network(
                      widget.project.image!,
                      fit: BoxFit.cover,
                      colorBlendMode: BlendMode.darken,
                      color: Colors.black.withValues(alpha: 0.5),
                    )
                  : Image.asset(
                      Res.projectBanner1,
                      fit: BoxFit.cover,
                      colorBlendMode: BlendMode.darken,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: widget.expandable ? double.maxFinite : 350,
          height: expanded ? 350 : 200,
          margin: margin,
          curve: Curves.ease,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (widget.navigateOnTap) {
                  context.navigateTo(
                    '/projects/${widget.project.id}',
                    extra: widget.project.projectName,
                  );
                }
                widget.onTap?.call();
              },
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.project.projectName,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
