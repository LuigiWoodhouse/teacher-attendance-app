import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_app/models/attendance_session.dart';
import 'package:teacher_app/models/attendance_status.dart';
import 'package:teacher_app/models/attendance_term.dart';
import 'package:teacher_app/models/teacher_record.dart';

void main() {
  test('old teachers and attendance entries default to current year term 3',
      () {
    final currentYear = DateTime.now().year;
    final teacher = TeacherRecord.fromJson({
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'legacyPresentDays': 2,
      'entries': [
        {
          'dayKey': '2026-06-24',
          'session': 'morning',
          'status': 'present',
        },
      ],
    });

    expect(teacher.currentYear, currentYear);
    expect(teacher.currentTerm, AttendanceTerm.term3);
    expect(teacher.entries.single.year, currentYear);
    expect(teacher.entries.single.term, AttendanceTerm.term3);
    expect(teacher.presentDaysForPeriod(currentYear, AttendanceTerm.term3), 3);
    expect(teacher.presentDaysForPeriod(currentYear, AttendanceTerm.term1), 0);
  });

  test('same date and session can be recorded in different periods', () {
    final date = DateTime(2026, 6, 24);
    final teacher = const TeacherRecord(
      firstName: 'Grace',
      lastName: 'Hopper',
      currentYear: 2021,
    )
        .saveEntry(
          status: AttendanceStatus.present,
          date: date,
          year: 2020,
          term: AttendanceTerm.term1,
          session: AttendanceSession.morning,
        )
        .saveEntry(
          status: AttendanceStatus.absent,
          date: date,
          year: 2021,
          term: AttendanceTerm.term1,
          session: AttendanceSession.morning,
        );

    expect(teacher.entries, hasLength(2));
    expect(teacher.presentDaysForPeriod(2020, AttendanceTerm.term1), 1);
    expect(teacher.absentDaysForPeriod(2021, AttendanceTerm.term1), 1);
    expect(
      teacher.countForPeriodSessionAndStatus(
        2020,
        AttendanceTerm.term1,
        AttendanceSession.morning,
        AttendanceStatus.present,
      ),
      1,
    );
  });

  test('legacy term 3 totals do not appear in other selected periods', () {
    final teacher = const TeacherRecord(
      firstName: 'Katherine',
      lastName: 'Johnson',
      currentYear: 2021,
      currentTerm: AttendanceTerm.term1,
      legacyYear: 2020,
      legacyPresentDays: 4,
    ).saveEntry(
      status: AttendanceStatus.present,
      date: DateTime(2021, 1, 12),
      year: 2021,
      term: AttendanceTerm.term1,
      session: AttendanceSession.morning,
    );

    expect(teacher.presentDaysForPeriod(2021, AttendanceTerm.term1), 1);
    expect(teacher.presentDaysForPeriod(2021, AttendanceTerm.term3), 0);
    expect(teacher.presentDaysForPeriod(2020, AttendanceTerm.term3), 4);
  });
}
