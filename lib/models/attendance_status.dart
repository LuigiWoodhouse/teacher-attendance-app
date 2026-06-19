import 'package:flutter/material.dart';

enum AttendanceStatus {
  present,
  absent,
  late,
  holiday,
}

extension AttendanceStatusX on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.holiday:
        return 'Holiday';
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present:
        return Icons.check_circle_outline;
      case AttendanceStatus.absent:
        return Icons.highlight_off;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.holiday:
        return Icons.beach_access_outlined;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return const Color(0xFF1C7C54);
      case AttendanceStatus.absent:
        return const Color(0xFFC44536);
      case AttendanceStatus.late:
        return const Color(0xFFD9822B);
      case AttendanceStatus.holiday:
        return const Color(0xFF4C6FFF);
    }
  }

  static AttendanceStatus fromName(String? value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'holiday':
        return AttendanceStatus.holiday;
      default:
        return AttendanceStatus.present;
    }
  }
}
