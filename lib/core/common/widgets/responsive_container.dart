import 'package:flutter/material.dart';
import 'package:flutter_bootstrap5/flutter_bootstrap5.dart';
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
    return switch (_breakpoint) {
      ScreenSize.sm => FB5Container.sm(child: child),
      ScreenSize.md => FB5Container.md(child: child),
      ScreenSize.lg => FB5Container.lg(child: child),
      ScreenSize.xl => FB5Container.xl(child: child),
      ScreenSize.xxl => FB5Container.xxl(child: child),
      _ => FB5Container(child: child),
    };
  }
}
