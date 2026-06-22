import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;

import '../models/attendance_entry.dart';
import '../models/attendance_session.dart';
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
    const summarySheetName = 'Teacher Attendance';
    const logSheetName = 'Session Log';
    final workbook = xl.Excel.createExcel();
    final defaultSheetName = workbook.getDefaultSheet();

    if (defaultSheetName != null && defaultSheetName != summarySheetName) {
      workbook.rename(defaultSheetName, summarySheetName);
    }

    final summarySheet = workbook[summarySheetName];
    final logSheet = workbook[logSheetName];

    summarySheet.appendRow(<xl.CellValue>[
      xl.TextCellValue(summarySheetName),
    ]);
    summarySheet.appendRow(<xl.CellValue>[
      xl.TextCellValue('Created At'),
      xl.TextCellValue(formatDateTimeForSheet(createdAt)),
    ]);
    summarySheet.appendRow(const <xl.CellValue>[]);
    summarySheet.appendRow(<xl.CellValue>[
      xl.TextCellValue('Full Name'),
      xl.TextCellValue('First Name'),
      xl.TextCellValue('Last Name'),
      xl.TextCellValue('Present Sessions'),
      xl.TextCellValue('Absent Sessions'),
      xl.TextCellValue('Late Sessions'),
      xl.TextCellValue('Holiday Sessions'),
      xl.TextCellValue('Morning Sessions Logged'),
      xl.TextCellValue('Afternoon Sessions Logged'),
      xl.TextCellValue('Present Session Log'),
      xl.TextCellValue('Absent Session Log'),
      xl.TextCellValue('Late Session Log'),
      xl.TextCellValue('Holiday Session Log'),
      xl.TextCellValue('Logged Sessions'),
    ]);

    for (final teacher in teachers) {
      summarySheet.appendRow(<xl.CellValue>[
        xl.TextCellValue(teacher.fullName),
        xl.TextCellValue(teacher.firstName),
        xl.TextCellValue(teacher.lastName),
        xl.IntCellValue(teacher.presentDays),
        xl.IntCellValue(teacher.absentDays),
        xl.IntCellValue(teacher.lateDays),
        xl.IntCellValue(teacher.holidayDays),
        xl.IntCellValue(teacher.morningSessions),
        xl.IntCellValue(teacher.afternoonSessions),
        xl.TextCellValue(
            _formatEntriesForStatus(teacher, AttendanceStatus.present)),
        xl.TextCellValue(
            _formatEntriesForStatus(teacher, AttendanceStatus.absent)),
        xl.TextCellValue(
            _formatEntriesForStatus(teacher, AttendanceStatus.late)),
        xl.TextCellValue(
            _formatEntriesForStatus(teacher, AttendanceStatus.holiday)),
        xl.IntCellValue(teacher.entries.length),
      ]);
    }

    logSheet.appendRow(<xl.CellValue>[
      xl.TextCellValue(logSheetName),
    ]);
    logSheet.appendRow(<xl.CellValue>[
      xl.TextCellValue('Created At'),
      xl.TextCellValue(formatDateTimeForSheet(createdAt)),
    ]);
    logSheet.appendRow(const <xl.CellValue>[]);
    logSheet.appendRow(<xl.CellValue>[
      xl.TextCellValue('Full Name'),
      xl.TextCellValue('First Name'),
      xl.TextCellValue('Last Name'),
      xl.TextCellValue('Date'),
      xl.TextCellValue('Session'),
      xl.TextCellValue('Status'),
    ]);

    for (final teacher in teachers) {
      for (final entry in teacher.sortedEntries) {
        logSheet.appendRow(<xl.CellValue>[
          xl.TextCellValue(teacher.fullName),
          xl.TextCellValue(teacher.firstName),
          xl.TextCellValue(teacher.lastName),
          xl.TextCellValue(formatDate(entry.date)),
          xl.TextCellValue(entry.session.label),
          xl.TextCellValue(entry.status.label),
        ]);
      }
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
  Future<File> writeTemporaryBackupFile(
      String fileName, Uint8List bytes) async {
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

String _formatEntriesForStatus(TeacherRecord teacher, AttendanceStatus status) {
  final matchingEntries = teacher.entries
      .where((entry) => entry.status == status)
      .toList()
    ..sort(_compareEntriesAscending);

  if (matchingEntries.isEmpty) {
    return '';
  }

  return matchingEntries
      .map(
        (entry) => '${formatDate(entry.date)} (${entry.session.label})',
      )
      .join('\n');
}

int _compareEntriesAscending(AttendanceEntry left, AttendanceEntry right) {
  final dayCompare = left.dayKey.compareTo(right.dayKey);
  if (dayCompare != 0) {
    return dayCompare;
  }

  return left.session.sortOrder.compareTo(right.session.sortOrder);
}
