import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milestone/app/routing/router.dart';
import 'package:milestone/app/theme/app_theme.dart';
import 'package:milestone/app/theme/milestone_theme_extension.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:provider/provider.dart';

sealed class CoreUtils {
  const CoreUtils();

  static final _imagePicker = ImagePicker();

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final scheme = context.colorScheme;
    final textStyle = context.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurface,
    );
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(
          content,
          style: textStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showSnackBar({
    required String message,
    String? title,
    LogLevel logLevel = LogLevel.info,
    bool enhanceBlur = false,
    bool enhanceMessage = false,
  }) {
    const isWeb = kIsWeb || kIsWasm;
    final overlayContext = rootNavigatorKey.currentContext;
    final theme = overlayContext != null
        ? overlayContext.theme
        : AppTheme.darkTheme;
    final scheme = theme.colorScheme;
    final milestoneTheme =
        theme.extension<MilestoneThemeExtension>() ??
        MilestoneThemeExtension.dark(theme.colorScheme);
    final accent = _toastAccent(logLevel, milestoneTheme);
    final surface = scheme.surfaceContainerHighest.withValues(
      alpha: enhanceBlur ? .82 : .94,
    );
    final foreground = scheme.onSurface;
    final secondaryForeground = enhanceMessage
        ? foreground
        : scheme.onSurfaceVariant;

    final toastChild = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: accent.withValues(alpha: .5)),
          boxShadow: isWeb
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: .15),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const Gap(8),
              ],
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final toast = isWeb
        ? toastChild
        : ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: enhanceBlur ? 7 : 0,
                sigmaY: enhanceBlur ? 7 : 0,
              ),
              child: toastChild,
            ),
          );

    rootNavigatorKey.currentContext!.read<FToast>()
      ..removeCustomToast()
      ..showToast(
        child: toast,
        toastDuration: const Duration(seconds: 5),
        gravity: isWeb ? ToastGravity.BOTTOM_RIGHT : ToastGravity.BOTTOM,
      );
  }

  static Future<File?> pickImage(BuildContext context) async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedImage != null) return File(pickedImage.path);
      return null;
    } on Exception catch (e, s) {
      log(
        '-----------Error Occurred-----------',
        name: 'CoreUtils.pickImage',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      showSnackBar(
        logLevel: LogLevel.error,
        message: 'Something went wrong',
        title: 'Error Picking Image',
      );
      return null;
    }
  }

  static Future<List<File>> pickImages(BuildContext context) async {
    try {
      final pickedImages = await _imagePicker.pickMultiImage();
      return pickedImages.map((file) => File(file.path)).toList();
    } on Exception catch (e, s) {
      log(
        '-----------Error Occurred-----------',
        name: 'CoreUtils.pickImages',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      showSnackBar(
        logLevel: LogLevel.error,
        message: 'Something went wrong',
        title: 'Error Picking Image',
      );
      return [];
    }
  }

  static Future<DateTime?> showGenericDatePicker(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    SelectableDayPredicate? selectableDayPredicate,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1960),
      lastDate: lastDate ?? DateTime(2300),
      selectableDayPredicate: selectableDayPredicate,
    );
  }

  static Color _toastAccent(
    LogLevel logLevel,
    MilestoneThemeExtension milestoneTheme,
  ) {
    return switch (logLevel) {
      LogLevel.info => milestoneTheme.feedbackInfo,
      LogLevel.warning => milestoneTheme.feedbackWarning,
      LogLevel.error => milestoneTheme.feedbackError,
      LogLevel.success => milestoneTheme.feedbackSuccess,
    };
  }
}
