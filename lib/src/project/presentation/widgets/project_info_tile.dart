import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

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
    final scheme = context.colorScheme;
    final tokens = context.milestoneTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCheck) ...[
            icon ??
                Icon(
                  checked ? Icons.check : Icons.close,
                  color: checked ? tokens.statusOnTrack : tokens.statusOverdue,
                ),
            const Gap(8),
          ],
          Expanded(
            child: Text(
              text,
              style:
                  style ??
                  context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
