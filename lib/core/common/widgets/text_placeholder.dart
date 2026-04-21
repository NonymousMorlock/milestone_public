import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:shimmer/shimmer.dart';

class TextPlaceholder extends StatelessWidget {
  const TextPlaceholder({
    required this.width,
    super.key,
  });
  final double width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.milestoneTheme;
    return Shimmer.fromColors(
      baseColor: tokens.placeholderBase,
      highlightColor: tokens.placeholderHighlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: width,
          height: 12,
          color: tokens.placeholderSolid,
        ),
      ),
    );
  }
}
