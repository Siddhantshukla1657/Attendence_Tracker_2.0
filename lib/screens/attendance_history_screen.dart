import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:attendence_tracker/models/attendance.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/services/storage_service.dart';
import 'package:attendence_tracker/theme/app_theme.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<AttendanceRecord> _allRecords = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;

  // Calendar view - group by individual dates
  Map<DateTime, List<AttendanceRecord>> _dateGroupedRecords = {};
  DateTime? _selectedDate; // Selected date filter
  List<AttendanceRecord> _filteredRecords = []; // Records for selected date

  // Subject view
  String? _selectedSubjectId;
  List<AttendanceRecord> _subjectRecords = [];

  @override
  void initState() {
    super.initState();
    print('AttendanceHistoryScreen: initState called');
    _tabController = TabController(length: 2, vsync: this);
    _loadHistoryData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('AttendanceHistoryScreen: didChangeDependencies called');
    // Reload data every time this screen is focused/opened
    print(
      'AttendanceHistoryScreen: Screen focused/opened - fetching fresh data',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print(
          'AttendanceHistoryScreen: Post frame callback - reloading history data',
        );
        _loadHistoryData();
      }
    });
  }

  @override
  void didUpdateWidget(AttendanceHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('AttendanceHistoryScreen: didUpdateWidget called');
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    print('AttendanceHistoryScreen: Loading attendance history data');

    try {
      _subjects = await StorageService.getSubjects();
      _allRecords = await StorageService.getAttendanceRecords();

      // Include all records (including free periods) for editing capability
      // Sort by date (newest first)
      _allRecords.sort((a, b) => b.date.compareTo(a.date));

      print(
        'AttendanceHistoryScreen: Loaded ${_subjects.length} subjects and ${_allRecords.length} attendance records (including free periods)',
      );

      _updateCalendarView();
      _updateSubjectView();
    } catch (e) {
      print('AttendanceHistoryScreen: Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance history: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method that can be called externally to force refresh
  void forceRefresh() {
    print('AttendanceHistoryScreen: forceRefresh called');
    _loadHistoryData();
  }

  void _updateCalendarView() {
    // Group records by date (day)
    _dateGroupedRecords.clear();

    for (final record in _allRecords) {
      final dateKey = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      if (!_dateGroupedRecords.containsKey(dateKey)) {
        _dateGroupedRecords[dateKey] = [];
      }
      _dateGroupedRecords[dateKey]!.add(record);
    }

    // Update filtered records based on selected date
    if (_selectedDate != null) {
      _filteredRecords = _dateGroupedRecords[_selectedDate] ?? [];
    } else {
      _filteredRecords = [];
    }

    print(
      'AttendanceHistoryScreen: Calendar view - ${_dateGroupedRecords.length} dates with ${_allRecords.length} total records. Selected date: ${_selectedDate != null ? DateFormat('MMM d, yyyy').format(_selectedDate!) : 'None'}',
    );
  }

  void _updateSubjectView() {
    if (_selectedSubjectId != null) {
      _subjectRecords = _allRecords
          .where((record) => record.subjectId == _selectedSubjectId)
          .toList();

      final subject = _getSubjectById(_selectedSubjectId!);
      print(
        'AttendanceHistoryScreen: Subject view - ${_subjectRecords.length} records for ${subject?.name}',
      );
    } else {
      _subjectRecords = [];
    }
  }

  Future<void> _updateAttendanceStatus(
    AttendanceRecord record,
    AttendanceStatus newStatus,
  ) async {
    print(
      'AttendanceHistoryScreen: Updating attendance status from ${record.status.name} to ${newStatus.name} for record ${record.id}',
    );

    try {
      final updatedRecord = record.copyWith(status: newStatus);
      await StorageService.updateAttendanceRecord(updatedRecord);
      print(
        'AttendanceHistoryScreen: Successfully updated attendance status in storage',
      );

      // Update local lists
      final allIndex = _allRecords.indexWhere((r) => r.id == record.id);
      if (allIndex != -1) {
        _allRecords[allIndex] = updatedRecord;
      }

      // Update date grouped records if needed
      for (final dateKey in _dateGroupedRecords.keys) {
        final dateIndex = _dateGroupedRecords[dateKey]!.indexWhere(
          (r) => r.id == record.id,
        );
        if (dateIndex != -1) {
          _dateGroupedRecords[dateKey]![dateIndex] = updatedRecord;
        }
      }

      // Update filtered records if needed
      if (_selectedDate != null) {
        final filteredIndex = _filteredRecords.indexWhere(
          (r) => r.id == record.id,
        );
        if (filteredIndex != -1) {
          _filteredRecords[filteredIndex] = updatedRecord;
        }
      }

      // Update subject records if needed
      final subjectIndex = _subjectRecords.indexWhere((r) => r.id == record.id);
      if (subjectIndex != -1) {
        _subjectRecords[subjectIndex] = updatedRecord;
      }

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance updated to ${newStatus.name}'),
            duration: const Duration(seconds: 2),
            backgroundColor: newStatus == AttendanceStatus.present
                ? Colors.green
                : newStatus == AttendanceStatus.absent
                ? Colors.red
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('AttendanceHistoryScreen: Error updating attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating attendance: $e')),
        );
      }
    }
  }

  void _showAttendanceOptions(AttendanceRecord record) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Attendance Status',
              style: AppTheme.subheadingTextStyle,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.presentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  PhosphorIcons.check(),
                  color: AppTheme.presentColor,
                ),
              ),
              title: const Text('Present'),
              trailing: record.status == AttendanceStatus.present
                  ? Icon(PhosphorIcons.check(), color: AppTheme.presentColor)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateAttendanceStatus(record, AttendanceStatus.present);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.absentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(PhosphorIcons.x(), color: AppTheme.absentColor),
              ),
              title: const Text('Absent'),
              trailing: record.status == AttendanceStatus.absent
                  ? Icon(PhosphorIcons.check(), color: AppTheme.presentColor)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateAttendanceStatus(record, AttendanceStatus.absent);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.freeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(PhosphorIcons.coffee(), color: AppTheme.freeColor),
              ),
              title: const Text('Free Period'),
              subtitle: const Text('Mark as not conducted'),
              trailing: record.status == AttendanceStatus.free
                  ? Icon(PhosphorIcons.check(), color: AppTheme.presentColor)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateAttendanceStatus(record, AttendanceStatus.free);
              },
            ),
          ],
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

  void _showDatePicker() async {
    print(
      'AttendanceHistoryScreen: Opening date picker. Available dates: ${_dateGroupedRecords.keys.length}',
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      selectableDayPredicate: (date) {
        // Only allow dates that have attendance records
        final dateKey = DateTime(date.year, date.month, date.day);
        return _dateGroupedRecords.containsKey(dateKey);
      },
    );

    if (picked != null) {
      final dateKey = DateTime(picked.year, picked.month, picked.day);
      setState(() {
        _selectedDate = dateKey;
      });
      _updateCalendarView();
      print(
        'AttendanceHistoryScreen: Selected date changed to ${DateFormat('MMM d, yyyy').format(dateKey)}',
      );
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _updateCalendarView();
    print('AttendanceHistoryScreen: Date filter cleared - showing all dates');
  }

  void _showSubjectPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Subject', style: AppTheme.subheadingTextStyle),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Subjects'),
              trailing: _selectedSubjectId == null
                  ? Icon(PhosphorIcons.check(), color: AppTheme.presentColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedSubjectId = null;
                });
                _updateSubjectView();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  final subject = _subjects[index];
                  final isSelected = _selectedSubjectId == subject.id;
                  return ListTile(
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(subject.color.replaceFirst('#', '0xff')),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(subject.name),
                    subtitle: Text('Teacher: ${subject.teacherName}'),
                    trailing: isSelected
                        ? Icon(
                            PhosphorIcons.check(),
                            color: AppTheme.presentColor,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSubjectId = subject.id;
                      });
                      _updateSubjectView();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar View'),
            Tab(icon: Icon(Icons.book), text: 'Subject View'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildCalendarView(), _buildSubjectView()],
            ),
    );
  }

  Widget _buildCalendarView() {
    print(
      'AttendanceHistoryScreen: Building calendar view. Selected date: $_selectedDate, Records: ${_allRecords.length}',
    );

    if (_selectedDate != null) {
      // Show records for selected date only
      return Column(
        children: [
          // Selected date header with calendar picker
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.largeBorderRadius),
                bottomRight: Radius.circular(AppTheme.largeBorderRadius),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!),
                        style: AppTheme.headingTextStyle.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${_filteredRecords.length} ${_filteredRecords.length == 1 ? 'record' : 'records'}',
                        style: AppTheme.bodyTextStyle.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showDatePicker,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Change Date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearDateFilter,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Show All Dates',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.error.withOpacity(0.1),
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),

          // Records for selected date
          Expanded(
            child: _filteredRecords.isEmpty
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
                          'No attendance records for this date',
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
                    padding: const EdgeInsets.all(AppTheme.defaultPadding),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
                      final subject = _getSubjectById(record.subjectId);
                      return _buildAttendanceRecordCard(record, subject);
                    },
                  ),
          ),
        ],
      );
    } else {
      // Show all dates grouped
      final sortedDates = _dateGroupedRecords.keys.toList()
        ..sort((a, b) => b.compareTo(a)); // Newest first

      return Column(
        children: [
          // Header with calendar picker
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.largeBorderRadius),
                bottomRight: Radius.circular(AppTheme.largeBorderRadius),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance History',
                        style: AppTheme.headingTextStyle.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${_allRecords.length} total records across ${_dateGroupedRecords.length} dates',
                        style: AppTheme.bodyTextStyle.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Pick Date" to filter by specific date',
                        style: AppTheme.captionTextStyle.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showDatePicker,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Pick Date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),

          // Date-grouped records
          Expanded(
            child: _dateGroupedRecords.isEmpty
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
                          'No attendance records found',
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
                    padding: const EdgeInsets.all(AppTheme.defaultPadding),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final records = _dateGroupedRecords[date]!;
                      return _buildDateSection(date, records);
                    },
                  ),
          ),
        ],
      );
    }
  }

  Widget _buildDateSection(DateTime date, List<AttendanceRecord> records) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.largeBorderRadius),
                topRight: Radius.circular(AppTheme.largeBorderRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.calendar(),
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(date),
                  style: AppTheme.subheadingTextStyle.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${records.length} ${records.length == 1 ? 'record' : 'records'}',
                    style: AppTheme.captionTextStyle.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Records for this date
          ...records.map((record) {
            final subject = _getSubjectById(record.subjectId);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildAttendanceRecordCard(record, subject),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSubjectView() {
    return Column(
      children: [
        // Subject selector
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppTheme.largeBorderRadius),
              bottomRight: Radius.circular(AppTheme.largeBorderRadius),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSubjectId != null
                          ? _getSubjectById(_selectedSubjectId!)?.name ??
                                'Unknown Subject'
                          : 'Select a Subject',
                      style: AppTheme.headingTextStyle.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      _selectedSubjectId != null
                          ? '${_subjectRecords.length} records'
                          : 'Choose a subject to view history',
                      style: AppTheme.bodyTextStyle.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showSubjectPicker,
                icon: Icon(PhosphorIcons.books()),
                label: const Text('Choose Subject'),
              ),
            ],
          ),
        ),

        // Subject records
        Expanded(
          child: _selectedSubjectId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.books(),
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select a subject to view attendance history',
                        style: AppTheme.bodyTextStyle.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : _subjectRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.clipboardText(),
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance records for this subject',
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
                  padding: const EdgeInsets.all(AppTheme.defaultPadding),
                  itemCount: _subjectRecords.length,
                  itemBuilder: (context, index) {
                    final record = _subjectRecords[index];
                    final subject = _getSubjectById(record.subjectId);
                    return _buildAttendanceRecordCard(record, subject);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAttendanceRecordCard(AttendanceRecord record, Subject? subject) {
    final statusColor = _getStatusColor(record.status);
    final isToday = _isToday(record.date);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallPadding),
      elevation: isToday ? 4 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
          border: isToday
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : Border.all(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with date and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date and time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(record.date),
                            style: AppTheme.subheadingTextStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'TODAY',
                                style: AppTheme.captionTextStyle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${DateFormat('HH:mm').format(record.startTime)} - ${DateFormat('HH:mm').format(record.endTime)}',
                        style: AppTheme.captionTextStyle,
                      ),
                    ],
                  ),

                  // Status badge
                  GestureDetector(
                    onTap: () => _showAttendanceOptions(record),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getStatusText(record.status),
                            style: AppTheme.captionTextStyle.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            PhosphorIcons.pencil(),
                            size: 12,
                            color: statusColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Subject information
              if (subject != null) ...[
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(subject.color.replaceFirst('#', '0xff')),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: AppTheme.bodyTextStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Teacher: ${subject.teacherName}',
                            style: AppTheme.captionTextStyle,
                          ),
                          if (subject.classroom.isNotEmpty)
                            Text(
                              'Room: ${subject.classroom}',
                              style: AppTheme.captionTextStyle,
                            ),
                        ],
                      ),
                    ),
                    // Subject type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getSubjectTypeColor(
                          subject.type.toString(),
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subject.type == SubjectType.lecture ? 'Lecture' : 'Lab',
                        style: AppTheme.captionTextStyle.copyWith(
                          color: AppTheme.getSubjectTypeColor(
                            subject.type.toString(),
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Location if available
              if (record.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(PhosphorIcons.mapPin(), size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      record.location!,
                      style: AppTheme.captionTextStyle.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
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
