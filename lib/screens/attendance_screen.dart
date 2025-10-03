import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:attendence_tracker/models/attendance.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/services/storage_service.dart';
import 'package:attendence_tracker/theme/app_theme.dart';
import 'package:attendence_tracker/screens/past_lectures_screen.dart';
import 'package:attendence_tracker/screens/attendance_history_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  List<AttendanceRecord> _attendanceRecords = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('AttendanceScreen: initState called');
    _loadAttendanceData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('AttendanceScreen: didChangeDependencies called');
    // Reload data every time this screen is focused/opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print(
          'AttendanceScreen: Post frame callback - reloading attendance data',
        );
        _loadAttendanceData();
      }
    });
  }

  @override
  void didUpdateWidget(AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('AttendanceScreen: didUpdateWidget called');
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);
    print(
      'AttendanceScreen: Loading attendance data for ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
    );

    try {
      _subjects = await StorageService.getSubjects();

      // Clean up any duplicate records before loading
      final duplicatesRemoved =
          await StorageService.cleanupDuplicateAttendanceRecords();
      if (duplicatesRemoved > 0) {
        print(
          'AttendanceScreen: Cleaned up $duplicatesRemoved duplicate records',
        );
      }

      _attendanceRecords = await StorageService.getAttendanceForDate(
        _selectedDate,
      );
      print(
        'AttendanceScreen: Loaded ${_subjects.length} subjects and ${_attendanceRecords.length} attendance records',
      );
    } catch (e) {
      print('AttendanceScreen: Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading attendance: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method that can be called externally to force refresh
  void forceRefresh() {
    print('AttendanceScreen: forceRefresh called');
    _loadAttendanceData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PastLecturesScreen(),
                ),
              );
            },
            child: const Text('Past Lectures'),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.clockCounterClockwise()),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AttendanceHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date tabs for Today and Yesterday
                Container(
                  margin: const EdgeInsets.all(AppTheme.defaultPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDateTab(
                          'Today',
                          DateTime.now(),
                          _selectedDate.day == DateTime.now().day,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDateTab(
                          'Yesterday',
                          DateTime.now().subtract(const Duration(days: 1)),
                          _selectedDate.day ==
                              DateTime.now()
                                  .subtract(const Duration(days: 1))
                                  .day,
                        ),
                      ),
                    ],
                  ),
                ),

                // Attendance list
                Expanded(
                  child: _attendanceRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.clipboard(),
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No attendance records for this day',
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
                          itemCount: _attendanceRecords.length,
                          itemBuilder: (context, index) {
                            final record = _attendanceRecords[index];
                            final subject = _getSubjectById(record.subjectId);

                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: AppTheme.smallPadding,
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: subject != null
                                        ? Color(
                                            int.parse(
                                              subject.color.replaceFirst(
                                                '#',
                                                '0xff',
                                              ),
                                            ),
                                          )
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(subject?.name ?? 'Unknown Subject'),
                                subtitle: Text(
                                  '${DateFormat('HH:mm').format(record.startTime)} - ${DateFormat('HH:mm').format(record.endTime)}',
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      record.status,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(record.status),
                                    style: AppTheme.captionTextStyle.copyWith(
                                      color: _getStatusColor(record.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateTab(String label, DateTime date, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        _loadAttendanceData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodyTextStyle.copyWith(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Subject? _getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppTheme.presentColor;
      case AttendanceStatus.absent:
        return AppTheme.absentColor;
      case AttendanceStatus.free:
      default:
        return AppTheme.freeColor;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.free:
      default:
        return 'Free';
    }
  }
}
