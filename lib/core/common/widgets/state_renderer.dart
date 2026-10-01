import 'package:flutter/material.dart';
import 'package:milestone/core/common/widgets/state_renderer_loading_overlay.dart';
import 'package:milestone/core/common/widgets/state_renderer_loading_scene.dart';

class StateRenderer extends StatelessWidget {
  /// Creates a [StateRenderer] that shows a loading indicator when [loading]
  /// is true. Otherwise, it shows the [child].
  const StateRenderer({
    required this.loading,
    this.builder,
    this.child,
    this.loadingWidget,
    super.key,
  }) : assert(
         child != null || builder != null,
         'child or builder must be provided',
       ),
       assert(
         child == null || builder == null,
         'child and builder cannot be provided at the same time',
       );

  final bool loading;
  final Widget? child;
  final Widget Function(BuildContext context)? builder;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    final content = builder?.call(context) ?? child!;
    final overlayChild = loadingWidget ?? const StateRendererLoadingScene();

    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: loading ? 220 : 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              opacity: loading ? .28 : 1,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                scale: loading ? .985 : 1,
                child: AbsorbPointer(
                  absorbing: loading,
                  child: ExcludeSemantics(
                    excluding: loading,
                    child: content,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  final scale =
                      Tween<double>(
                        begin: .96,
                        end: 1,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                          reverseCurve: Curves.easeInCubic,
                        ),
                      );

                  return FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(
                      scale: scale,
                      child: child,
                    ),
                  );
                },
                child: loading
                    ? AbsorbPointer(
                        key: const ValueKey('state_renderer_loading_overlay'),
                        child: TickerMode(
                          enabled: true,
                          child: Semantics(
                            key: const Key('loading_indicator'),
                            label: 'Loading content',
                            child: StateRendererLoadingOverlay(
                              child: overlayChild,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('state_renderer_loading_overlay_empty'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
