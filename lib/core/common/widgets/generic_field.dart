// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milestone/core/res/styles/colours.dart';

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
    final border = OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(10),
    );
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
        decoration: InputDecoration(
          filled: true,
          fillColor: Colours.lightThemePrimaryColour.withValues(alpha: .2),
          border: border,
          errorBorder: border,
          focusedErrorBorder: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderSide: borderColour == null
                ? BorderSide.none
                : BorderSide(color: borderColour!),
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.only(
            top: 10,
            left: 10,
          ),
          hintMaxLines: 1,
          label: label == null
              ? null
              : RichText(
                  text: TextSpan(
                    text: label,
                    style: labelStyle ??
                        TextStyle(color: Colors.grey, fontSize: labelFontSize),
                    children: [
                      if (required)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
          suffixIcon: suffixIcon,
          prefixText: prefixText,
          prefixStyle: const TextStyle(fontSize: 16, color: Colors.black),
          helperText: helperText,
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
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
