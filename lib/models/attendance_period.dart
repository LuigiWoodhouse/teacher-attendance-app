import 'attendance_term.dart';

class AttendancePeriod {
  const AttendancePeriod({
    required this.year,
    required this.term,
  });

  final int year;
  final AttendanceTerm term;

  String get label => '$year ${term.label}';
  String get shortLabel => '$year ${term.shortLabel}';
  String get summaryLabel => '$year ${term.summaryLabel}';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendancePeriod &&
            runtimeType == other.runtimeType &&
            year == other.year &&
            term == other.term;
  }

  @override
  int get hashCode => Object.hash(year, term);
}
