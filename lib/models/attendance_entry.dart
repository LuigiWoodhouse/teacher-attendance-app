import 'attendance_status.dart';
import '../utils/attendance_date_utils.dart';

class AttendanceEntry {
  const AttendanceEntry({
    required this.dayKey,
    required this.status,
  });

  final String dayKey;
  final AttendanceStatus status;

  DateTime get date => dateFromKey(dayKey);

  AttendanceEntry copyWith({
    String? dayKey,
    AttendanceStatus? status,
  }) {
    return AttendanceEntry(
      dayKey: dayKey ?? this.dayKey,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayKey': dayKey,
      'status': status.name,
    };
  }

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceEntry(
      dayKey: json['dayKey'] as String? ?? dateKey(DateTime.now()),
      status: AttendanceStatusX.fromName(json['status'] as String?),
    );
  }
}
