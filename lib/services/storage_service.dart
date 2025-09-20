import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/models/attendance.dart';
import 'package:attendence_tracker/models/timetable.dart';


class StorageService {
  static const String _subjectsKey = 'subjects';
  static const String _attendanceKey = 'attendance_records';
  static const String _timetablesKey = 'timetables';
  static const String _settingsKey = 'app_settings';
  static const String _backupKey = 'data_backup';
  static const String _lastBackupKey = 'last_backup_date';
  static const String _dataVersionKey = 'data_version';
  static const String _initializationKey = 'app_initialized';

  static const int _currentDataVersion = 1;
  static const int _backupIntervalHours = 24; // Backup every 24 hours

  static SharedPreferences? _prefs;

  // Initialize the storage service with enhanced data persistence
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();

    // Mark as initialized to prevent data loss
    await prefs.setBool(_initializationKey, true);

    // Check if this is first run or data recovery needed
    await _ensureDataIntegrity();

    // Perform automatic backup
    await _performAutomaticBackup();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception(
        'StorageService not initialized. Call StorageService.init() first.',
      );
    }
    return _prefs!;
  }

  // Ensure data integrity and recover if needed
  static Future<void> _ensureDataIntegrity() async {
    try {
      // Check data version for migrations
      final currentVersion = prefs.getInt(_dataVersionKey) ?? 0;
      if (currentVersion < _currentDataVersion) {
        await _migrateData(currentVersion, _currentDataVersion);
        await prefs.setInt(_dataVersionKey, _currentDataVersion);
      }

      // Validate critical data exists and is accessible
      await _validateCriticalData();
    } catch (e) {
      // If validation fails, attempt recovery from backup
      await _attemptDataRecovery();
    }
  }

  // Validate that critical data structures are intact
  static Future<void> _validateCriticalData() async {
    try {
      // Test reading each data type to ensure they're not corrupted
      await getSubjects();
      await getAttendanceRecords();
      await getTimetables();
      await getSettings();
    } catch (e) {
      throw Exception('Data validation failed: $e');
    }
  }

  // Attempt to recover data from backup
  static Future<void> _attemptDataRecovery() async {
    try {
      final backupData = prefs.getString(_backupKey);
      if (backupData != null) {
        final success = await importData(backupData);
        if (success) {
          print('Data recovered from backup successfully');
        } else {
          await _initializeDefaultData();
        }
      } else {
        await _initializeDefaultData();
      }
    } catch (e) {
      await _initializeDefaultData();
    }
  }

  // Initialize default data structure
  static Future<void> _initializeDefaultData() async {
    await saveSubjects([]);
    await saveAttendanceRecords([]);
    await saveTimetables([]);
    await saveSettings(_getDefaultSettings());
    print('Initialized with default data structure');
  }

  // Perform automatic backup
  static Future<void> _performAutomaticBackup() async {
    try {
      final lastBackupStr = prefs.getString(_lastBackupKey);
      final now = DateTime.now();

      bool shouldBackup = true;
      if (lastBackupStr != null) {
        final lastBackup = DateTime.parse(lastBackupStr);
        final hoursSinceBackup = now.difference(lastBackup).inHours;
        shouldBackup = hoursSinceBackup >= _backupIntervalHours;
      }

      if (shouldBackup) {
        final backupData = await exportData();
        await prefs.setString(_backupKey, backupData);
        await prefs.setString(_lastBackupKey, now.toIso8601String());
        print('Automatic backup completed');
      }
    } catch (e) {
      // Backup failed, but don't crash the app
      print('Automatic backup failed: $e');
    }
  }

  // Data migration for future versions
  static Future<void> _migrateData(int fromVersion, int toVersion) async {
    print('Migrating data from version $fromVersion to $toVersion');
    // Placeholder for future data migrations
    // This will be used when we need to update data structures
  }

  // Enhanced data persistence - Force save with backup
  static Future<void> _saveWithBackup(String key, dynamic value) async {
    try {
      if (value is List<String>) {
        await prefs.setStringList(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      }

      // Trigger backup after important data changes
      if (key == _subjectsKey ||
          key == _attendanceKey ||
          key == _timetablesKey) {
        _performAutomaticBackup(); // Don't await to avoid blocking
      }
    } catch (e) {
      print('Error saving data: $e');
      // Try to recover and retry once
      await _attemptDataRecovery();
      if (value is List<String>) {
        await prefs.setStringList(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    }
  }

  // Subject operations
  static Future<List<Subject>> getSubjects() async {
    final subjectsJson = prefs.getStringList(_subjectsKey) ?? [];
    return subjectsJson
        .map((json) => Subject.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveSubjects(List<Subject> subjects) async {
    final subjectsJson = subjects
        .map((subject) => jsonEncode(subject.toJson()))
        .toList();
    await _saveWithBackup(_subjectsKey, subjectsJson);
    // Update cache and notify screens would happen here if NavigationService existed
  }

  static Future<void> addSubject(Subject subject) async {
    final subjects = await getSubjects();
    subjects.add(subject);
    await saveSubjects(subjects);
    // Notify all relevant screens to refresh would happen here
  }

  static Future<void> updateSubject(Subject updatedSubject) async {
    final subjects = await getSubjects();
    final index = subjects.indexWhere((s) => s.id == updatedSubject.id);
    if (index != -1) {
      subjects[index] = updatedSubject;
      await saveSubjects(subjects);
    // Notify all screens to refresh as subject changes affect many screens would happen here
    }
  }

  static Future<void> deleteSubject(String subjectId) async {
    final subjects = await getSubjects();
    subjects.removeWhere((s) => s.id == subjectId);
    await saveSubjects(subjects);

    // Also delete related attendance records
    final attendance = await getAttendanceRecords();
    attendance.removeWhere((a) => a.subjectId == subjectId);
    await saveAttendanceRecords(attendance);

    // Notify all screens to refresh as deleting subjects affects timetables and attendance
  }

  static Future<Subject?> getSubjectById(String id) async {
    final subjects = await getSubjects();
    try {
      return subjects.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  // Attendance operations
  static Future<List<AttendanceRecord>> getAttendanceRecords() async {
    final attendanceJson = prefs.getStringList(_attendanceKey) ?? [];
    return attendanceJson
        .map((json) => AttendanceRecord.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveAttendanceRecords(
    List<AttendanceRecord> records,
  ) async {
    final recordsJson = records
        .map((record) => jsonEncode(record.toJson()))
        .toList();
    await _saveWithBackup(_attendanceKey, recordsJson);
    // Update cache and notify screens would happen here if NavigationService existed
  }

  static Future<void> addAttendanceRecord(AttendanceRecord record) async {
    final records = await getAttendanceRecords();
    records.add(record);
    await saveAttendanceRecords(records);
    // Notify attendance and schedule screens would happen here
  }

  static Future<void> updateAttendanceRecord(
    AttendanceRecord updatedRecord,
  ) async {
    final records = await getAttendanceRecords();
    final index = records.indexWhere((r) => r.id == updatedRecord.id);
    if (index != -1) {
      records[index] = updatedRecord;
      await saveAttendanceRecords(records);
      // Notify all relevant screens would happen here
    }
  }

  static Future<void> deleteAttendanceRecord(String recordId) async {
    final records = await getAttendanceRecords();
    records.removeWhere((r) => r.id == recordId);
    await saveAttendanceRecords(records);
  }

  static Future<List<AttendanceRecord>> getAttendanceForDate(
    DateTime date,
  ) async {
    final records = await getAttendanceRecords();
    return records
        .where(
          (r) =>
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day,
        )
        .toList();
  }

  static Future<List<AttendanceRecord>> getAttendanceForSubject(
    String subjectId,
  ) async {
    final records = await getAttendanceRecords();
    return records.where((r) => r.subjectId == subjectId).toList();
  }

  static Future<List<AttendanceRecord>> getAttendanceForMonth(
    int year,
    int month,
  ) async {
    final records = await getAttendanceRecords();
    return records
        .where((r) => r.date.year == year && r.date.month == month)
        .toList();
  }

  static Future<List<AttendanceRecord>> getAttendanceForSubjectInMonth(
    String subjectId,
    int year,
    int month,
  ) async {
    final records = await getAttendanceRecords();
    return records
        .where(
          (r) =>
              r.subjectId == subjectId &&
              r.date.year == year &&
              r.date.month == month,
        )
        .toList();
  }

  // Timetable operations
  static Future<List<Timetable>> getTimetables() async {
    final timetablesJson = prefs.getStringList(_timetablesKey) ?? [];
    return timetablesJson
        .map((json) => Timetable.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveTimetables(List<Timetable> timetables) async {
    final timetablesJson = timetables
        .map((timetable) => jsonEncode(timetable.toJson()))
        .toList();
    await _saveWithBackup(_timetablesKey, timetablesJson);
    // Update cache and notify screens would happen here if NavigationService existed
  }

  static Future<void> addTimetable(Timetable timetable) async {
    final timetables = await getTimetables();
    timetables.add(timetable);
    await saveTimetables(timetables);
    // Notify relevant screens would happen here
  }

  static Future<void> updateTimetable(Timetable updatedTimetable) async {
    final timetables = await getTimetables();
    final index = timetables.indexWhere((t) => t.id == updatedTimetable.id);
    if (index != -1) {
      timetables[index] = updatedTimetable;
      await saveTimetables(timetables);
      // Notify all relevant screens as timetable changes affect schedule
    }
  }

  static Future<void> deleteTimetable(String timetableId) async {
    final timetables = await getTimetables();
    timetables.removeWhere((t) => t.id == timetableId);
    await saveTimetables(timetables);
    // Notify all screens as deleting timetables affects many screens
  }

  static Future<Timetable?> getActiveTimetable() async {
    final timetables = await getTimetables();
    try {
      return timetables.firstWhere((t) => t.isActive);
    } catch (e) {
      return null;
    }
  }

  static Future<void> setActiveTimetable(String timetableId) async {
    final timetables = await getTimetables();
    for (int i = 0; i < timetables.length; i++) {
      timetables[i] = timetables[i].copyWith(
        isActive: timetables[i].id == timetableId,
      );
    }
    await saveTimetables(timetables);
    // Notify schedule screen as active timetable change affects daily schedule
  }

  // Settings operations
  static Future<Map<String, dynamic>> getSettings() async {
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson == null) {
      return _getDefaultSettings();
    }
    return jsonDecode(settingsJson);
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _saveWithBackup(_settingsKey, jsonEncode(settings));
  }

  static Future<void> updateSetting(String key, dynamic value) async {
    final settings = await getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  static Future<T?> getSetting<T>(String key) async {
    final settings = await getSettings();
    return settings[key] as T?;
  }

  // Theme settings
  static Future<bool> isDarkMode() async {
    return await getSetting<bool>('isDarkMode') ?? false;
  }

  static Future<void> setDarkMode(bool isDark) async {
    await updateSetting('isDarkMode', isDark);
  }

  static Map<String, dynamic> _getDefaultSettings() {
    return {
      'isDarkMode': false,
      'notificationsEnabled': true,
      'autoMarkAttendance': false,
      'defaultAttendanceStatus': 'free',
      'weekStartsOn': 'monday',
      'timeFormat': '24h',
      'appVersion': '1.0.0',
    };
  }

  // Utility methods
  static Future<void> clearAllData() async {
    // Create a backup before clearing
    await _performAutomaticBackup();
    await prefs.clear();
    // Reinitialize after clearing
    await _initializeDefaultData();
  }

  // Manual backup method
  static Future<bool> createManualBackup() async {
    try {
      await _performAutomaticBackup();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if data exists (for onboarding)
  static Future<bool> hasExistingData() async {
    final subjects = await getSubjects();
    final timetables = await getTimetables();
    return subjects.isNotEmpty || timetables.isNotEmpty;
  }

  // Get storage usage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    final subjects = await getSubjects();
    final attendance = await getAttendanceRecords();
    final timetables = await getTimetables();
    final lastBackup = prefs.getString(_lastBackupKey);

    return {
      'subjects_count': subjects.length,
      'attendance_records_count': attendance.length,
      'timetables_count': timetables.length,
      'last_backup': lastBackup,
      'data_version': prefs.getInt(_dataVersionKey) ?? 0,
      'has_backup': prefs.getString(_backupKey) != null,
    };
  }

  static Future<String> exportData() async {
    final subjects = await getSubjects();
    final attendance = await getAttendanceRecords();
    final timetables = await getTimetables();
    final settings = await getSettings();

    final exportData = {
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'attendance': attendance.map((a) => a.toJson()).toList(),
      'timetables': timetables.map((t) => t.toJson()).toList(),
      'settings': settings,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };

    // Return JSON string for export
    // In a real app, you might want to save this to a file or share it
    return jsonEncode(exportData);
  }

  static Future<bool> importData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);

      // Import subjects
      if (data['subjects'] != null) {
        final subjects = (data['subjects'] as List)
            .map((json) => Subject.fromJson(json))
            .toList();
        await saveSubjects(subjects);
      }

      // Import attendance
      if (data['attendance'] != null) {
        final attendance = (data['attendance'] as List)
            .map((json) => AttendanceRecord.fromJson(json))
            .toList();
        await saveAttendanceRecords(attendance);
      }

      // Import timetables
      if (data['timetables'] != null) {
        final timetables = (data['timetables'] as List)
            .map((json) => Timetable.fromJson(json))
            .toList();
        await saveTimetables(timetables);
      }

      // Import settings
      if (data['settings'] != null) {
        await saveSettings(data['settings']);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
