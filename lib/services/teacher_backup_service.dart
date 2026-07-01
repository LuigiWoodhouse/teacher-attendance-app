import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;

import '../models/attendance_entry.dart';
import '../models/attendance_period.dart';
import '../models/attendance_session.dart';
import '../models/attendance_status.dart';
import '../models/attendance_term.dart';
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
    const periodSheetName = 'Term Summaries';
    const logSheetName = 'Session Log';
    final workbook = xl.Excel.createExcel();
    final defaultSheetName = workbook.getDefaultSheet();

    if (defaultSheetName != null && defaultSheetName != summarySheetName) {
      workbook.rename(defaultSheetName, summarySheetName);
    }

    final summarySheet = workbook[summarySheetName];
    final periodSheet = workbook[periodSheetName];
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
      xl.TextCellValue('Default Year'),
      xl.TextCellValue('Default Term'),
      xl.TextCellValue('Number of Days Present'),
      xl.TextCellValue('Number of Days Absent'),
      xl.TextCellValue('Number of Days Late'),
      xl.TextCellValue('Number of Holidays'),
      xl.TextCellValue('Present Dates'),
      xl.TextCellValue('Absent Dates'),
      xl.TextCellValue('Late Dates'),
      xl.TextCellValue('Holiday Dates'),
      xl.TextCellValue('Logged Entries'),
      xl.TextCellValue('Morning Sessions Logged'),
      xl.TextCellValue('Afternoon Sessions Logged'),
      xl.TextCellValue('Present Session Log'),
      xl.TextCellValue('Absent Session Log'),
      xl.TextCellValue('Late Session Log'),
      xl.TextCellValue('Holiday Session Log'),
    ]);

    for (final teacher in teachers) {
      summarySheet.appendRow(<xl.CellValue>[
        xl.TextCellValue(teacher.fullName),
        xl.TextCellValue(teacher.firstName),
        xl.TextCellValue(teacher.lastName),
        xl.IntCellValue(teacher.currentYear),
        xl.TextCellValue(teacher.currentTerm.label),
        xl.IntCellValue(teacher.presentDays),
        xl.IntCellValue(teacher.absentDays),
        xl.IntCellValue(teacher.lateDays),
        xl.IntCellValue(teacher.holidayDays),
        xl.TextCellValue(
          _formatEntriesForStatus(teacher, AttendanceStatus.present),
        ),
        xl.TextCellValue(
          _formatEntriesForStatus(teacher, AttendanceStatus.absent),
        ),
        xl.TextCellValue(
          _formatEntriesForStatus(teacher, AttendanceStatus.late),
        ),
        xl.TextCellValue(
          _formatEntriesForStatus(teacher, AttendanceStatus.holiday),
        ),
        xl.IntCellValue(teacher.entries.length),
        xl.IntCellValue(teacher.morningSessions),
        xl.IntCellValue(teacher.afternoonSessions),
        xl.TextCellValue(
          _formatEntriesForStatus(teacher, AttendanceStatus.present),
        ),
        xl.TextCellValue(
          _formatEntriesForStatus(teacher, AttendanceStatus.absent),
        ),
        xl.TextCellValue(
          _formatEntriesForStatus(teacher, AttendanceStatus.late),
        ),
        xl.TextCellValue(
          _formatEntriesForStatus(teacher, AttendanceStatus.holiday),
        ),
      ]);
    }

    periodSheet.appendRow(<xl.CellValue>[
      xl.TextCellValue(periodSheetName),
    ]);
    periodSheet.appendRow(<xl.CellValue>[
      xl.TextCellValue('Created At'),
      xl.TextCellValue(formatDateTimeForSheet(createdAt)),
    ]);
    periodSheet.appendRow(const <xl.CellValue>[]);
    periodSheet.appendRow(<xl.CellValue>[
      xl.TextCellValue('Full Name'),
      xl.TextCellValue('First Name'),
      xl.TextCellValue('Last Name'),
      xl.TextCellValue('Year'),
      xl.TextCellValue('Term'),
      xl.TextCellValue('Present'),
      xl.TextCellValue('Absent'),
      xl.TextCellValue('Late'),
      xl.TextCellValue('Holidays'),
      xl.TextCellValue('Logged Entries'),
      xl.TextCellValue('Morning Sessions'),
      xl.TextCellValue('Afternoon Sessions'),
    ]);

    for (final teacher in teachers) {
      for (final period in _backupPeriodsForTeacher(teacher)) {
        periodSheet.appendRow(<xl.CellValue>[
          xl.TextCellValue(teacher.fullName),
          xl.TextCellValue(teacher.firstName),
          xl.TextCellValue(teacher.lastName),
          xl.IntCellValue(period.year),
          xl.TextCellValue(period.term.label),
          xl.IntCellValue(
            teacher.presentDaysForPeriod(period.year, period.term),
          ),
          xl.IntCellValue(
            teacher.absentDaysForPeriod(period.year, period.term),
          ),
          xl.IntCellValue(
            teacher.lateDaysForPeriod(period.year, period.term),
          ),
          xl.IntCellValue(
            teacher.holidayDaysForPeriod(period.year, period.term),
          ),
          xl.IntCellValue(
            teacher.loggedEntriesForPeriod(period.year, period.term),
          ),
          xl.IntCellValue(
            teacher.morningSessionsForPeriod(period.year, period.term),
          ),
          xl.IntCellValue(
            teacher.afternoonSessionsForPeriod(period.year, period.term),
          ),
        ]);
      }
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
      xl.TextCellValue('Year'),
      xl.TextCellValue('Term'),
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
          xl.IntCellValue(entry.year),
          xl.TextCellValue(entry.term.label),
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

List<AttendancePeriod> _backupPeriodsForTeacher(TeacherRecord teacher) {
  final periods = <AttendancePeriod>{
    teacher.currentPeriod,
    if (teacher.hasLegacyTotals) teacher.legacyPeriod,
    for (final entry in teacher.entries)
      AttendancePeriod(year: entry.year, term: entry.term),
  }.toList()
    ..sort(_comparePeriodsAscending);

  return periods;
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
        (entry) =>
            '${entry.year} ${entry.term.label} - ${formatDate(entry.date)} '
            '(${entry.session.label})',
      )
      .join('\n');
}

int _compareEntriesAscending(AttendanceEntry left, AttendanceEntry right) {
  final yearCompare = left.year.compareTo(right.year);
  if (yearCompare != 0) {
    return yearCompare;
  }

  final dayCompare = left.dayKey.compareTo(right.dayKey);
  if (dayCompare != 0) {
    return dayCompare;
  }

  final termCompare = left.term.sortOrder.compareTo(right.term.sortOrder);
  if (termCompare != 0) {
    return termCompare;
  }

  return left.session.sortOrder.compareTo(right.session.sortOrder);
}

int _comparePeriodsAscending(AttendancePeriod left, AttendancePeriod right) {
  final yearCompare = left.year.compareTo(right.year);
  if (yearCompare != 0) {
    return yearCompare;
  }

  return left.term.sortOrder.compareTo(right.term.sortOrder);
}
