import 'package:flutter/material.dart';

import '../models/teacher_record.dart';

class TermSummaryTile extends StatelessWidget {
  const TermSummaryTile({
    super.key,
    required this.teacher,
    required this.onTapTeacher,
  });

  final TeacherRecord teacher;
  final VoidCallback onTapTeacher;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onTapTeacher,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  teacher.fullName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: Theme.of(context).colorScheme.primary,
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
              Text('P ${teacher.presentDays}'),
              Text('A ${teacher.absentDays}'),
              Text('L ${teacher.lateDays}'),
              Text('H ${teacher.holidayDays}'),
            ],
          ),
        ],
      ),
    );
  }
}
