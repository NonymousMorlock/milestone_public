// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milestone/core/common/widgets/date_picker.dart';
import 'package:milestone/core/common/widgets/generic_field.dart';
import 'package:milestone/core/utils/core_utils.dart';

class DateField extends StatelessWidget {
  /// A [GenericField] with a date picker as its suffix icon.
  ///
  /// This Field forces the user to use the [DatePicker]. They don't have the
  /// ability to edit the value of the field by hand.
  const DateField({
    required this.dateController,
    required this.dateNotifier,
    super.key,
    this.refresh,
    this.onDateChanged,
    this.label,
    this.dateFormat,
  });

  final TextEditingController dateController;
  final ValueNotifier<DateTime?> dateNotifier;
  final void Function(VoidCallback)? refresh;
  final void Function(DateTime?)? onDateChanged;
  final String? label;
  final DateFormat? dateFormat;

  @override
  Widget build(BuildContext context) {
    void dateChangedHandler(DateTime? date) {
      if (date != null) {
        if (dateFormat != null) {
          dateController.text = dateFormat!.format(date);
        } else {
          //DateFormat('MM/dd/yy')
          dateController.text = DateFormat('yyyy/MM/dd').format(date);
        }
        dateNotifier.value = date;
        refresh?.call(() {});
        onDateChanged?.call(date);
      }
    }

    return GenericField(
      controller: dateController,
      readOnly: true,
      label: label ?? 'Date',
      onTap: () async {
        dateChangedHandler(await CoreUtils.showGenericDatePicker(context));
      },
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DatePicker(
            initialDate: dateNotifier.value,
            onDateChanged: dateChangedHandler,
          ),
          ListenableBuilder(
            listenable: dateController,
            builder: (_, __) {
              if (dateController.text.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    dateController.clear();
                    dateNotifier.value = null;
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
