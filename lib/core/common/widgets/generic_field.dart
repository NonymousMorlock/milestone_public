// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milestone/core/extensions/context_extensions.dart';

class GenericField extends StatelessWidget {
  /// Creates a custom [TextField] and exposes a variety of properties to be
  /// changed at will, for better control.
  const GenericField({
    required this.controller,
    super.key,
    this.hint,
    this.validator,
    this.height,
    this.width,
    this.label,
    this.keyboardType,
    this.borderColour,
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.smartDashesType,
    this.inputFormatters,
    this.suffixIcon,
    this.labelFontSize,
    this.labelStyle,
    this.prefixText,
    this.maxLength,
    this.required = false,
    this.maxLines,
    this.minLines,
    this.helperText,
  }) : assert(
         labelFontSize == null || labelStyle == null,
         'Cannot set labelFontSize and labelStyle at the same time',
       );

  final TextEditingController controller;
  final String? hint;
  final String? Function(String? value)? validator;
  final ValueChanged<String?>? onChanged;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final String? label;
  final TextInputType? keyboardType;
  final Color? borderColour;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final SmartDashesType? smartDashesType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final double? labelFontSize;
  final TextStyle? labelStyle;
  final String? prefixText;
  final int? maxLength;
  final bool required;
  final int? maxLines;
  final int? minLines;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final sharedRadius = BorderRadius.circular(10);
    final labelBaseStyle =
        labelStyle ??
        context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontSize: labelFontSize,
        );
    var decoration = InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      prefixText: prefixText,
      helperText: helperText,
    );

    if (label case final String fieldLabel) {
      decoration = decoration.copyWith(
        label: RichText(
          text: TextSpan(
            text: fieldLabel,
            style: labelBaseStyle,
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: context.colorScheme.error),
                ),
            ],
          ),
        ),
      );
    }

    if (borderColour case final Color focusedColor) {
      decoration = decoration.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: sharedRadius,
          borderSide: BorderSide(color: focusedColor),
        ),
      );
    }

    return Center(
      child: TextFormField(
        enabled: enabled,
        readOnly: readOnly,
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: minLines,
        decoration: decoration,
        onChanged: onChanged,
        onTap: onTap,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          return validator?.call(value);
        },
        smartDashesType: smartDashesType,
        inputFormatters: inputFormatters,
      ),
    );
  }
}
