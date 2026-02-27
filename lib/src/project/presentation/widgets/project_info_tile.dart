import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ProjectInfoTile extends StatelessWidget {
  const ProjectInfoTile({
    required this.text,
    super.key,
    this.checked = false,
    this.showCheck = false,
    this.style,
    this.icon,
  });

  final String text;
  final bool checked;
  final bool showCheck;
  final TextStyle? style;
  final Icon? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (showCheck) ...[
            icon ??
                Icon(
                  checked ? Icons.check : Icons.close,
                  color: checked ? Colors.green : Colors.red,
                ),
            const Gap(8),
          ],
          Expanded(
            child: Text(
              text,
              style: style ?? const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
