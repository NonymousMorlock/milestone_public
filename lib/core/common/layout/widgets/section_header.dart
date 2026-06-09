import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    this.title,
    this.subtitle,
    this.action,
  });

  final String? title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final hasCustomTitle =
        title?.toLowerCase().trim() != subtitle?.toLowerCase().trim();
    Widget? heading;
    Widget? subHeading;

    if (title case final value?) {
      heading = Text(
        value,
        maxLines: hasCustomTitle ? null : 1,
        overflow: hasCustomTitle ? null : .ellipsis,
        style: context.textTheme.titleLarge?.copyWith(
          fontWeight: .w700,
        ),
      );
    }

    if (subtitle case final value?) {
      subHeading = Padding(
        padding: EdgeInsets.only(top: title == null ? 0 : 6),
        child: Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (action == null) {
      return Column(
        crossAxisAlignment: .start,
        children: [?heading, ?subHeading],
      );
    }

    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: heading == null && subHeading == null ? .end : .start,
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          spacing: 12,
          children: [
            if (heading != null)
              Expanded(child: heading)
            else if (subHeading != null)
              Expanded(child: subHeading),
            action!,
          ],
        ),
        if (heading != null && subHeading != null) subHeading,
      ],
    );
  }
}
