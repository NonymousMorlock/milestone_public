import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OutlinedBackButton extends StatelessWidget {
  const OutlinedBackButton({this.alwaysVisible = false, super.key});

  final bool alwaysVisible;

  @override
  Widget build(BuildContext context) {
    if ((!kIsWeb && !kIsWasm) && (alwaysVisible || context.canPop())) {
      return Center(
        child: IconButton.outlined(
          onPressed: () {
            if (context.canPop()) return context.pop();
            context.go('/');
          },
          icon: const BackButtonIcon(),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
