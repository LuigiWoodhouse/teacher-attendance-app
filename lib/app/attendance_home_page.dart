import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../models/attendance_entry.dart';
import '../models/attendance_period.dart';
import '../models/attendance_session.dart';
import '../models/attendance_status.dart';
import '../models/attendance_term.dart';
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
import '../widgets/year_picker_field.dart';

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
  int _selectedNewTeacherYear = DateTime.now().year;
  AttendanceTerm _selectedNewTeacherTerm = AttendanceTerm.term3;
  String? _appVersionLabel;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
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

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final versionLabel = 'v${packageInfo.version}+${packageInfo.buildNumber}';

    if (!mounted) {
      return;
    }

    setState(() {
      _appVersionLabel = versionLabel;
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
      _teachers.add(
        TeacherRecord(
          firstName: firstName,
          lastName: lastName,
          currentYear: _selectedNewTeacherYear,
          currentTerm: _selectedNewTeacherTerm,
        ),
      );
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

  Future<void> _changeTeacherPeriod(
    int index,
    AttendancePeriod period,
  ) async {
    final teacher = _teachers[index];

    if (teacher.currentPeriod == period) {
      return;
    }

    setState(() {
      _teachers[index] = teacher.copyWith(
        currentYear: period.year,
        currentTerm: period.term,
      );
    });

    await _saveTeachers();
    _showMessage('${teacher.fullName} set to ${period.label}.');
  }

  Future<void> _saveAttendanceEntry(
    int teacherIndex, {
    required AttendanceStatus status,
    required DateTime date,
    required int year,
    required AttendanceTerm term,
    required AttendanceSession session,
    AttendanceEntry? originalEntry,
  }) async {
    final teacher = _teachers[teacherIndex];

    setState(() {
      _teachers[teacherIndex] = teacher.saveEntry(
        status: status,
        date: date,
        year: year,
        term: term,
        session: session,
        originalEntry: originalEntry,
      );
    });

    await _saveTeachers();
    _showMessage(
      '$year ${term.label} ${session.label.toLowerCase()} '
      '${status.label.toLowerCase()} saved for ${formatDate(date)}.',
    );
  }

  Future<void> _removeAttendanceEntry(
    int teacherIndex,
    AttendanceEntry entry,
  ) async {
    final teacher = _teachers[teacherIndex];

    setState(() {
      _teachers[teacherIndex] = teacher.removeEntry(entry);
    });

    await _saveTeachers();
    _showMessage('Attendance entry removed.');
  }

  Future<void> _openAttendanceDialog(
    int teacherIndex, {
    AttendanceEntry? existingEntry,
  }) async {
    DateTime selectedDate = existingEntry?.date ?? DateTime.now();
    int selectedYear =
        existingEntry?.year ?? _teachers[teacherIndex].currentYear;
    AttendanceTerm selectedTerm =
        existingEntry?.term ?? _teachers[teacherIndex].currentTerm;
    AttendanceSession selectedSession =
        existingEntry?.session ?? AttendanceSession.morning;
    AttendanceStatus selectedStatus =
        existingEntry?.status ?? AttendanceStatus.present;
    AttendanceDialogAction? action;
    final yearOptions = _yearOptions;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existingEntry == null ? 'Log attendance' : 'Edit attendance',
              ),
              content: SingleChildScrollView(
                child: Column(
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
                    YearPickerField(
                      key: ValueKey('attendance-year-$selectedYear'),
                      selectedYear: selectedYear,
                      firstYear: yearOptions.last,
                      lastYear: yearOptions.first,
                      dialogTitle: 'Select attendance year',
                      onChanged: (year) {
                        setDialogState(() {
                          selectedYear = year;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Term',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AttendanceTerm.values.map((term) {
                        final isSelected = term == selectedTerm;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(term.label),
                          onSelected: (_) {
                            setDialogState(() {
                              selectedTerm = term;
                            });
                          },
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Session',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AttendanceSession.values.map((session) {
                        final isSelected = session == selectedSession;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(session.label),
                          onSelected: (_) {
                            setDialogState(() {
                              selectedSession = session;
                            });
                          },
                        );
                      }).toList(growable: false),
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
      await _removeAttendanceEntry(teacherIndex, existingEntry);
      return;
    }

    await _saveAttendanceEntry(
      teacherIndex,
      status: selectedStatus,
      date: selectedDate,
      year: selectedYear,
      term: selectedTerm,
      session: selectedSession,
      originalEntry: existingEntry,
    );
  }

  Future<void> _logToday(
    int teacherIndex,
    AttendanceSession session,
    AttendanceStatus status,
  ) async {
    final teacher = _teachers[teacherIndex];
    final period = teacher.currentPeriod;
    final today = DateTime.now();
    final existingEntry = _entryForDatePeriodAndSession(
      teacher,
      today,
      period.year,
      period.term,
      session,
    );

    await _saveAttendanceEntry(
      teacherIndex,
      status: status,
      date: today,
      year: period.year,
      term: period.term,
      session: session,
      originalEntry: existingEntry,
    );
  }

  AttendanceEntry? _entryForDatePeriodAndSession(
    TeacherRecord teacher,
    DateTime date,
    int year,
    AttendanceTerm term,
    AttendanceSession session,
  ) {
    final dayKey = dateKey(date);
    return teacher.entries.cast<AttendanceEntry?>().firstWhere(
          (entry) =>
              entry?.dayKey == dayKey &&
              entry?.year == year &&
              entry?.term == term &&
              entry?.session == session,
          orElse: () => null,
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

  int get _totalPresent => _teachers.fold(
        0,
        (sum, teacher) =>
            sum +
            teacher.presentDaysForPeriod(
              teacher.currentYear,
              teacher.currentTerm,
            ),
      );

  int get _totalAbsent => _teachers.fold(
        0,
        (sum, teacher) =>
            sum +
            teacher.absentDaysForPeriod(
              teacher.currentYear,
              teacher.currentTerm,
            ),
      );

  int get _totalLate => _teachers.fold(
        0,
        (sum, teacher) =>
            sum +
            teacher.lateDaysForPeriod(
              teacher.currentYear,
              teacher.currentTerm,
            ),
      );

  int get _totalHoliday => _teachers.fold(
        0,
        (sum, teacher) =>
            sum +
            teacher.holidayDaysForPeriod(
              teacher.currentYear,
              teacher.currentTerm,
            ),
      );

  List<int> get _yearOptions {
    final currentYear = DateTime.now().year;
    final years = <int>{
      for (var year = 2020; year <= currentYear + 1; year += 1) year,
      _selectedNewTeacherYear,
      ..._teachers.map((teacher) => teacher.currentYear),
      ..._teachers.map((teacher) => teacher.legacyYear),
      for (final teacher in _teachers)
        ...teacher.entries.map((entry) => entry.year),
    }.toList()
      ..sort((left, right) => right.compareTo(left));

    return years;
  }

  List<AttendancePeriod> get _periodOptions {
    return <AttendancePeriod>[
      for (final year in _yearOptions)
        for (final term in AttendanceTerm.values)
          AttendancePeriod(year: year, term: term),
    ];
  }

  List<AttendancePeriod> get _summaryPeriods {
    final years = <int>{
      _selectedNewTeacherYear,
      for (final teacher in _teachers) teacher.currentYear,
      for (final teacher in _teachers)
        if (teacher.hasLegacyTotals) teacher.legacyYear,
      for (final teacher in _teachers)
        for (final entry in teacher.entries) entry.year,
    };

    final periods = <AttendancePeriod>{
      for (final year in years)
        for (final term in AttendanceTerm.values)
          AttendancePeriod(year: year, term: term),
    }.toList()
      ..sort(_comparePeriodsAscending);

    return periods;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Teacher Attendance'),
            if (_appVersionLabel != null)
              Text(
                _appVersionLabel!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w500,
                    ),
              ),
          ],
        ),
      ),
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
                      yearOptions: _yearOptions,
                      selectedYear: _selectedNewTeacherYear,
                      onYearChanged: (year) {
                        setState(() {
                          _selectedNewTeacherYear = year;
                        });
                      },
                      selectedTerm: _selectedNewTeacherTerm,
                      onTermChanged: (term) {
                        setState(() {
                          _selectedNewTeacherTerm = term;
                        });
                      },
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
                            onLogMorningToday: (status) => _logToday(
                              index,
                              AttendanceSession.morning,
                              status,
                            ),
                            onLogAfternoonToday: (status) => _logToday(
                              index,
                              AttendanceSession.afternoon,
                              status,
                            ),
                            periodOptions: _periodOptions,
                            onChangePeriod: (period) => _changeTeacherPeriod(
                              index,
                              period,
                            ),
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
                    ...(_summaryPeriods.isEmpty
                            ? <AttendancePeriod>[
                                AttendancePeriod(
                                  year: _selectedNewTeacherYear,
                                  term: _selectedNewTeacherTerm,
                                ),
                              ]
                            : _summaryPeriods)
                        .map(
                      (period) => _TermSummarySection(
                        period: period,
                        teachers: _teachers,
                        onTapTeacher: _scrollToTeacherCard,
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

class _TermSummarySection extends StatelessWidget {
  const _TermSummarySection({
    required this.period,
    required this.teachers,
    required this.onTapTeacher,
  });

  final AttendancePeriod period;
  final List<TeacherRecord> teachers;
  final ValueChanged<int> onTapTeacher;

  @override
  Widget build(BuildContext context) {
    final matchingTeachers = <({int index, TeacherRecord teacher})>[];

    for (var index = 0; index < teachers.length; index += 1) {
      final teacher = teachers[index];
      if (teacher.shouldShowInPeriodSummary(period.year, period.term)) {
        matchingTeachers.add((index: index, teacher: teacher));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period.summaryLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (teachers.isEmpty || matchingTeachers.isEmpty)
          const SummaryPlaceholder()
        else
          ...matchingTeachers.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TermSummaryTile(
                teacher: item.teacher,
                period: period,
                onTapTeacher: () => onTapTeacher(item.index),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

int _comparePeriodsAscending(AttendancePeriod left, AttendancePeriod right) {
  final yearCompare = left.year.compareTo(right.year);
  if (yearCompare != 0) {
    return yearCompare;
  }

  return left.term.sortOrder.compareTo(right.term.sortOrder);
}
