// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:milestone/core/common/widgets/date_field.dart';
import 'package:milestone/core/res/styles/colours.dart';

class DatePicker extends StatelessWidget {
  /// Creates a single date picker icon that lets user pick a date when tapped.
  /// <br><br>
  /// This widget was used in the [DateField] widget
  const DatePicker({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.onDateChanged,
    this.icon,
  });

  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final SelectableDayPredicate? selectableDayPredicate;
  final ValueChanged<DateTime?>? onDateChanged;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon ?? const Icon(Icons.calendar_month_outlined),
      onPressed: () async {
        final date = await showDatePicker(
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
        onDateChanged?.call(date);
      },
    );
  }
}
