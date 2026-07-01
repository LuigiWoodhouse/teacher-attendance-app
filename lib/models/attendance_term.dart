enum AttendanceTerm {
  term1,
  term2,
  term3,
}

extension AttendanceTermX on AttendanceTerm {
  String get label {
    switch (this) {
      case AttendanceTerm.term1:
        return 'Term 1';
      case AttendanceTerm.term2:
        return 'Term 2';
      case AttendanceTerm.term3:
        return 'Term 3';
    }
  }

  String get summaryLabel {
    switch (this) {
      case AttendanceTerm.term1:
        return 'End of Term 1 Summary';
      case AttendanceTerm.term2:
        return 'End of Term 2 Summary';
      case AttendanceTerm.term3:
        return 'End of Term 3 Summary';
    }
  }

  String get shortLabel {
    switch (this) {
      case AttendanceTerm.term1:
        return 'T1';
      case AttendanceTerm.term2:
        return 'T2';
      case AttendanceTerm.term3:
        return 'T3';
    }
  }

  int get sortOrder {
    switch (this) {
      case AttendanceTerm.term1:
        return 0;
      case AttendanceTerm.term2:
        return 1;
      case AttendanceTerm.term3:
        return 2;
    }
  }

  static AttendanceTerm fromName(String? value) {
    switch (value) {
      case 'term1':
        return AttendanceTerm.term1;
      case 'term2':
        return AttendanceTerm.term2;
      case 'term3':
      default:
        return AttendanceTerm.term3;
    }
  }
}
