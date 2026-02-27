import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TextPlaceholder extends StatelessWidget {
  const TextPlaceholder({
    required this.width,
    super.key,
  });
  final double width;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: width,
          height: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}
