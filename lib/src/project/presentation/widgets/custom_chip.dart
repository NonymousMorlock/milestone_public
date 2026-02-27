import 'package:flutter/material.dart';
import 'package:milestone/core/res/styles/colours.dart';

class CustomChip extends StatelessWidget {
  const CustomChip({required this.label, super.key, this.avatar, this.onTap});

  final String label;
  final Widget? avatar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: Colours.lightThemePrimaryTextColour,
      label: Text(label),
      iconTheme: const IconThemeData(color: Colors.green),
      labelStyle: const TextStyle(color: Colors.white),
      avatar: avatar ?? const Icon(Icons.add),
      onPressed: onTap,
    );
  }
}
