import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.actions,
    required this.compact,
    this.title,
    this.subtitle,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title case final value?)
          Text(
            value,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        if (subtitle case final value?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              value,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );

    if (actions.isEmpty) {
      return titleBlock;
    }

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 12,
            children: actions,
          ),
        ),
      ],
    );
  }
}
