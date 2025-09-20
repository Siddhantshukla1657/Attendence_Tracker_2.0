import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:attendence_tracker/models/attendance.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/services/storage_service.dart';
import 'package:attendence_tracker/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<AttendanceRecord> _allRecords = [];
  List<Subject> _subjects = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;

  // Overall statistics
  late AttendanceStats _overallStats;
  late AttendanceStats _lectureStats;
  late AttendanceStats _labStats;

  // Subject-wise statistics
  Map<String, AttendanceStats> _subjectStats = {};

  @override
  void initState() {
    super.initState();
    print('ReportsScreen: initState called');
    _loadReportsData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('ReportsScreen: didChangeDependencies called');
    // Reload data every time this screen is focused/opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('ReportsScreen: Post frame callback - reloading reports data');
        _loadReportsData();
      }
    });
  }

  @override
  void didUpdateWidget(ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('ReportsScreen: didUpdateWidget called');
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);
    print(
      'ReportsScreen: Loading reports data for ${DateFormat('yyyy-MM').format(_selectedMonth)}',
    );

    try {
      _subjects = await StorageService.getSubjects();
      _allRecords = await StorageService.getAttendanceForMonth(
        _selectedMonth.year,
        _selectedMonth.month,
      );
      print(
        'ReportsScreen: Loaded ${_subjects.length} subjects and ${_allRecords.length} attendance records',
      );

      _calculateStatistics();
    } catch (e) {
      print('ReportsScreen: Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method that can be called externally to force refresh
  void forceRefresh() {
    print('ReportsScreen: forceRefresh called');
    _loadReportsData();
  }

  void _calculateStatistics() {
    // Filter conducted records
    final conductedRecords = _allRecords.where((r) => r.wasConducted).toList();

    // Overall statistics
    _overallStats = AttendanceStats.fromRecords(conductedRecords);

    // Lecture and Lab statistics
    final lectureRecords = <AttendanceRecord>[];
    final labRecords = <AttendanceRecord>[];

    for (final record in conductedRecords) {
      final subject = _getSubjectById(record.subjectId);
      if (subject != null) {
        if (subject.type == SubjectType.lecture) {
          lectureRecords.add(record);
        } else {
          labRecords.add(record);
        }
      }
    }

    _lectureStats = AttendanceStats.fromRecords(lectureRecords);
    _labStats = AttendanceStats.fromRecords(labRecords);

    // Subject-wise statistics
    _subjectStats.clear();
    for (final subject in _subjects) {
      final subjectRecords = conductedRecords
          .where((r) => r.subjectId == subject.id)
          .toList();
      _subjectStats[subject.id] = AttendanceStats.fromRecords(subjectRecords);
    }
  }

  Subject? _getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadReportsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          TextButton.icon(
            onPressed: _showMonthPicker,
            icon: Icon(PhosphorIcons.calendar()),
            label: Text(DateFormat('MMM yyyy').format(_selectedMonth)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month header
                  Text(
                    'Attendance Summary for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                    style: AppTheme.headingTextStyle,
                  ),
                  const SizedBox(height: 20),

                  // Overall statistics cards
                  _buildOverallStatsSection(),

                  const SizedBox(height: 24),

                  // Attendance chart
                  _buildAttendanceChart(),

                  const SizedBox(height: 24),

                  // Lecture vs Lab breakdown
                  _buildLectureLabBreakdown(),

                  const SizedBox(height: 24),

                  // Subject-wise breakdown
                  _buildSubjectWiseBreakdown(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallStatsSection() {
    return Column(
      children: [
        // Main statistics row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Lectures',
                _overallStats.conductedLectures.toString(),
                Colors.blue,
                PhosphorIcons.books(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Present',
                _overallStats.presentCount.toString(),
                AppTheme.presentColor,
                PhosphorIcons.check(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Absent',
                _overallStats.absentCount.toString(),
                AppTheme.absentColor,
                PhosphorIcons.x(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Attendance percentage card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
          ),
          child: Column(
            children: [
              Text(
                'Attendance Percentage',
                style: AppTheme.subheadingTextStyle.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_overallStats.attendancePercentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.subheadingTextStyle.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.captionTextStyle.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    if (_overallStats.conductedLectures == 0) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
        ),
        child: const Center(child: Text('No data to display')),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance Overview', style: AppTheme.subheadingTextStyle),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: _overallStats.presentCount.toDouble(),
                      color: AppTheme.presentColor,
                      title: 'Present\n${_overallStats.presentCount}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: _overallStats.absentCount.toDouble(),
                      color: AppTheme.absentColor,
                      title: 'Absent\n${_overallStats.absentCount}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureLabBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lecture vs Lab Breakdown',
              style: AppTheme.subheadingTextStyle,
            ),
            const SizedBox(height: 16),

            // Lectures
            _buildTypeBreakdownRow(
              'Total Lectures Attended',
              _lectureStats.presentCount,
              _lectureStats.conductedLectures,
              _lectureStats.attendancePercentage,
              AppTheme.lectureColor,
            ),

            const SizedBox(height: 12),

            // Labs
            _buildTypeBreakdownRow(
              'Total Labs Attended',
              _labStats.presentCount,
              _labStats.conductedLectures,
              _labStats.attendancePercentage,
              AppTheme.labColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBreakdownRow(
    String title,
    int present,
    int total,
    double percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTheme.bodyTextStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$present / $total',
              style: AppTheme.bodyTextStyle.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: total > 0 ? present / total : 0,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTheme.captionTextStyle.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectWiseBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject-wise Attendance',
              style: AppTheme.subheadingTextStyle,
            ),
            const SizedBox(height: 16),

            if (_subjects.isEmpty)
              const Center(child: Text('No subjects available'))
            else
              ..._subjects.map((subject) {
                final stats =
                    _subjectStats[subject.id] ??
                    AttendanceStats(
                      totalLectures: 0,
                      conductedLectures: 0,
                      presentCount: 0,
                      absentCount: 0,
                    );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  subject.color.replaceFirst('#', '0xff'),
                                ),
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subject.name,
                              style: AppTheme.bodyTextStyle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${stats.presentCount}/${stats.conductedLectures}',
                            style: AppTheme.bodyTextStyle.copyWith(
                              color: Color(
                                int.parse(
                                  subject.color.replaceFirst('#', '0xff'),
                                ),
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Teacher: ${subject.teacherName}',
                        style: AppTheme.captionTextStyle,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: stats.conductedLectures > 0
                                  ? stats.presentCount / stats.conductedLectures
                                  : 0,
                              backgroundColor: Color(
                                int.parse(
                                  subject.color.replaceFirst('#', '0xff'),
                                ),
                              ).withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(
                                  int.parse(
                                    subject.color.replaceFirst('#', '0xff'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${stats.attendancePercentage.toStringAsFixed(1)}%',
                            style: AppTheme.captionTextStyle.copyWith(
                              color: Color(
                                int.parse(
                                  subject.color.replaceFirst('#', '0xff'),
                                ),
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
