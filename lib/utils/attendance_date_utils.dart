String dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime dateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) {
    return DateTime.now();
  }

  return DateTime(
    int.tryParse(parts[0]) ?? DateTime.now().year,
    int.tryParse(parts[1]) ?? DateTime.now().month,
    int.tryParse(parts[2]) ?? DateTime.now().day,
  );
}

bool isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatDateRange(DateTime start, DateTime end) {
  if (isSameDate(start, end)) {
    return formatDate(start);
  }

  return '${formatDate(start)} - ${formatDate(end)}';
}

String backupFileName(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'pm' : 'am';
  final month = monthAbbreviation(dateTime.month);
  return '${month}_${dateTime.day}_${dateTime.year}_$hour$minute$period';
}

String formatDateTimeForSheet(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '${formatDate(dateTime)} $hour:$minute $period';
}

String monthAbbreviation(int month) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
