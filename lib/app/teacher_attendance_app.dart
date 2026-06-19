import 'package:flutter/material.dart';

import 'attendance_home_page.dart';
import '../services/teacher_backup_service.dart';
import '../services/teacher_records_store.dart';

class TeacherAttendanceApp extends StatelessWidget {
  const TeacherAttendanceApp({
    super.key,
    required this.recordsStore,
    required this.backupService,
  });

  final TeacherRecordsStore recordsStore;
  final TeacherBackupService backupService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C7C54)),
        scaffoldBackgroundColor: const Color(0xFFF5F7F9),
        useMaterial3: true,
      ),
      home: AttendanceHomePage(
        recordsStore: recordsStore,
        backupService: backupService,
      ),
    );
  }
}
