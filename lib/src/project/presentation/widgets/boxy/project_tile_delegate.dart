import 'package:boxy/boxy.dart';
import 'package:flutter/widgets.dart';
import 'package:milestone/src/project/presentation/widgets/boxy/project_tile_style.dart';

class ProjectTileDelegate extends BoxyDelegate {
  ProjectTileDelegate({required this.style});

  final ProjectTileStyle style;

  @override
  Size layout() {
    // We can grab children by name using BoxyId and getChild
    final title = getChild(#title);
    final client = getChild(#client);
    final info = getChild(#info);

    // Lay out the client first so it can provide a minimum height to the title
    // and info
    final clientSize = client.layout(
      constraints.deflate(
        EdgeInsets.only(right: style.clientInset),
      ),
    );

    // Lay out and position the title
    final titleSize = title.layout(
      constraints.copyWith(
        minHeight: clientSize.height / 2 + style.gapHeight / 2,
      ),
    );
    title.position(Offset.zero);

    // Position the client at the bottom right of the title, offset to the left
    // by clientInset
    client.position(
      Offset(
        titleSize.width - (clientSize.width + style.clientInset),
        (titleSize.height - clientSize.height / 2) + style.gapHeight / 2,
      ),
    );

    // Lay out info to match the width of title and position it below the title
    final infoSize = info.layout(
      BoxConstraints(
        minHeight: clientSize.height / 2,
        minWidth: titleSize.width,
        maxWidth: titleSize.width,
      ),
    );
    info.position(Offset(0, titleSize.height + style.gapHeight));

    return Size(
      titleSize.width,
      titleSize.height + infoSize.height + style.gapHeight,
    );
  }

  // Any BoxyDelegate with parameters should always implement shouldRelayout,
  // otherwise it won't update when its properties do.
  @override
  bool shouldRelayout(ProjectTileDelegate oldDelegate) =>
      style != oldDelegate.style;
}
