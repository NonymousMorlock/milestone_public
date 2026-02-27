import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class StateRenderer extends StatelessWidget {
  /// Creates a [StateRenderer] that shows a loading indicator when [loading]
  /// is true. Otherwise, it shows the [child].
  const StateRenderer({
    required this.loading,
    this.builder,
    this.child,
    this.loadingWidget,
    super.key,
  })  : assert(
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
    return loading
        ? Center(
            child: loadingWidget ??
                CircularProgressIndicator.adaptive(
                  key: const Key('loading_indicator'),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.theme.primaryColor,
                  ),
                ),
          )
        : builder?.call(context) ?? child!;
  }
}
