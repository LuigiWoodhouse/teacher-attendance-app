import 'package:flutter/material.dart';

import '../models/attendance_entry.dart';
import '../models/attendance_session.dart';
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
    required this.onLogMorningToday,
    required this.onLogAfternoonToday,
    required this.onEditTeacher,
    required this.onEditEntry,
    required this.onDelete,
  });

  final TeacherRecord teacher;
  final Color backgroundColor;
  final Color outlineColor;
  final VoidCallback onLogAttendance;
  final ValueChanged<AttendanceStatus> onLogMorningToday;
  final ValueChanged<AttendanceStatus> onLogAfternoonToday;
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
    final history = _showAllHistory
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
                label: const Text('Log a session'),
              ),
              _QuickLogMenuButton(
                label: 'Morning today',
                icon: Icons.wb_sunny_outlined,
                session: AttendanceSession.morning,
                onSelected: widget.onLogMorningToday,
              ),
              _QuickLogMenuButton(
                label: 'Afternoon today',
                icon: Icons.brightness_3_outlined,
                session: AttendanceSession.afternoon,
                onSelected: widget.onLogAfternoonToday,
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
                'Older totals were kept, but only new entries show exact dates and sessions.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (history.isEmpty)
            Text(
              'No attendance sessions logged yet.',
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
                      : 'See more${hiddenHistoryCount > 0 ? ' ($hiddenHistoryCount more sessions)' : ''}',
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
    final backgroundColor = entry.status.color.withValues(alpha: 0.12);

    return ActionChip(
      backgroundColor: backgroundColor,
      side: BorderSide(
        color: entry.status.color.withValues(alpha: 0.4),
      ),
      avatar: Icon(
        entry.status.icon,
        size: 18,
        color: entry.status.color,
      ),
      label: Text(
        '${formatDate(entry.date)} ${entry.session.shortLabel} - ${entry.status.label}',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: entry.status.color),
      ),
      onPressed: onTap,
    );
  }
}

class _QuickLogMenuButton extends StatelessWidget {
  const _QuickLogMenuButton({
    required this.label,
    required this.icon,
    required this.session,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final AttendanceSession session;
  final ValueChanged<AttendanceStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AttendanceStatus>(
      tooltip: 'Log ${session.label.toLowerCase()} attendance for today',
      onSelected: onSelected,
      itemBuilder: (context) {
        return AttendanceStatus.values.map((status) {
          return PopupMenuItem<AttendanceStatus>(
            value: status,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(status.icon, size: 18, color: status.color),
                const SizedBox(width: 8),
                Text(status.label),
              ],
            ),
          );
        }).toList(growable: false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
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
