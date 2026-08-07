import 'package:flutter/material.dart';
import 'package:milestone/core/common/app/milestone/app_state.dart';
import 'package:milestone/core/common/widgets/state_renderer_loading_scene.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';

class AppStateReactor extends StatelessWidget {
  const AppStateReactor({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<$State>(
      valueListenable: AppState.instance.current,
      builder: (context, current, _) {
        final isLoading = current == $State.LOADING;

        return PopScope(
          canPop: !isLoading,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop || !isLoading) {
              return;
            }

            CoreUtils.showSnackBar(
              logLevel: LogLevel.warning,
              message: 'Please wait until the current operation is complete.',
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (isLoading) ...[
                const ModalBarrier(
                  dismissible: false,
                  color: Color(0xA6000000),
                ),
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: StateRendererLoadingScene(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
