import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:milestone/app/theme/milestone_theme_extension.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class StateRendererLoadingScene extends StatefulWidget {
  const StateRendererLoadingScene({super.key});

  @override
  State<StateRendererLoadingScene> createState() =>
      _StateRendererLoadingSceneState();
}

class _StateRendererLoadingSceneState extends State<StateRendererLoadingScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final milestoneTheme = context.milestoneTheme;
    final textTheme = context.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 420.0;
        final stageWidth = width.clamp(240.0, 420.0);
        final compact = stageWidth < 320;
        final sceneSize = compact ? 112.0 : 132.0;
        final panelPadding = compact ? 18.0 : 24.0;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            final labelPulse = lerpDouble(.84, 1, _wave(progress, .12))!;
            final badgeScale = lerpDouble(.95, 1.05, _wave(progress, .2))!;
            final badgeTilt = lerpDouble(-.08, .08, _wave(progress, .58))!;
            final trackOneWidth = lerpDouble(.78, .98, _wave(progress, 0))!;
            final trackTwoWidth = lerpDouble(.46, .74, _wave(progress, .24))!;
            final trackThreeWidth = lerpDouble(
              .58,
              .88,
              _wave(progress, .48),
            )!;
            final satellites =
                <({double angle, double radius, double size, Color color})>[
                  (
                    angle: progress * math.pi * 2,
                    radius: sceneSize * .34,
                    size: 11,
                    color: milestoneTheme.loadingAccentStart,
                  ),
                  (
                    angle: -(progress * math.pi * 2 * 1.4) - .8,
                    radius: sceneSize * .22,
                    size: 8,
                    color: scheme.secondary,
                  ),
                  (
                    angle: (progress * math.pi * 2 * .82) + 1.7,
                    radius: sceneSize * .43,
                    size: 9,
                    color: scheme.tertiary,
                  ),
                ];

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: stageWidth,
                minHeight: compact ? 208 : 236,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: .8),
                  ),
                  gradient: LinearGradient(
                    begin: .topLeft,
                    end: .bottomRight,
                    colors: [
                      Color.alphaBlend(
                        milestoneTheme.loadingAccentStart.withValues(
                          alpha: .18,
                        ),
                        scheme.surfaceContainerHighest,
                      ),
                      Color.alphaBlend(
                        milestoneTheme.loadingAccentEnd.withValues(alpha: .12),
                        scheme.surfaceContainerHigh,
                      ),
                      Color.alphaBlend(
                        scheme.tertiary.withValues(alpha: .08),
                        scheme.surface,
                      ),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: .08),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(panelPadding),
                  child: Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .start,
                    children: [
                      Transform.scale(
                        alignment: .centerLeft,
                        scale: labelPulse,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Color.alphaBlend(
                              milestoneTheme.loadingAccentStart.withValues(
                                alpha: .12,
                              ),
                              scheme.surface,
                            ),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: .8,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: .min,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scheme.primary.withValues(
                                      alpha: .18,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: .circle,
                                        color: scheme.primary,
                                      ),
                                      child: const SizedBox.square(
                                        dimension: 6,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Milestone workspace',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: .w700,
                                    letterSpacing: .2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      Center(
                        child: SizedBox.square(
                          dimension: sceneSize,
                          child: Stack(
                            alignment: .center,
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _StateRendererLoadingSignalPainter(
                                    progress: progress,
                                    colorScheme: scheme,
                                    milestoneTheme: milestoneTheme,
                                  ),
                                ),
                              ),
                              for (final satellite in satellites)
                                Transform.translate(
                                  offset: Offset(
                                    math.cos(satellite.angle) *
                                        satellite.radius,
                                    math.sin(satellite.angle) *
                                        satellite.radius,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: .circle,
                                      color: satellite.color,
                                      boxShadow: [
                                        BoxShadow(
                                          color: satellite.color.withValues(
                                            alpha: .32,
                                          ),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: SizedBox.square(
                                      dimension: satellite.size,
                                    ),
                                  ),
                                ),
                              Transform.rotate(
                                angle: badgeTilt,
                                child: Transform.scale(
                                  scale: badgeScale,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: LinearGradient(
                                        begin: .topLeft,
                                        end: .bottomRight,
                                        colors: [
                                          Color.alphaBlend(
                                            milestoneTheme.loadingAccentStart
                                                .withValues(alpha: .66),
                                            scheme.surfaceBright,
                                          ),
                                          Color.alphaBlend(
                                            milestoneTheme.loadingAccentEnd
                                                .withValues(alpha: .5),
                                            scheme.surfaceContainerHighest,
                                          ),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: scheme.onSurface.withValues(
                                          alpha: .08,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: milestoneTheme
                                              .loadingAccentStart
                                              .withValues(alpha: .2),
                                          blurRadius: 18,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Icon(
                                        Icons.timeline_rounded,
                                        color: scheme.onPrimaryContainer,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 20),
                      Text(
                        'Syncing your workspace',
                        style: textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: .w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bringing your Milestone workspace up '
                        'to date so everything is ready for the next step.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: trackOneWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: [
                                  scheme.surfaceContainerHighest,
                                  Color.alphaBlend(
                                    milestoneTheme.loadingAccentStart
                                        .withValues(
                                          alpha: .14,
                                        ),
                                    scheme.surfaceContainerHigh,
                                  ),
                                  scheme.surfaceContainerHighest,
                                ],
                              ),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: .52,
                                ),
                              ),
                            ),
                            child: const SizedBox(height: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: trackTwoWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: [
                                  scheme.surfaceContainerHighest,
                                  Color.alphaBlend(
                                    scheme.secondary.withValues(alpha: .14),
                                    scheme.surfaceContainerHigh,
                                  ),
                                  scheme.surfaceContainerHighest,
                                ],
                              ),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: .52,
                                ),
                              ),
                            ),
                            child: const SizedBox(height: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: trackThreeWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: [
                                  scheme.surfaceContainerHighest,
                                  Color.alphaBlend(
                                    scheme.tertiary.withValues(alpha: .14),
                                    scheme.surfaceContainerHigh,
                                  ),
                                  scheme.surfaceContainerHighest,
                                ],
                              ),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: .52,
                                ),
                              ),
                            ),
                            child: const SizedBox(height: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StateRendererLoadingSignalPainter extends CustomPainter {
  const _StateRendererLoadingSignalPainter({
    required this.progress,
    required this.colorScheme,
    required this.milestoneTheme,
  });

  final double progress;
  final ColorScheme colorScheme;
  final MilestoneThemeExtension milestoneTheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.shortestSide * .48;
    final middleRadius = size.shortestSide * .34;
    final innerRadius = size.shortestSide * .22;

    final haloPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              milestoneTheme.loadingAccentStart.withValues(alpha: .22),
              milestoneTheme.loadingAccentEnd.withValues(alpha: .12),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: outerRadius * 1.15),
          );
    canvas.drawCircle(center, outerRadius * 1.05, haloPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = colorScheme.outlineVariant.withValues(alpha: .55);
    canvas
      ..drawCircle(center, outerRadius, ringPaint)
      ..drawCircle(center, middleRadius, ringPaint)
      ..drawCircle(center, innerRadius, ringPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6
      ..color = milestoneTheme.loadingAccentStart.withValues(alpha: .68);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: middleRadius),
      (progress * math.pi * 2) - math.pi / 3,
      math.pi / 1.8,
      false,
      arcPaint,
    );
    arcPaint
      ..strokeWidth = 4
      ..color = colorScheme.tertiary.withValues(alpha: .72);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -(progress * math.pi * 2 * 1.2) - .6,
      math.pi / 1.5,
      false,
      arcPaint,
    );

    final nodePaint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 24; index++) {
      final t = index / 24;
      final angle = (math.pi * 2 * t) - math.pi / 2;
      final pulse = _wave(progress, t);
      final nodeRadius = lerpDouble(1.8, 4.6, pulse)!;
      final offset = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      );

      nodePaint.color = Color.lerp(
        colorScheme.outlineVariant.withValues(alpha: .4),
        milestoneTheme.loadingAccentStart.withValues(alpha: .95),
        pulse,
      )!;
      canvas.drawCircle(offset, nodeRadius, nodePaint);
    }

    final sweepAngle = (progress * math.pi * 2) - math.pi / 2;
    final scanLinePaint = Paint()
      ..strokeWidth = 1.2
      ..color = colorScheme.onSurface.withValues(alpha: .16);
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(sweepAngle) * outerRadius,
        center.dy + math.sin(sweepAngle) * outerRadius,
      ),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _StateRendererLoadingSignalPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.milestoneTheme != milestoneTheme;
  }
}

double _wave(double progress, double shift) {
  return (math.sin((progress + shift) * math.pi * 2) + 1) / 2;
}
