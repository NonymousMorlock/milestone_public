import 'package:flutter/material.dart';

class CustomChip extends StatelessWidget {
  const CustomChip({
    required this.label,
    super.key,
    this.avatar,
    this.onTap,
    this.radius,
    this.padding,
  });

  final String label;
  final Widget? avatar;
  final VoidCallback? onTap;
  final double? radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: avatar ?? const Icon(Icons.add),
      onPressed: onTap,
      padding: padding ?? const .all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius ?? 10),
      ),
    );
  }
}
