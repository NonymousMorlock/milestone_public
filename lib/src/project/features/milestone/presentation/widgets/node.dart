import 'package:flutter/material.dart';

/// A widget that represents a node in a graphical interface.
///
/// This widget is a small circular container with a fixed size and green color.
/// It can be used to represent a point or node in a layout.
class Node extends StatelessWidget {
  /// Creates a [Node] widget.
  const Node({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      width: 10,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}
