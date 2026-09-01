import 'package:flutter/material.dart';

/// A widget that represents a vertical connector line.
///
/// This widget is a simple vertical line with a fixed width and color.
/// It can be used to visually connect other widgets in a layout.
class Connector extends StatelessWidget {
  /// Creates a [Connector] widget.
  const Connector({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      child: ColoredBox(color: Colors.green),
    );
  }
}
