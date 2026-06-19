import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;

import '../models/attendance_status.dart';
import '../models/teacher_record.dart';
import '../utils/attendance_date_utils.dart';

abstract class TeacherBackupService {
  Uint8List buildBackupBytes(
    List<TeacherRecord> teachers, {
    required DateTime createdAt,
  });

  String buildBackupFileName(DateTime createdAt);

  Future<File> writeTemporaryBackupFile(String fileName, Uint8List bytes);
}

class ExcelTeacherBackupService implements TeacherBackupService {
  @override
  Uint8List buildBackupBytes(
    List<TeacherRecord> teachers, {
    required DateTime createdAt,
  }) {
    const sheetName = 'Teacher Attendance';
    final workbook = xl.Excel.createExcel();
    final defaultSheetName = workbook.getDefaultSheet();

    if (defaultSheetName != null && defaultSheetName != sheetName) {
      workbook.rename(defaultSheetName, sheetName);
    }

    final sheet = workbook[sheetName];

    sheet.appendRow(<xl.CellValue>[
      xl.TextCellValue(sheetName),
    ]);
    sheet.appendRow(<xl.CellValue>[
      xl.TextCellValue('Created At'),
      xl.TextCellValue(formatDateTimeForSheet(createdAt)),
    ]);
    sheet.appendRow(const <xl.CellValue>[]);
    sheet.appendRow(<xl.CellValue>[
      xl.TextCellValue('Full Name'),
      xl.TextCellValue('First Name'),
      xl.TextCellValue('Last Name'),
      xl.TextCellValue('Number of Days Present'),
      xl.TextCellValue('Number of Days Absent'),
      xl.TextCellValue('Number of Days Late'),
      xl.TextCellValue('Number of Holidays'),
      xl.TextCellValue('Present Dates'),
      xl.TextCellValue('Absent Dates'),
      xl.TextCellValue('Late Dates'),
      xl.TextCellValue('Holiday Dates'),
      xl.TextCellValue('Logged Entries'),
    ]);

    for (final teacher in teachers) {
      sheet.appendRow(<xl.CellValue>[
        xl.TextCellValue(teacher.fullName),
        xl.TextCellValue(teacher.firstName),
        xl.TextCellValue(teacher.lastName),
        xl.IntCellValue(teacher.presentDays),
        xl.IntCellValue(teacher.absentDays),
        xl.IntCellValue(teacher.lateDays),
        xl.IntCellValue(teacher.holidayDays),
        xl.TextCellValue(_formatDatesForStatus(teacher, AttendanceStatus.present)),
        xl.TextCellValue(_formatDatesForStatus(teacher, AttendanceStatus.absent)),
        xl.TextCellValue(_formatDatesForStatus(teacher, AttendanceStatus.late)),
        xl.TextCellValue(_formatDatesForStatus(teacher, AttendanceStatus.holiday)),
        xl.IntCellValue(teacher.entries.length),
      ]);
    }

    final bytes = workbook.encode();
    if (bytes == null) {
      throw StateError('Could not generate the Excel backup.');
    }

    return Uint8List.fromList(bytes);
  }

  @override
  String buildBackupFileName(DateTime createdAt) {
    return '${backupFileName(createdAt)}.xlsx';
  }

  @override
  Future<File> writeTemporaryBackupFile(String fileName, Uint8List bytes) async {
    final safePrefix = fileName.replaceAll('.xlsx', '');
    final tempDirectory = await Directory.systemTemp.createTemp(
      'teacher_attendance_$safePrefix',
    );
    final tempFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await tempFile.writeAsBytes(bytes, flush: true);
    return tempFile;
  }
}

String _formatDatesForStatus(TeacherRecord teacher, AttendanceStatus status) {
  final dates = teacher.entries
      .where((entry) => entry.status == status)
      .map((entry) => DateTime(entry.date.year, entry.date.month, entry.date.day))
      .toList()
    ..sort((left, right) => left.compareTo(right));

  if (dates.isEmpty) {
    return '';
  }

  final ranges = <String>[];
  var rangeStart = dates.first;
  var rangeEnd = dates.first;

  for (final date in dates.skip(1)) {
    final expectedNextDay = rangeEnd.add(const Duration(days: 1));
    if (isSameDate(date, expectedNextDay)) {
      rangeEnd = date;
      continue;
    }

    ranges.add(formatDateRange(rangeStart, rangeEnd));
    rangeStart = date;
    rangeEnd = date;
  }

  ranges.add(formatDateRange(rangeStart, rangeEnd));
  return ranges.join('\n');
}
