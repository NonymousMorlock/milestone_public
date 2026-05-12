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

  final VoidCallback? onPressed;
  final String text;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? backgroundColour;

  @override
  Widget build(BuildContext context) {
    final overrideStyle = backgroundColour == null
        ? null
        : ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(backgroundColour),
          );
    return ConstrainedBox(
      // set a max width considering web xxl screens
      constraints: const BoxConstraints(maxWidth: 500),
      child: SizedBox(
        height: height ?? 50,
        width: double.maxFinite,
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: Size(double.infinity, height ?? 50),
            padding: padding,
          ).merge(overrideStyle),
          onPressed: onPressed == null
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  onPressed!();
                },
          child: Text(text, style: textStyle),
        ),
      ),
    );
  }
}
