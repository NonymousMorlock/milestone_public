import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/res/styles/colours.dart';
import 'package:milestone/core/services/router.dart';
import 'package:provider/provider.dart';

abstract class CoreUtils {
  const CoreUtils();

  static final _imagePicker = ImagePicker();

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final style = TextStyle(
      color: context.isDarkMode
          ? Colours.lightThemeWhiteColour
          : Colours.lightThemePrimaryTextColour,
    );
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        title: Text(title, style: style),
        content: Text(
          content,
          style: style,
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

  static Future<void> showSnackBar({
    required String message,
    String? title,
    LogLevel logLevel = LogLevel.info,
    bool enhanceBlur = false,
    bool enhanceMessage = false,
  }) async {
    const isWeb = kIsWeb || kIsWasm;
    Widget toast;

    if (!isWeb) {
      toast = ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: enhanceBlur
                  ? Colors.white.withValues(alpha: .2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(8),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: enhanceMessage ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      toast = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: logLevel.color,
            borderRadius: BorderRadius.circular(15),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(8),
                ],
                Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
      unawaited(
        showSnackBar(
          logLevel: LogLevel.error,
          message: 'Something went wrong',
          title: 'Error Picking Image',
        ),
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
      unawaited(
        showSnackBar(
          logLevel: LogLevel.error,
          message: 'Something went wrong',
          title: 'Error Picking Image',
        ),
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
      builder: (_, child) {
        return Theme(
          data: ThemeData().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colours.lightThemePrimaryColour,
              surface: Colours.lightThemePrimaryTextColour,
              onSurface: Colours.lightThemeSecondaryTextColour,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
