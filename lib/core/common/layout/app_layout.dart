import 'package:flutter/material.dart';

enum AppLayoutSize {
  compact,
  medium,
  expanded,
}

enum AppPageWidthPolicy {
  dashboard,
  details,
  form,
  narrow,
}

abstract final class AppLayout {
  static AppLayoutSize classify(double width) {
    if (width < 600) {
      return AppLayoutSize.compact;
    }
    if (width < 1024) {
      return AppLayoutSize.medium;
    }
    return AppLayoutSize.expanded;
  }

  static EdgeInsets pagePadding(AppLayoutSize size) => switch (size) {
    AppLayoutSize.compact => const EdgeInsets.all(16),
    AppLayoutSize.medium => const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 24,
    ),
    AppLayoutSize.expanded => const EdgeInsets.symmetric(
      horizontal: 32,
      vertical: 32,
    ),
  };

  static double maxWidthFor(AppPageWidthPolicy policy) => switch (policy) {
    AppPageWidthPolicy.dashboard => 1240,
    AppPageWidthPolicy.details => 1120,
    AppPageWidthPolicy.form => 920,
    AppPageWidthPolicy.narrow => 720,
  };
}
