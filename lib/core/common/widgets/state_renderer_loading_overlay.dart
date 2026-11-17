import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class StateRendererLoadingOverlay extends StatelessWidget {
  const StateRendererLoadingOverlay({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final milestoneTheme = context.milestoneTheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surface.withValues(alpha: .84),
                Color.alphaBlend(
                  milestoneTheme.loadingAccentStart.withValues(alpha: .08),
                  scheme.surfaceContainerHigh,
                ).withValues(alpha: .92),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
