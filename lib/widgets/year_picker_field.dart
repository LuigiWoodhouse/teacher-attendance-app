import 'package:flutter/material.dart';

Future<int?> showYearSelectionDialog({
  required BuildContext context,
  required int initialYear,
  required int firstYear,
  required int lastYear,
  String title = 'Select year',
}) {
  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 320,
          height: 320,
          child: YearPicker(
            firstDate: DateTime(firstYear),
            lastDate: DateTime(lastYear),
            selectedDate: DateTime(initialYear),
            currentDate: DateTime.now(),
            onChanged: (date) {
              Navigator.of(dialogContext).pop(date.year);
            },
          ),
        ),
      );
    },
  );
}

class YearPickerField extends StatelessWidget {
  const YearPickerField({
    super.key,
    required this.selectedYear,
    required this.firstYear,
    required this.lastYear,
    required this.onChanged,
    this.labelText = 'Year',
    this.dialogTitle = 'Select year',
  });

  final int selectedYear;
  final int firstYear;
  final int lastYear;
  final ValueChanged<int> onChanged;
  final String labelText;
  final String dialogTitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final pickedYear = await showYearSelectionDialog(
          context: context,
          initialYear: selectedYear,
          firstYear: firstYear,
          lastYear: lastYear,
          title: dialogTitle,
        );

        if (pickedYear != null) {
          onChanged(pickedYear);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(selectedYear.toString()),
      ),
    );
  }
}
