import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Ignore unused_import rule because without it, it marks the import as unused
import 'package:milestone/core/utils/title_non_web.dart'
    if (dart.library.html) 'package:milestone/core/utils/title_web.dart';

/// A widget that adapts its behavior based on the platform.
///
/// This widget displays a title and a child widget. On web and WASM platforms,
/// it wraps the child widget with a `Title` widget to set the browser
/// tab title.
class AdaptiveBase extends StatelessWidget {
  /// Creates an [AdaptiveBase] widget.
  ///
  /// The [title] parameter is required and represents the title of the web
  /// page.
  /// The [child] parameter is required and represents the page to render.
  const AdaptiveBase({required this.title, required this.child, super.key});

  /// The title to display.
  final String title;

  /// The child widget to display.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty || (!kIsWeb && !kIsWasm)) return child;
    return LayoutBuilder(
      builder: (_, __) {
        setPageTitle(title);
        return child;
      },
    );
  }
}
