import 'package:flutter/material.dart';

import '../models/attendance_entry.dart';
import '../models/attendance_status.dart';
import '../models/teacher_record.dart';
import '../utils/attendance_date_utils.dart';

class TeacherCard extends StatefulWidget {
  const TeacherCard({
    super.key,
    required this.teacher,
    required this.backgroundColor,
    required this.outlineColor,
    required this.onLogAttendance,
    required this.onPresent,
    required this.onAbsent,
    required this.onLate,
    required this.onHoliday,
    required this.onEditTeacher,
    required this.onEditEntry,
    required this.onDelete,
  });

  final TeacherRecord teacher;
  final Color backgroundColor;
  final Color outlineColor;
  final VoidCallback onLogAttendance;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final VoidCallback onLate;
  final VoidCallback onHoliday;
  final VoidCallback onEditTeacher;
  final ValueChanged<AttendanceEntry> onEditEntry;
  final VoidCallback onDelete;

  @override
  State<TeacherCard> createState() => _TeacherCardState();
}

class _TeacherCardState extends State<TeacherCard> {
  static const int _collapsedHistoryCount = 5;

  bool _showAllHistory = false;

  @override
  Widget build(BuildContext context) {
    final allHistory = widget.teacher.sortedEntries;
    final hasHiddenHistory = allHistory.length > _collapsedHistoryCount;
    final history =
        _showAllHistory
            ? allHistory
            : allHistory.take(_collapsedHistoryCount).toList(growable: false);
    final hiddenHistoryCount = allHistory.length - history.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: widget.outlineColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: widget.outlineColor.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  widget.teacher.firstName.isEmpty
                      ? '?'
                      : widget.teacher.firstName[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.teacher.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                onPressed: widget.onEditTeacher,
                tooltip: 'Edit teacher',
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: widget.onDelete,
                tooltip: 'Remove teacher',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(label: 'Present', value: widget.teacher.presentDays),
              _StatPill(label: 'Absent', value: widget.teacher.absentDays),
              _StatPill(label: 'Late', value: widget.teacher.lateDays),
              _StatPill(label: 'Holiday', value: widget.teacher.holidayDays),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: widget.onLogAttendance,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Log a day'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onPresent,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Present today'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onLate,
                icon: const Icon(Icons.schedule),
                label: const Text('Late today'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onAbsent,
                icon: const Icon(Icons.highlight_off),
                label: const Text('Absent today'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onHoliday,
                icon: const Icon(Icons.beach_access_outlined),
                label: const Text('Holiday today'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Attendance log',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (widget.teacher.hasLegacyTotals)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Older totals were kept, but only new entries show exact dates.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (history.isEmpty)
            Text(
              'No dated attendance logged yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history
                  .map(
                    (entry) => _AttendanceEntryChip(
                      entry: entry,
                      onTap: () => widget.onEditEntry(entry),
                    ),
                  )
                  .toList(growable: false),
            ),
            if (hasHiddenHistory) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllHistory = !_showAllHistory;
                  });
                },
                icon: Icon(
                  _showAllHistory
                      ? Icons.expand_less_outlined
                      : Icons.expand_more_outlined,
                ),
                label: Text(
                  _showAllHistory
                      ? 'Show less'
                      : 'See more${hiddenHistoryCount > 0 ? ' ($hiddenHistoryCount more days)' : ''}',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AttendanceEntryChip extends StatelessWidget {
  const _AttendanceEntryChip({
    required this.entry,
    required this.onTap,
  });

  final AttendanceEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        entry.status.icon,
        size: 18,
        color: entry.status.color,
      ),
      label: Text('${formatDate(entry.date)} - ${entry.status.label}'),
      onPressed: onTap,
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}
