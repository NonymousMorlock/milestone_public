import 'package:flutter/material.dart';
import 'package:milestone/app/shell/app_shell_destination.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class SidebarDestinationTile extends StatelessWidget {
  const SidebarDestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.backgroundColor,
    super.key,
  });

  final AppShellDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected ? backgroundColor : Colors.transparent,
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.25)
                  : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(destination.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
