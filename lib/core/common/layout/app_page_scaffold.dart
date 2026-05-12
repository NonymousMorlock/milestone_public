import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/widgets/page_header.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.child,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.widthPolicy = AppPageWidthPolicy.dashboard,
    this.scrollable = true,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final AppPageWidthPolicy widthPolicy;
  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = AppLayout.classify(constraints.maxWidth);
        final padding = AppLayout.pagePadding(sizeClass);
        final maxWidth = AppLayout.maxWidthFor(widthPolicy);
        final header = PageHeader(
          title: title,
          subtitle: subtitle,
          actions: actions,
          compact: sizeClass == AppLayoutSize.compact,
        );

        final content = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        );

        if (scrollable) {
          return SingleChildScrollView(
            padding: padding,
            child: content,
          );
        }

        return Padding(
          padding: padding,
          child: content,
        );
      },
    );
  }
}
