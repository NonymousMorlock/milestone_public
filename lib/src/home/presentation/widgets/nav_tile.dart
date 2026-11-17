import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class NavTile extends StatelessWidget {
  const NavTile({
    required this.icon,
    required this.title,
    super.key,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tokens = context.milestoneTheme;
    return Column(
      children: [
        ListTile(
          tileColor: tokens.navTileSurface,
          leading: CircleAvatar(
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(
              icon,
              color: scheme.onSurface,
            ),
          ),
          onTap: onTap,
          title: Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          trailing: Icon(
            Icons.arrow_right,
            color: scheme.onSurface,
          ),
        ),
        Divider(
          color: scheme.outlineVariant,
          height: 0,
          thickness: 1,
        ),
      ],
    );
  }
}
