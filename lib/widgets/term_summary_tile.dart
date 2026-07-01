import 'package:flutter/material.dart';

import '../models/attendance_period.dart';
import '../models/attendance_session.dart';
import '../models/attendance_status.dart';
import '../models/teacher_record.dart';

class TermSummaryTile extends StatelessWidget {
  const TermSummaryTile({
    super.key,
    required this.teacher,
    required this.period,
    required this.onTapTeacher,
  });

  final TeacherRecord teacher;
  final AttendancePeriod period;
  final VoidCallback onTapTeacher;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTapTeacher,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Text(
                      teacher.fullName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    'P ${teacher.presentDaysForPeriod(period.year, period.term)}',
                  ),
                  Text(
                    'A ${teacher.absentDaysForPeriod(period.year, period.term)}',
                  ),
                  Text(
                    'L ${teacher.lateDaysForPeriod(period.year, period.term)}',
                  ),
                  Text(
                    'H ${teacher.holidayDaysForPeriod(period.year, period.term)}',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Session breakdown',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _SessionBreakdownTable(teacher: teacher, period: period),
          if (teacher.hasLegacyTotalsForPeriod(period.year, period.term)) ...[
            const SizedBox(height: 8),
            Text(
              'AM/PM rows cover dated session logs. Older carried totals are kept in ${period.label} counts above.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionBreakdownTable extends StatelessWidget {
  const _SessionBreakdownTable({
    required this.teacher,
    required this.period,
  });

  final TeacherRecord teacher;
  final AttendancePeriod period;

  @override
  Widget build(BuildContext context) {
    final headers = AttendanceStatus.values;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9E0E6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 92,
                child: Text(
                  'Session',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ...headers.map(
                (status) => Expanded(
                  child: Center(
                    child: Text(
                      _shortStatusLabel(status),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SessionBreakdownRow(
            label: 'Morning',
            period: period,
            session: AttendanceSession.morning,
            teacher: teacher,
          ),
          const SizedBox(height: 6),
          _SessionBreakdownRow(
            label: 'Afternoon',
            period: period,
            session: AttendanceSession.afternoon,
            teacher: teacher,
          ),
        ],
      ),
    );
  }
}

class _SessionBreakdownRow extends StatelessWidget {
  const _SessionBreakdownRow({
    required this.label,
    required this.period,
    required this.session,
    required this.teacher,
  });

  final String label;
  final AttendancePeriod period;
  final AttendanceSession session;
  final TeacherRecord teacher;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        ...AttendanceStatus.values.map(
          (status) => Expanded(
            child: Center(
              child: Text(
                teacher
                    .countForPeriodSessionAndStatus(
                      period.year,
                      period.term,
                      session,
                      status,
                    )
                    .toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _shortStatusLabel(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return 'P';
    case AttendanceStatus.absent:
      return 'A';
    case AttendanceStatus.late:
      return 'L';
    case AttendanceStatus.holiday:
      return 'H';
  }
}
