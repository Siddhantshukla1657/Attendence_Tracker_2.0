import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/models/attendance.dart';
import 'package:attendence_tracker/models/timetable.dart';
import 'package:attendence_tracker/services/backend_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class StorageService {
  static const String _subjectsKey = 'subjects';
  static const String _attendanceKey = 'attendance_records';
  static const String _timetablesKey = 'timetables';
  static const String _settingsKey = 'app_settings';
  static const String _backupKey = 'data_backup';
  static const String _lastBackupKey = 'last_backup_date';
  static const String _dataVersionKey = 'data_version';
  static const String _initializationKey = 'app_initialized';
  static const String _lastSyncKey = 'last_sync_time';

  static const int _currentDataVersion = 1;
  static const int _backupIntervalHours = 24; // Backup every 24 hours
  static const int _autoSyncIntervalMinutes = 5; // Auto sync every 5 minutes

  static SharedPreferences? _prefs;
  static final BackendService _backendService = BackendService();
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  // Initialize the storage service with enhanced data persistence
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();

    // Mark as initialized to prevent data loss
    await prefs.setBool(_initializationKey, true);

    // Check if this is first run or data recovery needed
    await _ensureDataIntegrity();

    // Set up automatic sync when connectivity changes
    await _setupConnectivityListener();

    // Perform automatic backup after sync
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

  // Method to perform background sync after app initialization
  static Future<void> performBackgroundSync() async {
    try {
      // Only attempt sync if user is authenticated
      if (_backendService.isAuthenticated) {
        print('Performing background sync with backend...');

        // Get data from local storage first (this is our primary source now)
        final localSubjects = await getSubjects();
        final localAttendance = await getAttendanceRecords();
        final localTimetables = await getTimetables();
        bool hasLocalData =
            localSubjects.isNotEmpty ||
            localAttendance.isNotEmpty ||
            localTimetables.isNotEmpty;

        // Always prioritize local data - only fetch from backend if local is empty
        if (!hasLocalData) {
          print('No local data found, checking backend...');
          final hasBackendData = await _backendService.hasAnyData();

          if (hasBackendData) {
            print('Found data in backend, fetching...');
            // Get data from backend
            final backendSubjects = await _backendService.getSubjects();
            final backendAttendance = await _backendService
                .getAttendanceRecords();
            final backendTimetables = await _backendService.getTimetables();

            // Update local storage with backend data only if we don't have local data
            await saveSubjects(backendSubjects);
            await saveAttendanceRecords(backendAttendance);
            await saveTimetables(backendTimetables);

            print(
              'Local storage updated with backend data: '
              '${backendSubjects.length} subjects, '
              '${backendAttendance.length} attendance records, '
              '${backendTimetables.length} timetables',
            );
          } else {
            print('No data found in either backend or local storage');
          }
        } else {
          print('Local data found, syncing to backend if needed...');
          // If we have local data, sync it to backend (local is our source of truth)
          await _backendService.syncLocalDataWithBackend(
            subjects: localSubjects,
            attendanceRecords: localAttendance,
            timetables: localTimetables,
          );
        }
      } else {
        print('User not authenticated, using local storage only');
      }
    } catch (e) {
      print('Background sync failed: $e');
      // Continue with local data if sync fails - local storage is our priority
      print('Continuing with local storage data');
    }
  }

  // Set up connectivity listener for automatic sync
  static Future<void> _setupConnectivityListener() async {
    try {
      // Listen for connectivity changes
      _connectivitySubscription?.cancel();
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
        List<ConnectivityResult> result,
      ) async {
        // Check if we have internet connectivity
        if (result.any((r) => r != ConnectivityResult.none)) {
          // Internet is available, attempt to sync
          print('Internet connection detected, attempting auto sync...');
          await _attemptAutoSync();
        }
      });

      // Check current connectivity status
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Internet is available, attempt to sync
        print('Internet available on app start, scheduling auto sync...');
        // Schedule sync to happen after app initialization
        Future.delayed(const Duration(seconds: 2), () async {
          await _attemptAutoSync();
        });
      }
    } catch (e) {
      print('Error setting up connectivity listener: $e');
    }
  }

  // Attempt automatic sync based on time interval
  static Future<void> _attemptAutoSync() async {
    try {
      if (!_backendService.isAuthenticated) {
        print('User not authenticated, skipping auto sync');
        return;
      }

      final lastSyncStr = prefs.getString(_lastSyncKey);
      final now = DateTime.now();

      bool shouldSync = true;
      if (lastSyncStr != null) {
        final lastSync = DateTime.parse(lastSyncStr);
        final minutesSinceSync = now.difference(lastSync).inMinutes;
        shouldSync = minutesSinceSync >= _autoSyncIntervalMinutes;
      }

      if (shouldSync) {
        print('Performing automatic sync...');
        await syncWithBackend(bidirectional: true);
        await prefs.setString(_lastSyncKey, now.toIso8601String());
        print('Automatic sync completed');
      }
    } catch (e) {
      print('Automatic sync failed: $e');
    }
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

  // Force sync with backend - improved version that prioritizes local data
  static Future<void> forceSyncWithBackend() async {
    try {
      // Only attempt sync if user is authenticated
      if (_backendService.isAuthenticated) {
        print('Forcing sync with backend...');

        // Always prioritize local data as the source of truth
        final localSubjects = await getSubjects();
        final localAttendance = await getAttendanceRecords();
        final localTimetables = await getTimetables();

        print(
          'Local data: ${localSubjects.length} subjects, '
          '${localAttendance.length} attendance records, '
          '${localTimetables.length} timetables',
        );

        // Sync local data to backend (local is our source of truth)
        await _backendService.syncLocalDataWithBackend(
          subjects: localSubjects,
          attendanceRecords: localAttendance,
          timetables: localTimetables,
        );

        print('Local storage synced to backend successfully');
      } else {
        print('User not authenticated, skipping backend sync');
      }
    } catch (e) {
      print('Backend sync failed: $e');
      // Continue with local data if sync fails - local storage is our priority
      print('Continuing with local storage data');
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
    // Also save to backend if user is authenticated
    if (_backendService.isAuthenticated) {
      try {
        await _backendService.addSubject(subject);
      } catch (e) {
        print('Failed to add subject to backend: $e');
        // Continue with local storage even if backend fails
      }
    }
    // Notify all relevant screens to refresh would happen here if NavigationService existed
  }

  static Future<void> updateSubject(Subject updatedSubject) async {
    final subjects = await getSubjects();
    final index = subjects.indexWhere((s) => s.id == updatedSubject.id);
    if (index != -1) {
      subjects[index] = updatedSubject;
      await saveSubjects(subjects);
      // Also update backend if user is authenticated
      if (_backendService.isAuthenticated) {
        try {
          await _backendService.updateSubject(updatedSubject);
        } catch (e) {
          print('Failed to update subject in backend: $e');
          // Continue with local storage even if backend fails
        }
      }
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

    // Also delete from backend if user is authenticated
    if (_backendService.isAuthenticated) {
      try {
        await _backendService.deleteSubject(subjectId);
      } catch (e) {
        print('Failed to delete subject from backend: $e');
        // Continue with local storage even if backend fails
      }
    }

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
    // Also save to backend if user is authenticated
    if (_backendService.isAuthenticated) {
      try {
        await _backendService.addAttendanceRecord(record);
      } catch (e) {
        print('Failed to add attendance record to backend: $e');
        // Continue with local storage even if backend fails
      }
    }
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
      // Also update backend if user is authenticated
      if (_backendService.isAuthenticated) {
        try {
          await _backendService.updateAttendanceRecord(updatedRecord);
        } catch (e) {
          print('Failed to update attendance record in backend: $e');
          // Continue with local storage even if backend fails
        }
      }
      // Notify all relevant screens would happen here
    }
  }

  static Future<void> deleteAttendanceRecord(String recordId) async {
    final records = await getAttendanceRecords();
    records.removeWhere((r) => r.id == recordId);
    await saveAttendanceRecords(records);
    // Also delete from backend if user is authenticated
    if (_backendService.isAuthenticated) {
      try {
        await _backendService.deleteAttendanceRecord(recordId);
      } catch (e) {
        print('Failed to delete attendance record from backend: $e');
        // Continue with local storage even if backend fails
      }
    }
  }

  static Future<List<AttendanceRecord>> getAttendanceForDate(
    DateTime date,
  ) async {
    final records = await getAttendanceRecords();
    final dateRecords = records
        .where(
          (r) =>
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day,
        )
        .toList();

    // Remove duplicates based on date, time, and subject
    final uniqueRecords = <AttendanceRecord>[];
    final seen = <String>{};

    for (final record in dateRecords) {
      final key =
          '${record.date.year}-${record.date.month}-${record.date.day}_${record.startTime.hour}:${record.startTime.minute}_${record.subjectId}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueRecords.add(record);
      } else {
        // Log duplicate found and remove it
        print(
          'StorageService: Found duplicate attendance record: ${record.id}',
        );
        await deleteAttendanceRecord(record.id);
      }
    }

    return uniqueRecords;
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
    // Also save to backend if user is authenticated
    if (_backendService.isAuthenticated) {
      try {
        await _backendService.addTimetable(timetable);
      } catch (e) {
        print('Failed to add timetable to backend: $e');
        // Continue with local storage even if backend fails
      }
    }
    // Notify relevant screens would happen here
  }

  static Future<void> updateTimetable(Timetable updatedTimetable) async {
    final timetables = await getTimetables();
    final index = timetables.indexWhere((t) => t.id == updatedTimetable.id);
    if (index != -1) {
      timetables[index] = updatedTimetable;
      await saveTimetables(timetables);
      // Also update backend if user is authenticated
      if (_backendService.isAuthenticated) {
        try {
          await _backendService.updateTimetable(updatedTimetable);
        } catch (e) {
          print('Failed to update timetable in backend: $e');
          // Continue with local storage even if backend fails
        }
      }
      // Notify all relevant screens as timetable changes affect schedule
    }
  }

  static Future<void> deleteTimetable(String timetableId) async {
    final timetables = await getTimetables();
    timetables.removeWhere((t) => t.id == timetableId);
    await saveTimetables(timetables);
    // Also delete from backend if user is authenticated
    if (_backendService.isAuthenticated) {
      try {
        await _backendService.deleteTimetable(timetableId);
      } catch (e) {
        print('Failed to delete timetable from backend: $e');
        // Continue with local storage even if backend fails
      }
    }
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

  // Clean up duplicate attendance records
  static Future<int> cleanupDuplicateAttendanceRecords() async {
    final allRecords = await getAttendanceRecords();
    final uniqueRecords = <AttendanceRecord>[];
    final seen = <String>{};
    int duplicatesRemoved = 0;

    for (final record in allRecords) {
      final key =
          '${record.date.year}-${record.date.month}-${record.date.day}_${record.startTime.hour}:${record.startTime.minute}_${record.subjectId}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueRecords.add(record);
      } else {
        duplicatesRemoved++;
        print(
          'StorageService: Removing duplicate attendance record: ${record.id}',
        );
      }
    }

    if (duplicatesRemoved > 0) {
      await saveAttendanceRecords(uniqueRecords);
      print(
        'StorageService: Cleaned up $duplicatesRemoved duplicate attendance records',
      );
    }

    return duplicatesRemoved;
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

  // Manual sync method that can be called from UI - enhanced version
  static Future<void> syncWithBackend({bool bidirectional = false}) async {
    if (!_backendService.isAuthenticated) {
      print('Cannot sync - user not authenticated');
      return;
    }

    try {
      print('Manual sync initiated...');

      // Get local data (always our source of truth)
      final localSubjects = await getSubjects();
      final localAttendance = await getAttendanceRecords();
      final localTimetables = await getTimetables();

      if (bidirectional) {
        print('Bidirectional sync requested, but prioritizing local data...');
        // Even with bidirectional sync, we prioritize local data
        // We still fetch from backend but don't overwrite local data
        try {
          final backendSubjects = await _backendService.getSubjects();
          final backendAttendance = await _backendService
              .getAttendanceRecords();
          final backendTimetables = await _backendService.getTimetables();

          print(
            'Backend data: ${backendSubjects.length} subjects, '
            '${backendAttendance.length} attendance records, '
            '${backendTimetables.length} timetables',
          );

          // Merge backend data with local data (local takes precedence)
          // This ensures no data loss from either source
          final mergedSubjects = _mergeSubjectLists(
            localSubjects,
            backendSubjects,
          );
          final mergedAttendance = _mergeAttendanceLists(
            localAttendance,
            backendAttendance,
          );
          final mergedTimetables = _mergeTimetableLists(
            localTimetables,
            backendTimetables,
          );

          // Save merged data to local storage (local still takes precedence)
          await saveSubjects(mergedSubjects);
          await saveAttendanceRecords(mergedAttendance);
          await saveTimetables(mergedTimetables);

          print('Data merged successfully, local data takes precedence');
        } catch (e) {
          print('Error during bidirectional fetch: $e');
          // Continue with local data only
        }
      }

      // Sync local data with backend (local is our source of truth)
      await _backendService.syncLocalDataWithBackend(
        subjects: localSubjects,
        attendanceRecords: localAttendance,
        timetables: localTimetables,
      );

      // Update last sync time
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      print('Manual sync completed successfully with local data priority');
    } catch (e) {
      print('Manual sync failed: $e');
      // Don't rethrow - continue with local data
      print('Continuing with local storage data');
    }
  }

  // Helper method to merge subject lists, prioritizing local data
  static List<Subject> _mergeSubjectLists(
    List<Subject> localSubjects,
    List<Subject> backendSubjects,
  ) {
    final localSubjectMap = {for (var s in localSubjects) s.id: s};
    final backendSubjectMap = {for (var s in backendSubjects) s.id: s};

    // Start with all local subjects
    final mergedMap = Map<String, Subject>.from(localSubjectMap);

    // Add backend subjects that don't exist locally
    for (final entry in backendSubjectMap.entries) {
      if (!mergedMap.containsKey(entry.key)) {
        mergedMap[entry.key] = entry.value;
      }
    }

    return mergedMap.values.toList();
  }

  // Helper method to merge attendance lists, prioritizing local data
  static List<AttendanceRecord> _mergeAttendanceLists(
    List<AttendanceRecord> localAttendance,
    List<AttendanceRecord> backendAttendance,
  ) {
    final localAttendanceMap = {for (var a in localAttendance) a.id: a};
    final backendAttendanceMap = {for (var a in backendAttendance) a.id: a};

    // Start with all local attendance records
    final mergedMap = Map<String, AttendanceRecord>.from(localAttendanceMap);

    // Add backend records that don't exist locally
    for (final entry in backendAttendanceMap.entries) {
      if (!mergedMap.containsKey(entry.key)) {
        mergedMap[entry.key] = entry.value;
      }
    }

    return mergedMap.values.toList();
  }

  // Helper method to merge timetable lists, prioritizing local data
  static List<Timetable> _mergeTimetableLists(
    List<Timetable> localTimetables,
    List<Timetable> backendTimetables,
  ) {
    final localTimetableMap = {for (var t in localTimetables) t.id: t};
    final backendTimetableMap = {for (var t in backendTimetables) t.id: t};

    // Start with all local timetables
    final mergedMap = Map<String, Timetable>.from(localTimetableMap);

    // Add backend timetables that don't exist locally
    for (final entry in backendTimetableMap.entries) {
      if (!mergedMap.containsKey(entry.key)) {
        mergedMap[entry.key] = entry.value;
      }
    }

    return mergedMap.values.toList();
  }

  // Force fetch from backend and update local storage
  static Future<void> forceFetchFromBackend() async {
    if (!_backendService.isAuthenticated) {
      print('Cannot fetch - user not authenticated');
      return;
    }

    try {
      print('Force fetching data from backend...');

      // Get current local data as backup
      final currentLocalSubjects = await getSubjects();
      final currentLocalAttendance = await getAttendanceRecords();
      final currentLocalTimetables = await getTimetables();

      // Get data from backend
      final backendSubjects = await _backendService.getSubjects();
      final backendAttendance = await _backendService.getAttendanceRecords();
      final backendTimetables = await _backendService.getTimetables();

      // Only update local storage if we got data from backend
      // Otherwise, keep local data intact
      if (backendSubjects.isNotEmpty ||
          backendAttendance.isNotEmpty ||
          backendTimetables.isNotEmpty) {
        // Merge backend data with local data (local takes precedence for conflicts)
        final mergedSubjects = _mergeSubjectLists(
          currentLocalSubjects,
          backendSubjects,
        );
        final mergedAttendance = _mergeAttendanceLists(
          currentLocalAttendance,
          backendAttendance,
        );
        final mergedTimetables = _mergeTimetableLists(
          currentLocalTimetables,
          backendTimetables,
        );

        // Update local storage with merged data
        await saveSubjects(mergedSubjects);
        await saveAttendanceRecords(mergedAttendance);
        await saveTimetables(mergedTimetables);

        // Update last sync time
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

        print(
          'Force fetch completed with merge: '
          '${mergedSubjects.length} subjects, '
          '${mergedAttendance.length} attendance records, '
          '${mergedTimetables.length} timetables',
        );
      } else {
        print('No data fetched from backend, keeping local data intact');
      }
    } catch (e) {
      print('Force fetch failed: $e');
      // Don't rethrow - continue with local data
      print('Continuing with existing local storage data');
    }
  }

  // Dispose method to clean up resources
  static Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
