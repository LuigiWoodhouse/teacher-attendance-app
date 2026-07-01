import 'attendance_entry.dart';
import 'attendance_period.dart';
import 'attendance_session.dart';
import 'attendance_status.dart';
import 'attendance_term.dart';

class TeacherRecord {
  const TeacherRecord({
    required this.firstName,
    required this.lastName,
    required this.currentYear,
    this.currentTerm = AttendanceTerm.term3,
    int? legacyYear,
    this.legacyPresentDays = 0,
    this.legacyAbsentDays = 0,
    this.legacyLateDays = 0,
    this.legacyHolidayDays = 0,
    this.entries = const <AttendanceEntry>[],
  }) : legacyYear = legacyYear ?? currentYear;

  final String firstName;
  final String lastName;
  final int currentYear;
  final AttendanceTerm currentTerm;
  final int legacyYear;
  final int legacyPresentDays;
  final int legacyAbsentDays;
  final int legacyLateDays;
  final int legacyHolidayDays;
  final List<AttendanceEntry> entries;

  String get fullName => '$firstName $lastName'.trim();

  AttendancePeriod get currentPeriod => AttendancePeriod(
        year: currentYear,
        term: currentTerm,
      );

  AttendancePeriod get legacyPeriod => AttendancePeriod(
        year: legacyYear,
        term: AttendanceTerm.term3,
      );

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

  int presentDaysForPeriod(int year, AttendanceTerm term) {
    return _legacyCountForPeriod(year, term, legacyYear, legacyPresentDays) +
        entries
            .where(
              (entry) =>
                  entry.year == year &&
                  entry.term == term &&
                  entry.status == AttendanceStatus.present,
            )
            .length;
  }

  int absentDaysForPeriod(int year, AttendanceTerm term) {
    return _legacyCountForPeriod(year, term, legacyYear, legacyAbsentDays) +
        entries
            .where(
              (entry) =>
                  entry.year == year &&
                  entry.term == term &&
                  entry.status == AttendanceStatus.absent,
            )
            .length;
  }

  int lateDaysForPeriod(int year, AttendanceTerm term) {
    return _legacyCountForPeriod(year, term, legacyYear, legacyLateDays) +
        entries
            .where(
              (entry) =>
                  entry.year == year &&
                  entry.term == term &&
                  entry.status == AttendanceStatus.late,
            )
            .length;
  }

  int holidayDaysForPeriod(int year, AttendanceTerm term) {
    return _legacyCountForPeriod(year, term, legacyYear, legacyHolidayDays) +
        entries
            .where(
              (entry) =>
                  entry.year == year &&
                  entry.term == term &&
                  entry.status == AttendanceStatus.holiday,
            )
            .length;
  }

  int presentDaysForTerm(AttendanceTerm term) {
    return _legacyCountForTerm(term, legacyPresentDays) +
        entries
            .where(
              (entry) =>
                  entry.term == term &&
                  entry.status == AttendanceStatus.present,
            )
            .length;
  }

  int absentDaysForTerm(AttendanceTerm term) {
    return _legacyCountForTerm(term, legacyAbsentDays) +
        entries
            .where(
              (entry) =>
                  entry.term == term && entry.status == AttendanceStatus.absent,
            )
            .length;
  }

  int lateDaysForTerm(AttendanceTerm term) {
    return _legacyCountForTerm(term, legacyLateDays) +
        entries
            .where(
              (entry) =>
                  entry.term == term && entry.status == AttendanceStatus.late,
            )
            .length;
  }

  int holidayDaysForTerm(AttendanceTerm term) {
    return _legacyCountForTerm(term, legacyHolidayDays) +
        entries
            .where(
              (entry) =>
                  entry.term == term &&
                  entry.status == AttendanceStatus.holiday,
            )
            .length;
  }

  bool get hasLegacyTotals =>
      legacyPresentDays +
          legacyAbsentDays +
          legacyLateDays +
          legacyHolidayDays >
      0;

  bool hasLegacyTotalsForTerm(AttendanceTerm term) {
    return term == AttendanceTerm.term3 && hasLegacyTotals;
  }

  bool hasLegacyTotalsForPeriod(int year, AttendanceTerm term) {
    return _isLegacyPeriod(year, term, legacyYear) && hasLegacyTotals;
  }

  List<AttendanceEntry> get sortedEntries {
    final sorted = List<AttendanceEntry>.from(entries)
      ..sort(_compareEntriesDescending);
    return sorted;
  }

  List<AttendanceEntry> sortedEntriesForPeriod(int year, AttendanceTerm term) {
    return sortedEntries
        .where((entry) => entry.year == year && entry.term == term)
        .toList(growable: false);
  }

  int get morningSessions => entries
      .where((entry) => entry.session == AttendanceSession.morning)
      .length;

  int get afternoonSessions => entries
      .where((entry) => entry.session == AttendanceSession.afternoon)
      .length;

  int loggedEntriesForTerm(AttendanceTerm term) {
    return entries.where((entry) => entry.term == term).length;
  }

  int loggedEntriesForPeriod(int year, AttendanceTerm term) {
    return entries
        .where((entry) => entry.year == year && entry.term == term)
        .length;
  }

  int morningSessionsForTerm(AttendanceTerm term) {
    return entries
        .where(
          (entry) =>
              entry.term == term && entry.session == AttendanceSession.morning,
        )
        .length;
  }

  int morningSessionsForPeriod(int year, AttendanceTerm term) {
    return entries
        .where(
          (entry) =>
              entry.year == year &&
              entry.term == term &&
              entry.session == AttendanceSession.morning,
        )
        .length;
  }

  int afternoonSessionsForTerm(AttendanceTerm term) {
    return entries
        .where(
          (entry) =>
              entry.term == term &&
              entry.session == AttendanceSession.afternoon,
        )
        .length;
  }

  int afternoonSessionsForPeriod(int year, AttendanceTerm term) {
    return entries
        .where(
          (entry) =>
              entry.year == year &&
              entry.term == term &&
              entry.session == AttendanceSession.afternoon,
        )
        .length;
  }

  int countForSessionAndStatus(
    AttendanceSession session,
    AttendanceStatus status,
  ) {
    return entries
        .where(
          (entry) => entry.session == session && entry.status == status,
        )
        .length;
  }

  int countForTermSessionAndStatus(
    AttendanceTerm term,
    AttendanceSession session,
    AttendanceStatus status,
  ) {
    return entries
        .where(
          (entry) =>
              entry.term == term &&
              entry.session == session &&
              entry.status == status,
        )
        .length;
  }

  int countForPeriodSessionAndStatus(
    int year,
    AttendanceTerm term,
    AttendanceSession session,
    AttendanceStatus status,
  ) {
    return entries
        .where(
          (entry) =>
              entry.year == year &&
              entry.term == term &&
              entry.session == session &&
              entry.status == status,
        )
        .length;
  }

  bool shouldShowInTermSummary(AttendanceTerm term) {
    return currentTerm == term ||
        entries.any((entry) => entry.term == term) ||
        hasLegacyTotalsForTerm(term);
  }

  bool shouldShowInPeriodSummary(int year, AttendanceTerm term) {
    return (currentYear == year && currentTerm == term) ||
        entries.any((entry) => entry.year == year && entry.term == term) ||
        hasLegacyTotalsForPeriod(year, term);
  }

  TeacherRecord copyWith({
    String? firstName,
    String? lastName,
    int? currentYear,
    AttendanceTerm? currentTerm,
    int? legacyYear,
    int? legacyPresentDays,
    int? legacyAbsentDays,
    int? legacyLateDays,
    int? legacyHolidayDays,
    List<AttendanceEntry>? entries,
  }) {
    return TeacherRecord(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      currentYear: currentYear ?? this.currentYear,
      currentTerm: currentTerm ?? this.currentTerm,
      legacyYear: legacyYear ?? this.legacyYear,
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
    required int year,
    required AttendanceTerm term,
    required AttendanceSession session,
    AttendanceEntry? originalEntry,
  }) {
    final nextEntries = List<AttendanceEntry>.from(entries);
    final newEntry = AttendanceEntry(
      dayKey: _dateKey(date),
      year: year,
      term: term,
      session: session,
      status: status,
    );

    if (originalEntry != null) {
      nextEntries.removeWhere(
        (entry) => entry.entryKey == originalEntry.entryKey,
      );
    }

    final existingIndex = nextEntries.indexWhere(
      (entry) => entry.entryKey == newEntry.entryKey,
    );

    if (existingIndex >= 0) {
      nextEntries[existingIndex] = newEntry;
    } else {
      nextEntries.add(newEntry);
    }

    nextEntries.sort(_compareEntriesDescending);
    return copyWith(entries: nextEntries);
  }

  TeacherRecord removeEntry(AttendanceEntry entryToRemove) {
    return copyWith(
      entries: entries
          .where((entry) => entry.entryKey != entryToRemove.entryKey)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'currentYear': currentYear,
      'currentTerm': currentTerm.name,
      'legacyYear': legacyYear,
      'legacyPresentDays': legacyPresentDays,
      'legacyAbsentDays': legacyAbsentDays,
      'legacyLateDays': legacyLateDays,
      'legacyHolidayDays': legacyHolidayDays,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  factory TeacherRecord.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? const <dynamic>[];
    final currentYear =
        _yearFromJson(json['currentYear']) ?? DateTime.now().year;
    final legacyYear = _yearFromJson(json['legacyYear']) ?? currentYear;

    return TeacherRecord(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      currentYear: currentYear,
      currentTerm: AttendanceTermX.fromName(json['currentTerm'] as String?),
      legacyYear: legacyYear,
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
          .map(
            (entry) => AttendanceEntry.fromJson(
              entry,
              defaultYear: legacyYear,
            ),
          )
          .toList(growable: false),
    );
  }
}

int _compareEntriesDescending(AttendanceEntry left, AttendanceEntry right) {
  final yearCompare = right.year.compareTo(left.year);
  if (yearCompare != 0) {
    return yearCompare;
  }

  final dayCompare = right.dayKey.compareTo(left.dayKey);
  if (dayCompare != 0) {
    return dayCompare;
  }

  final termCompare = right.term.sortOrder.compareTo(left.term.sortOrder);
  if (termCompare != 0) {
    return termCompare;
  }

  return right.session.sortOrder.compareTo(left.session.sortOrder);
}

int _legacyCountForTerm(AttendanceTerm term, int count) {
  return term == AttendanceTerm.term3 ? count : 0;
}

int _legacyCountForPeriod(
  int year,
  AttendanceTerm term,
  int legacyYear,
  int count,
) {
  return _isLegacyPeriod(year, term, legacyYear) ? count : 0;
}

bool _isLegacyPeriod(int year, AttendanceTerm term, int legacyYear) {
  return year == legacyYear && term == AttendanceTerm.term3;
}

int? _yearFromJson(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

String _dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
