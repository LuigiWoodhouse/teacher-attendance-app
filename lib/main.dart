import 'package:flutter/material.dart';

import 'app/teacher_attendance_app.dart';
import 'services/teacher_backup_service.dart';
import 'services/teacher_records_store.dart';

void main() {
  runApp(
    TeacherAttendanceApp(
      recordsStore: SharedPreferencesTeacherRecordsStore(),
      backupService: ExcelTeacherBackupService(),
    ),
  );
}
