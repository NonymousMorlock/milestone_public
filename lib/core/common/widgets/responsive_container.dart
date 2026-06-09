import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/enums/screen_size.dart';

class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({required this.child, super.key})
    : _breakpoint = null;

  const ResponsiveContainer.lg({required this.child, super.key})
    : _breakpoint = ScreenSize.lg;

  const ResponsiveContainer.md({required this.child, super.key})
    : _breakpoint = ScreenSize.md;

  const ResponsiveContainer.sm({required this.child, super.key})
    : _breakpoint = ScreenSize.sm;

  const ResponsiveContainer.xl({required this.child, super.key})
    : _breakpoint = ScreenSize.xl;

  const ResponsiveContainer.xxl({required this.child, super.key})
    : _breakpoint = ScreenSize.xxl;

  final Widget child;
  final ScreenSize? _breakpoint;

  @override
  Widget build(BuildContext context) {
    final maxWidth = switch (_breakpoint) {
      ScreenSize.sm => AppLayout.maxWidthFor(AppPageWidthPolicy.form),
      ScreenSize.md => AppLayout.maxWidthFor(AppPageWidthPolicy.details),
      ScreenSize.lg ||
      ScreenSize.xl ||
      ScreenSize.xxl ||
      null => AppLayout.maxWidthFor(AppPageWidthPolicy.dashboard),
    };

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
