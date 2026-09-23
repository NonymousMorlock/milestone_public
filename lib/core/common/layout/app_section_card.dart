import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/widgets/section_header.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.action,
  });

  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(24),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const .all(20),
        child: Column(
          crossAxisAlignment: .stretch,
          spacing: 16,
          children: [
            if (title != null || subtitle != null || action != null)
              SectionHeader(
                title: title,
                subtitle: subtitle,
                action: action,
              ),
            child,
          ],
        ),
      ),
    );
  }
}
