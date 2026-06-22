enum AttendanceSession {
  morning,
  afternoon,
}

extension AttendanceSessionX on AttendanceSession {
  String get label {
    switch (this) {
      case AttendanceSession.morning:
        return 'Morning';
      case AttendanceSession.afternoon:
        return 'Afternoon';
    }
  }

  String get shortLabel {
    switch (this) {
      case AttendanceSession.morning:
        return 'AM';
      case AttendanceSession.afternoon:
        return 'PM';
    }
  }

  int get sortOrder {
    switch (this) {
      case AttendanceSession.morning:
        return 0;
      case AttendanceSession.afternoon:
        return 1;
    }
  }

  static AttendanceSession fromName(String? value) {
    switch (value) {
      case 'afternoon':
        return AttendanceSession.afternoon;
      case 'morning':
      default:
        return AttendanceSession.morning;
    }
  }
}
