import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  const RoundedButton({
    required this.onPressed,
    required this.text,
    this.height,
    this.padding,
    this.textStyle,
    this.backgroundColour,
    super.key,
  });

  final VoidCallback onPressed;
  final String text;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? backgroundColour;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // set a max width considering web xxl screens
      constraints: const BoxConstraints(maxWidth: 500),
      child: SizedBox(
        height: height ?? 50,
        width: double.maxFinite,
        child: FilledButton(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: backgroundColour,
            padding: padding,
          ),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            onPressed();
          },
          child: Text(
            text,
            style: textStyle ??
                const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}
