import 'attendance_entry.dart';
import 'attendance_status.dart';
import '../utils/attendance_date_utils.dart';

class TeacherRecord {
  const TeacherRecord({
    required this.firstName,
    required this.lastName,
    this.legacyPresentDays = 0,
    this.legacyAbsentDays = 0,
    this.legacyLateDays = 0,
    this.legacyHolidayDays = 0,
    this.entries = const <AttendanceEntry>[],
  });

  final String firstName;
  final String lastName;
  final int legacyPresentDays;
  final int legacyAbsentDays;
  final int legacyLateDays;
  final int legacyHolidayDays;
  final List<AttendanceEntry> entries;

  String get fullName => '$firstName $lastName'.trim();

  int get presentDays =>
      legacyPresentDays +
      entries.where((entry) => entry.status == AttendanceStatus.present).length;

  int get absentDays =>
      legacyAbsentDays +
      entries.where((entry) => entry.status == AttendanceStatus.absent).length;

  int get lateDays =>
      legacyLateDays +
      entries.where((entry) => entry.status == AttendanceStatus.late).length;

  int get holidayDays =>
      legacyHolidayDays +
      entries.where((entry) => entry.status == AttendanceStatus.holiday).length;

  bool get hasLegacyTotals =>
      legacyPresentDays +
              legacyAbsentDays +
              legacyLateDays +
              legacyHolidayDays >
          0;

  List<AttendanceEntry> get sortedEntries {
    final sorted = List<AttendanceEntry>.from(entries)
      ..sort((left, right) => right.dayKey.compareTo(left.dayKey));
    return sorted;
  }

  TeacherRecord copyWith({
    String? firstName,
    String? lastName,
    int? legacyPresentDays,
    int? legacyAbsentDays,
    int? legacyLateDays,
    int? legacyHolidayDays,
    List<AttendanceEntry>? entries,
  }) {
    return TeacherRecord(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      legacyPresentDays: legacyPresentDays ?? this.legacyPresentDays,
      legacyAbsentDays: legacyAbsentDays ?? this.legacyAbsentDays,
      legacyLateDays: legacyLateDays ?? this.legacyLateDays,
      legacyHolidayDays: legacyHolidayDays ?? this.legacyHolidayDays,
      entries: entries ?? this.entries,
    );
  }

  TeacherRecord saveEntry({
    required AttendanceStatus status,
    required DateTime date,
    String? originalDayKey,
  }) {
    final nextEntries = List<AttendanceEntry>.from(entries);
    final newDayKey = dateKey(date);

    if (originalDayKey != null) {
      nextEntries.removeWhere((entry) => entry.dayKey == originalDayKey);
    }

    final existingIndex =
        nextEntries.indexWhere((entry) => entry.dayKey == newDayKey);
    final nextEntry = AttendanceEntry(dayKey: newDayKey, status: status);

    if (existingIndex >= 0) {
      nextEntries[existingIndex] = nextEntry;
    } else {
      nextEntries.add(nextEntry);
    }

    nextEntries.sort((left, right) => right.dayKey.compareTo(left.dayKey));
    return copyWith(entries: nextEntries);
  }

  TeacherRecord removeEntry(String dayKey) {
    return copyWith(
      entries: entries.where((entry) => entry.dayKey != dayKey).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'legacyPresentDays': legacyPresentDays,
      'legacyAbsentDays': legacyAbsentDays,
      'legacyLateDays': legacyLateDays,
      'legacyHolidayDays': legacyHolidayDays,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  factory TeacherRecord.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? const <dynamic>[];
    return TeacherRecord(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      legacyPresentDays:
          json['legacyPresentDays'] as int? ?? json['presentDays'] as int? ?? 0,
      legacyAbsentDays:
          json['legacyAbsentDays'] as int? ?? json['absentDays'] as int? ?? 0,
      legacyLateDays:
          json['legacyLateDays'] as int? ?? json['lateDays'] as int? ?? 0,
      legacyHolidayDays:
          json['legacyHolidayDays'] as int? ?? json['holidayDays'] as int? ?? 0,
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map(AttendanceEntry.fromJson)
          .toList(growable: false),
    );
  }
}
