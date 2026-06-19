import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../models/attendance_entry.dart';
import '../models/attendance_status.dart';
import '../models/teacher_name_draft.dart';
import '../models/teacher_record.dart';
import '../services/teacher_backup_service.dart';
import '../services/teacher_records_store.dart';
import '../utils/attendance_date_utils.dart';
import '../widgets/add_teacher_form.dart';
import '../widgets/backup_card.dart';
import '../widgets/edit_teacher_dialog.dart';
import '../widgets/empty_states.dart';
import '../widgets/summary_header.dart';
import '../widgets/teacher_card.dart';
import '../widgets/term_summary_tile.dart';

class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({
    super.key,
    required this.recordsStore,
    required this.backupService,
  });

  final TeacherRecordsStore recordsStore;
  final TeacherBackupService backupService;

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _scrollController = ScrollController();
  final List<TeacherRecord> _teachers = <TeacherRecord>[];
  final List<GlobalKey> _teacherCardKeys = <GlobalKey>[];

  bool _isBackingUp = false;
  bool _isSharing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    final teachers = await widget.recordsStore.loadTeachers();

    if (!mounted) {
      return;
    }

    setState(() {
      _teachers
        ..clear()
        ..addAll(teachers);
      _isLoading = false;
    });
  }

  Future<void> _saveTeachers() {
    return widget.recordsStore.saveTeachers(_teachers);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addTeacher() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showMessage('Enter both first and last name.');
      return;
    }

    setState(() {
      _teachers.add(TeacherRecord(firstName: firstName, lastName: lastName));
      _firstNameController.clear();
      _lastNameController.clear();
    });

    await _saveTeachers();
  }

  Future<void> _editTeacherName(int index) async {
    final teacher = _teachers[index];
    final updatedName = await showDialog<TeacherNameDraft>(
      context: context,
      builder: (_) {
        return EditTeacherDialog(
          initialFirstName: teacher.firstName,
          initialLastName: teacher.lastName,
        );
      },
    );

    if (!mounted || updatedName == null) {
      return;
    }

    setState(() {
      _teachers[index] = teacher.copyWith(
        firstName: updatedName.firstName,
        lastName: updatedName.lastName,
      );
    });

    await _saveTeachers();
    _showMessage('Teacher name updated.');
  }

  Future<void> _saveAttendanceEntry(
    int teacherIndex, {
    required AttendanceStatus status,
    required DateTime date,
    String? originalDayKey,
  }) async {
    final teacher = _teachers[teacherIndex];

    setState(() {
      _teachers[teacherIndex] = teacher.saveEntry(
        status: status,
        date: date,
        originalDayKey: originalDayKey,
      );
    });

    await _saveTeachers();
    _showMessage('${status.label} saved for ${formatDate(date)}.');
  }

  Future<void> _removeAttendanceEntry(int teacherIndex, String dayKey) async {
    final teacher = _teachers[teacherIndex];

    setState(() {
      _teachers[teacherIndex] = teacher.removeEntry(dayKey);
    });

    await _saveTeachers();
    _showMessage('Attendance entry removed.');
  }

  Future<void> _openAttendanceDialog(
    int teacherIndex, {
    AttendanceEntry? existingEntry,
  }) async {
    DateTime selectedDate = existingEntry?.date ?? DateTime.now();
    AttendanceStatus selectedStatus =
        existingEntry?.status ?? AttendanceStatus.present;
    AttendanceDialogAction? action;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existingEntry == null ? 'Log attendance' : 'Edit attendance',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedDate = pickedDate;
                      });
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(formatDate(selectedDate)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AttendanceStatus.values.map((status) {
                      final isSelected = status == selectedStatus;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(status.label),
                        avatar: Icon(status.icon, size: 18),
                        onSelected: (_) {
                          setDialogState(() {
                            selectedStatus = status;
                          });
                        },
                      );
                    }).toList(growable: false),
                  ),
                ],
              ),
              actions: [
                if (existingEntry != null)
                  TextButton(
                    onPressed: () {
                      action = AttendanceDialogAction.delete;
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    action = AttendanceDialogAction.save;
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(existingEntry == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == AttendanceDialogAction.delete && existingEntry != null) {
      await _removeAttendanceEntry(teacherIndex, existingEntry.dayKey);
      return;
    }

    await _saveAttendanceEntry(
      teacherIndex,
      status: selectedStatus,
      date: selectedDate,
      originalDayKey: existingEntry?.dayKey,
    );
  }

  Future<void> _logToday(int teacherIndex, AttendanceStatus status) async {
    final teacher = _teachers[teacherIndex];
    final today = DateTime.now();
    final todayKey = dateKey(today);
    final existingEntry = teacher.entries
        .cast<AttendanceEntry?>()
        .firstWhere((entry) => entry?.dayKey == todayKey, orElse: () => null);

    await _saveAttendanceEntry(
      teacherIndex,
      status: status,
      date: today,
      originalDayKey: existingEntry?.dayKey,
    );
  }

  Future<void> _removeTeacher(int index) async {
    setState(() {
      _teachers.removeAt(index);
    });

    await _saveTeachers();
  }

  GlobalKey _teacherCardKeyAt(int index) {
    while (_teacherCardKeys.length <= index) {
      _teacherCardKeys.add(GlobalKey());
    }
    return _teacherCardKeys[index];
  }

  Future<void> _scrollToTeacherCard(int index) async {
    if (!mounted) {
      return;
    }

    final targetContext = _teacherCardKeyAt(index).currentContext;
    if (targetContext == null) {
      return;
    }

    final targetObject = targetContext.findRenderObject();
    if (targetObject == null || !_scrollController.hasClients) {
      return;
    }

    final viewport = RenderAbstractViewport.of(targetObject);
    final targetOffset = viewport.getOffsetToReveal(targetObject, 0.08).offset;
    final clampedOffset = targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _confirmRemoveTeacher(int index) async {
    final teacher = _teachers[index];
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete teacher?'),
          content: Text(
            'Remove ${teacher.fullName} and all saved attendance records?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await _removeTeacher(index);
    _showMessage('Teacher removed.');
  }

  Future<void> _backupTeachers() async {
    if (_teachers.isEmpty) {
      _showMessage('Add at least one teacher before creating a backup.');
      return;
    }

    setState(() {
      _isBackingUp = true;
    });

    try {
      final now = DateTime.now();
      final bytes = widget.backupService.buildBackupBytes(
        _teachers,
        createdAt: now,
      );
      final defaultFileName = widget.backupService.buildBackupFileName(now);
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save teacher attendance backup',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: const <String>['xlsx'],
        bytes: bytes,
      );

      if (savedPath == null) {
        if (mounted) {
          _showMessage('Backup canceled.');
        }
        return;
      }

      if (!Platform.isAndroid && !Platform.isIOS) {
        final backupFile = File(savedPath);
        await backupFile.writeAsBytes(bytes, flush: true);
      }

      if (!mounted) {
        return;
      }

      _showMessage('Backup saved to $savedPath.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Backup failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _shareTeachersBackup(BuildContext shareContext) async {
    if (_teachers.isEmpty) {
      _showMessage('Add at least one teacher before sharing a backup.');
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final now = DateTime.now();
      final fileName = widget.backupService.buildBackupFileName(now);
      final bytes = widget.backupService.buildBackupBytes(
        _teachers,
        createdAt: now,
      );
      final box = shareContext.findRenderObject() as RenderBox?;
      final tempFile = await widget.backupService.writeTemporaryBackupFile(
        fileName,
        bytes,
      );

      await Share.shareXFiles(
        <XFile>[
          XFile(
            tempFile.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'Teacher attendance backup',
        text: 'Teacher attendance backup',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Backup ready to share.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Share failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  int get _totalPresent =>
      _teachers.fold(0, (sum, teacher) => sum + teacher.presentDays);

  int get _totalAbsent =>
      _teachers.fold(0, (sum, teacher) => sum + teacher.absentDays);

  int get _totalLate =>
      _teachers.fold(0, (sum, teacher) => sum + teacher.lateDays);

  int get _totalHoliday =>
      _teachers.fold(0, (sum, teacher) => sum + teacher.holidayDays);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Attendance')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SummaryHeader(
                      teacherCount: _teachers.length,
                      totalPresent: _totalPresent,
                      totalAbsent: _totalAbsent,
                      totalLate: _totalLate,
                      totalHoliday: _totalHoliday,
                    ),
                    const SizedBox(height: 16),
                    BackupCard(
                      isBackingUp: _isBackingUp,
                      isSharing: _isSharing,
                      hasTeachers: _teachers.isNotEmpty,
                      onBackup: _backupTeachers,
                      onShare: _shareTeachersBackup,
                    ),
                    const SizedBox(height: 16),
                    AddTeacherForm(
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      onAddTeacher: _addTeacher,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Teacher register',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (_teachers.isEmpty)
                      const EmptyState()
                    else
                      ...List.generate(
                        _teachers.length,
                        (index) => Padding(
                          key: _teacherCardKeyAt(index),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TeacherCard(
                            teacher: _teachers[index],
                            backgroundColor: index.isEven
                                ? const Color(0xFFF6FBF7)
                                : const Color(0xFFF2F7F3),
                            outlineColor: index.isEven
                                ? const Color(0xFFCEE5D4)
                                : const Color(0xFFB8D5C0),
                            onLogAttendance: () => _openAttendanceDialog(index),
                            onPresent: () =>
                                _logToday(index, AttendanceStatus.present),
                            onAbsent: () =>
                                _logToday(index, AttendanceStatus.absent),
                            onLate: () =>
                                _logToday(index, AttendanceStatus.late),
                            onHoliday: () =>
                                _logToday(index, AttendanceStatus.holiday),
                            onEditTeacher: () => _editTeacherName(index),
                            onEditEntry: (entry) => _openAttendanceDialog(
                              index,
                              existingEntry: entry,
                            ),
                            onDelete: () => _confirmRemoveTeacher(index),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'End of term summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (_teachers.isEmpty)
                      const SummaryPlaceholder()
                    else
                      ...List.generate(
                        _teachers.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TermSummaryTile(
                            teacher: _teachers[index],
                            onTapTeacher: () => _scrollToTeacherCard(index),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

enum AttendanceDialogAction {
  save,
  delete,
}
