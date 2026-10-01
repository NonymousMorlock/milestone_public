import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_layout.dart';

class ResponsiveFields extends StatelessWidget {
  const ResponsiveFields({
    required this.children,
    this.mediumColumns = 2,
    this.expandedColumns = 2,
    super.key,
  });

  final List<Widget> children;
  final int mediumColumns;
  final int expandedColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final sizeClass = AppLayout.classify(constraints.maxWidth);
        final columns = switch (sizeClass) {
          AppLayoutSize.compact => 1,
          AppLayoutSize.medium => mediumColumns,
          AppLayoutSize.expanded => expandedColumns,
        };
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map(
            (child) {
              return SizedBox(
                width: itemWidth,
                child: child,
              );
            },
          ).toList(),
        );
      },
    );
  }
}
