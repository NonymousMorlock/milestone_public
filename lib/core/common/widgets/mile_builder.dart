import 'package:flutter/material.dart';

class MileBuilder extends StatelessWidget {
  const MileBuilder({required this.builder, super.key, this.child});

  final Widget? child;
  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) => builder(context, child);
}
