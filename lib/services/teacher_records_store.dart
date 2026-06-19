import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/teacher_record.dart';

abstract class TeacherRecordsStore {
  Future<List<TeacherRecord>> loadTeachers();
  Future<void> saveTeachers(List<TeacherRecord> teachers);
}

class SharedPreferencesTeacherRecordsStore implements TeacherRecordsStore {
  SharedPreferencesTeacherRecordsStore({
    this.storageKey = 'teacher_records',
  });

  final String storageKey;

  @override
  Future<List<TeacherRecord>> loadTeachers() async {
    final preferences = await SharedPreferences.getInstance();
    final rawRecords = preferences.getStringList(storageKey) ?? <String>[];
    return rawRecords
        .map(
          (entry) => TeacherRecord.fromJson(
            jsonDecode(entry) as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveTeachers(List<TeacherRecord> teachers) async {
    final preferences = await SharedPreferences.getInstance();
    final rawRecords = teachers
        .map((teacher) => jsonEncode(teacher.toJson()))
        .toList(growable: false);
    await preferences.setStringList(storageKey, rawRecords);
  }
}
