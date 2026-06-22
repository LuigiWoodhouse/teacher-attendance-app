import 'attendance_session.dart';
import 'attendance_status.dart';
import '../utils/attendance_date_utils.dart';

class AttendanceEntry {
  const AttendanceEntry({
    required this.dayKey,
    required this.session,
    required this.status,
  });

  final String dayKey;
  final AttendanceSession session;
  final AttendanceStatus status;

  DateTime get date => dateFromKey(dayKey);
  String get entryKey => '$dayKey#${session.name}';

  AttendanceEntry copyWith({
    String? dayKey,
    AttendanceSession? session,
    AttendanceStatus? status,
  }) {
    return AttendanceEntry(
      dayKey: dayKey ?? this.dayKey,
      session: session ?? this.session,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayKey': dayKey,
      'session': session.name,
      'status': status.name,
    };
  }

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceEntry(
      dayKey: json['dayKey'] as String? ?? dateKey(DateTime.now()),
      session: AttendanceSessionX.fromName(json['session'] as String?),
      status: AttendanceStatusX.fromName(json['status'] as String?),
    );
  }
}
