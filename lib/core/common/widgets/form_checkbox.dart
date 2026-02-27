import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A custom checkbox widget for forms.
///
/// This widget displays a checkbox with a label and an optional info message.
/// The checkbox can be toggled by tapping on it or the label.
class FormCheckbox extends StatelessWidget {
  /// Creates a [FormCheckbox] widget.
  ///
  /// The [value] parameter is required and represents the current state of
  /// the checkbox.
  /// The [onChanged] parameter is required and is called when the checkbox
  /// is toggled.
  /// The [label] parameter is required and represents the text label for
  /// the checkbox.
  /// The [infoMessage] parameter is optional and, if provided, displays an
  /// info icon with a tooltip.
  const FormCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    this.infoMessage,
    super.key,
  });

  /// The current state of the checkbox.
  final bool value;

  /// Called when the checkbox is toggled.
  final ValueChanged<bool?> onChanged;

  /// An optional info message to display in a tooltip.
  final String? infoMessage;

  /// The text label for the checkbox.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            onChanged.call(!value);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AbsorbPointer(
                child: Checkbox(value: value, onChanged: (_) {}),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        if (infoMessage != null) ...[
          const Gap(5),
          Tooltip(
            triggerMode: TooltipTriggerMode.tap,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(8),
            showDuration: const Duration(seconds: 10),
            message: infoMessage,
            child: const Icon(Icons.info, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
