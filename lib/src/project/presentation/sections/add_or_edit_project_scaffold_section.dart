import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:milestone/core/common/widgets/responsive_container.dart';

class AddOrEditProjectScaffoldSection extends StatelessWidget {
  const AddOrEditProjectScaffoldSection({
    required this.titleText,
    required this.child,
    required this.onBackNavigation,
    super.key,
  });

  final String titleText;
  final Widget child;
  final VoidCallback onBackNavigation;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        onBackNavigation();
      },
      child: Scaffold(
        appBar: kIsWasm || kIsWeb
            ? null
            : AppBar(
                title: Text(titleText),
              ),
        body: SafeArea(
          child: ResponsiveContainer.sm(
            child: child,
          ),
        ),
      ),
    );
  }
}
