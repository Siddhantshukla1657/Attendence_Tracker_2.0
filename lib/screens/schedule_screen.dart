import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:attendence_tracker/models/timetable.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/models/attendance.dart';
import 'package:attendence_tracker/services/storage_service.dart';
import 'package:attendence_tracker/theme/app_theme.dart';
import 'package:attendence_tracker/widgets/schedule_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  List<TimeSlot> _todaySchedule = [];
  List<Subject> _subjects = [];
  List<AttendanceRecord> _todayAttendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('ScheduleScreen: initState called');
    _loadScheduleData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('ScheduleScreen: didChangeDependencies called');
    // Reload data when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('ScheduleScreen: Post frame callback - reloading schedule');
        _loadScheduleData();
      }
    });
  }

  @override
  void didUpdateWidget(ScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('ScheduleScreen: didUpdateWidget called');
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    setState(() => _isLoading = true);

    try {
      // Load subjects
      _subjects = await StorageService.getSubjects();
      print('ScheduleScreen: Loaded ${_subjects.length} subjects');

      // Load active timetable
      final activeTimetable = await StorageService.getActiveTimetable();
      if (activeTimetable != null) {
        final dayOfWeek = DayOfWeekExtension.fromDateTime(_selectedDate);
        _todaySchedule = activeTimetable.getScheduleForDay(dayOfWeek);
        print(
          'ScheduleScreen: Found ${_todaySchedule.length} time slots for ${dayOfWeek.name}',
        );
      } else {
        _todaySchedule = [];
        print('ScheduleScreen: No active timetable found');
      }

      // Load today's attendance records
      _todayAttendance = await StorageService.getAttendanceForDate(
        _selectedDate,
      );
      print(
        'ScheduleScreen: Loaded ${_todayAttendance.length} attendance records',
      );

      // Clean up any duplicate records
      final duplicatesRemoved =
          await StorageService.cleanupDuplicateAttendanceRecords();
      if (duplicatesRemoved > 0) {
        print(
          'ScheduleScreen: Cleaned up $duplicatesRemoved duplicate records',
        );
        // Reload attendance records after cleanup
        _todayAttendance = await StorageService.getAttendanceForDate(
          _selectedDate,
        );
      }

      // If no attendance records exist for today, create them from schedule
      if (_todayAttendance.isEmpty && _todaySchedule.isNotEmpty) {
        print('ScheduleScreen: Creating attendance records from schedule');
        await _createTodayAttendanceRecords();
      } else if (_todaySchedule.isNotEmpty) {
        // Check if we have attendance records for all scheduled slots
        print(
          'ScheduleScreen: Checking for missing attendance records. Slots: ${_todaySchedule.length}, Records: ${_todayAttendance.length}',
        );
        final missingRecords = <TimeSlot>[];
        for (final slot in _todaySchedule) {
          if (slot.subjectId != null) {
            final hasRecord = _todayAttendance.any(
              (record) =>
                  record.subjectId == slot.subjectId &&
                  record.date.year == _selectedDate.year &&
                  record.date.month == _selectedDate.month &&
                  record.date.day == _selectedDate.day &&
                  record.startTime.hour == slot.startTime.hour &&
                  record.startTime.minute == slot.startTime.minute,
            );
            print(
              'ScheduleScreen: Slot ${slot.subjectId} (${slot.startTime.hour}:${slot.startTime.minute}) has record: $hasRecord',
            );
            if (!hasRecord) {
              missingRecords.add(slot);
            }
          }
        }

        if (missingRecords.isNotEmpty) {
          print(
            'ScheduleScreen: Creating ${missingRecords.length} missing attendance records',
          );
          await _createAttendanceRecordsForSlots(missingRecords);
        } else {
          print('ScheduleScreen: No missing attendance records found');
        }
      }
    } catch (e) {
      print('ScheduleScreen: Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading schedule: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createTodayAttendanceRecords() async {
    final newRecords = <AttendanceRecord>[];

    for (final slot in _todaySchedule) {
      if (slot.subjectId != null) {
        final subject = _getSubjectById(slot.subjectId!);
        print(
          'ScheduleScreen: Creating attendance record for ${subject?.name} (${subject?.type}) - Duration: ${subject?.duration}',
        );

        // Create unique ID using date, time, and subject to prevent duplicates
        final uniqueId =
            '${_selectedDate.year}${_selectedDate.month.toString().padLeft(2, '0')}${_selectedDate.day.toString().padLeft(2, '0')}_${slot.startTime.hour.toString().padLeft(2, '0')}${slot.startTime.minute.toString().padLeft(2, '0')}_${slot.subjectId}';

        final record = AttendanceRecord(
          id: uniqueId,
          subjectId: slot.subjectId!,
          date: _selectedDate,
          startTime: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            slot.startTime.hour,
            slot.startTime.minute,
          ),
          endTime: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            slot.endTime.hour,
            slot.endTime.minute,
          ),
          status: AttendanceStatus.free,
          location: slot.location,
          createdAt: DateTime.now(),
        );

        newRecords.add(record);
        await StorageService.addAttendanceRecord(record);
      }
    }

    _todayAttendance = newRecords;
    print('ScheduleScreen: Created ${newRecords.length} attendance records');
  }

  Future<void> _createAttendanceRecordsForSlots(List<TimeSlot> slots) async {
    final newRecords = <AttendanceRecord>[];

    for (final slot in slots) {
      if (slot.subjectId != null) {
        final subject = _getSubjectById(slot.subjectId!);
        print(
          'ScheduleScreen: Creating missing attendance record for ${subject?.name} (${subject?.type}) - Duration: ${subject?.duration}',
        );

        // Create unique ID using date, time, and subject to prevent duplicates
        final uniqueId =
            '${_selectedDate.year}${_selectedDate.month.toString().padLeft(2, '0')}${_selectedDate.day.toString().padLeft(2, '0')}_${slot.startTime.hour.toString().padLeft(2, '0')}${slot.startTime.minute.toString().padLeft(2, '0')}_${slot.subjectId}';

        final record = AttendanceRecord(
          id: uniqueId,
          subjectId: slot.subjectId!,
          date: _selectedDate,
          startTime: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            slot.startTime.hour,
            slot.startTime.minute,
          ),
          endTime: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            slot.endTime.hour,
            slot.endTime.minute,
          ),
          status: AttendanceStatus.free,
          location: slot.location,
          createdAt: DateTime.now(),
        );

        newRecords.add(record);
        await StorageService.addAttendanceRecord(record);
      }
    }

    // Add new records to existing list
    _todayAttendance.addAll(newRecords);
    print(
      'ScheduleScreen: Created ${newRecords.length} missing attendance records',
    );
  }

  Subject? _getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  AttendanceRecord? _getAttendanceForSlot(TimeSlot slot) {
    if (slot.subjectId == null) return null;

    try {
      return _todayAttendance.firstWhere(
        (record) =>
            record.subjectId == slot.subjectId &&
            record.date.year == _selectedDate.year &&
            record.date.month == _selectedDate.month &&
            record.date.day == _selectedDate.day &&
            record.startTime.hour == slot.startTime.hour &&
            record.startTime.minute == slot.startTime.minute,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateAttendanceStatus(
    AttendanceRecord record,
    AttendanceStatus newStatus,
  ) async {
    print(
      'ScheduleScreen: Updating attendance status to ${newStatus.name} for record ${record.id}',
    );

    try {
      final updatedRecord = record.copyWith(status: newStatus);
      await StorageService.updateAttendanceRecord(updatedRecord);
      print('ScheduleScreen: Successfully updated attendance in storage');

      // Update local list and refresh UI
      final index = _todayAttendance.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        setState(() {
          _todayAttendance[index] = updatedRecord;
        });
        print('ScheduleScreen: Updated local attendance list');

        // Force rebuild of the widget to reflect changes immediately
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance marked as ${newStatus.name}'),
            duration: const Duration(seconds: 1),
            backgroundColor: newStatus == AttendanceStatus.present
                ? Colors.green
                : newStatus == AttendanceStatus.absent
                ? Colors.red
                : null,
          ),
        );
      }
    } catch (e) {
      print('ScheduleScreen: Error updating attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating attendance: $e')),
        );
      }
    }
  }

  // Method that can be called externally to force refresh
  void forceRefresh() {
    print('ScheduleScreen: forceRefresh called');
    _loadScheduleData();
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadScheduleData();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.calendarBlank()),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadScheduleData,
              child: Column(
                children: [
                  // Date Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.defaultPadding),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppTheme.largeBorderRadius),
                        bottomRight: Radius.circular(
                          AppTheme.largeBorderRadius,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: AppTheme.headingTextStyle.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE').format(_selectedDate),
                          style: AppTheme.bodyTextStyle.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Schedule List
                  Expanded(
                    child: _todaySchedule.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIcons.calendarX(),
                                  size: 64,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No classes scheduled for this day',
                                  style: AppTheme.bodyTextStyle.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(
                              AppTheme.defaultPadding,
                            ),
                            itemCount: _todaySchedule.length,
                            itemBuilder: (context, index) {
                              final slot = _todaySchedule[index];
                              final subject = slot.subjectId != null
                                  ? _getSubjectById(slot.subjectId!)
                                  : null;
                              final attendance = _getAttendanceForSlot(slot);

                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppTheme.smallPadding,
                                ),
                                child: ScheduleCard(
                                  timeSlot: slot,
                                  subject: subject,
                                  attendanceRecord: attendance,
                                  onAttendanceUpdate: attendance != null
                                      ? (status) => _updateAttendanceStatus(
                                          attendance,
                                          status,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
