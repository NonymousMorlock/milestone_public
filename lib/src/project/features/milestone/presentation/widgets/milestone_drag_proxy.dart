import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';

class MilestoneDragProxy extends StatelessWidget {
  const MilestoneDragProxy({
    required this.milestone,
    required this.sequence,
    required this.animation,
    super.key,
  });

  final Milestone milestone;
  final int sequence;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final opacityAnimation = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(curvedAnimation);
    final scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1,
    ).animate(curvedAnimation);

    return FadeTransition(
      opacity: opacityAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.colorScheme.shadow.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                spacing: 12,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        '#$sequence',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      milestone.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
