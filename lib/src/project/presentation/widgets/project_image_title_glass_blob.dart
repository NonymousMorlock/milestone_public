import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class ProjectImageTitleGlassBlob extends StatelessWidget {
  const ProjectImageTitleGlassBlob({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.milestoneTheme;
    final textTheme = context.textTheme;
    final scheme = context.colorScheme;

    return FractionallySizedBox(
      widthFactor: .9,
      alignment: .centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const .only(
            topLeft: .circular(30),
            topRight: .circular(30),
            bottomRight: .circular(30),
            bottomLeft: .circular(14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .22),
              blurRadius: 28,
              offset: const Offset(0, 16),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: .circular(30),
            topRight: .circular(30),
            bottomRight: .circular(30),
            bottomLeft: .circular(14),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .topLeft,
                  end: .bottomRight,
                  colors: [
                    tokens.glassSurface.withValues(
                      alpha: context.isLightMode ? .36 : .22,
                    ),
                    Color.alphaBlend(
                      scheme.primary.withValues(
                        alpha: context.isLightMode ? .22 : .18,
                      ),
                      tokens.glassSurface,
                    ).withValues(
                      alpha: context.isLightMode ? .28 : .32,
                    ),
                    Colors.black.withValues(
                      alpha: context.isLightMode ? .08 : .24,
                    ),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: context.isLightMode ? .42 : .14,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -26,
                    left: 18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: .circle,
                        color: Colors.white.withValues(
                          alpha: context.isLightMode ? .18 : .08,
                        ),
                      ),
                      child: const SizedBox.square(dimension: 72),
                    ),
                  ),
                  Positioned(
                    bottom: -34,
                    right: -18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: .circle,
                        color: scheme.secondary.withValues(
                          alpha: context.isLightMode ? .14 : .08,
                        ),
                      ),
                      child: const SizedBox.square(dimension: 88),
                    ),
                  ),
                  Padding(
                    padding: const .fromLTRB(18, 14, 20, 16),
                    child: Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .start,
                      spacing: 12,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: .9),
                                Colors.white.withValues(alpha: .45),
                              ],
                            ),
                          ),
                          child: const SizedBox(
                            width: 38,
                            height: 4,
                          ),
                        ),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: .ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white.withValues(alpha: .98),
                            fontWeight: .w800,
                            height: .95,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: .32),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                              Shadow(
                                color: Colors.black.withValues(alpha: .28),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
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
