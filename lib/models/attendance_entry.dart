import 'attendance_session.dart';
import 'attendance_status.dart';
import 'attendance_term.dart';
import '../utils/attendance_date_utils.dart';

class AttendanceEntry {
  const AttendanceEntry({
    required this.dayKey,
    required this.year,
    required this.term,
    required this.session,
    required this.status,
  });

  final String dayKey;
  final int year;
  final AttendanceTerm term;
  final AttendanceSession session;
  final AttendanceStatus status;

  DateTime get date => dateFromKey(dayKey);
  String get entryKey => '$year#$dayKey#${term.name}#${session.name}';

  AttendanceEntry copyWith({
    String? dayKey,
    int? year,
    AttendanceTerm? term,
    AttendanceSession? session,
    AttendanceStatus? status,
  }) {
    return AttendanceEntry(
      dayKey: dayKey ?? this.dayKey,
      year: year ?? this.year,
      term: term ?? this.term,
      session: session ?? this.session,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayKey': dayKey,
      'year': year,
      'term': term.name,
      'session': session.name,
      'status': status.name,
    };
  }

  factory AttendanceEntry.fromJson(
    Map<String, dynamic> json, {
    int? defaultYear,
  }) {
    final dayKey = json['dayKey'] as String? ?? dateKey(DateTime.now());
    return AttendanceEntry(
      dayKey: dayKey,
      year: _yearFromJson(json['year']) ??
          defaultYear ??
          dateFromKey(dayKey).year,
      term: AttendanceTermX.fromName(json['term'] as String?),
      session: AttendanceSessionX.fromName(json['session'] as String?),
      status: AttendanceStatusX.fromName(json['status'] as String?),
    );
  }
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
