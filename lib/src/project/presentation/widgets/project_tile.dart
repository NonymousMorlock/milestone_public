import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:milestone/src/project/presentation/widgets/boxy/project_tile_delegate.dart';
import 'package:milestone/src/project/presentation/widgets/boxy/project_tile_style.dart';

class ProjectTile extends StatelessWidget {
  const ProjectTile({
    required this.topHalf,
    required this.bottomHalf,
    required this.clientAvatar,
    super.key,
    this.style = const ProjectTileStyle(),
  });

  final Widget topHalf;
  final Widget bottomHalf;
  final Widget clientAvatar;
  final ProjectTileStyle style;

  @override
  Widget build(BuildContext context) {
    return CustomBoxy(
      delegate: ProjectTileDelegate(style: style),
      children: [
        // Children are in paint order, put the client last so it can sit
        // above the others
        BoxyId(id: #title, child: topHalf),
        BoxyId(id: #info, child: bottomHalf),
        BoxyId(id: #client, child: clientAvatar),
      ],
    );
  }
}
