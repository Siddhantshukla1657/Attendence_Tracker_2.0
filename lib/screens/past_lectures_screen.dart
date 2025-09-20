import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:attendence_tracker/models/attendance.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/services/storage_service.dart';
import 'package:attendence_tracker/theme/app_theme.dart';

class PastLecturesScreen extends StatefulWidget {
  const PastLecturesScreen({super.key});

  @override
  State<PastLecturesScreen> createState() => _PastLecturesScreenState();
}

class _PastLecturesScreenState extends State<PastLecturesScreen> {
  List<AttendanceRecord> _allRecords = [];
  List<AttendanceRecord> _filteredRecords = [];
  List<Subject> _subjects = [];
  String? _selectedSubjectId;
  bool _isLoading = true;
  int _selectedFilter = 0; // 0: All, 1: Present, 2: Absent

  @override
  void initState() {
    super.initState();
    _loadPastLectures();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data every time this screen is focused/opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPastLectures();
      }
    });
  }

  Future<void> _loadPastLectures() async {
    setState(() => _isLoading = true);
    print('PastLecturesScreen: Loading past lectures data');

    try {
      _subjects = await StorageService.getSubjects();
      _allRecords = await StorageService.getAttendanceRecords();

      // Filter out records that are in free state (not conducted)
      _allRecords = _allRecords.where((record) => record.wasConducted).toList();

      // Sort by date (newest first)
      _allRecords.sort((a, b) => b.date.compareTo(a.date));

      print(
        'PastLecturesScreen: Loaded ${_subjects.length} subjects and ${_allRecords.length} past records',
      );

      _applyFilters();
    } catch (e) {
      print('PastLecturesScreen: Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading past lectures: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    _filteredRecords = _allRecords.where((record) {
      // Subject filter
      if (_selectedSubjectId != null &&
          record.subjectId != _selectedSubjectId) {
        return false;
      }

      // Status filter
      switch (_selectedFilter) {
        case 1: // Present only
          return record.wasPresent;
        case 2: // Absent only
          return record.wasAbsent;
        default: // All
          return true;
      }
    }).toList();

    setState(() {});
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

  void _showSubjectFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Subject', style: AppTheme.subheadingTextStyle),
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
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ..._subjects.map((subject) {
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
                    ? Icon(PhosphorIcons.check(), color: AppTheme.presentColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedSubjectId = subject.id;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Lectures'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.funnel()),
            onPressed: _showSubjectFilter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter tabs
                Container(
                  margin: const EdgeInsets.all(AppTheme.defaultPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFilterTab(
                          'All',
                          0,
                          _filteredRecords.length,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterTab(
                          'Present',
                          1,
                          _allRecords.where((r) => r.wasPresent).length,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterTab(
                          'Absent',
                          2,
                          _allRecords.where((r) => r.wasAbsent).length,
                        ),
                      ),
                    ],
                  ),
                ),

                // Subject filter indicator
                if (_selectedSubjectId != null)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.defaultPadding,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(
                                _getSubjectById(
                                      _selectedSubjectId!,
                                    )?.color.replaceFirst('#', '0xff') ??
                                    '0xff2196F3',
                              ),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filtered by: ${_getSubjectById(_selectedSubjectId!)?.name ?? 'Unknown'}',
                          style: AppTheme.bodyTextStyle.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSubjectId = null;
                            });
                            _applyFilters();
                          },
                          child: Icon(
                            PhosphorIcons.x(),
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Lectures list
                Expanded(
                  child: _filteredRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.clockCounterClockwise(),
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedSubjectId != null
                                    ? 'No lectures found for selected subject'
                                    : 'No past lectures found',
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
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            final subject = _getSubjectById(record.subjectId);

                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: AppTheme.smallPadding,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppTheme.defaultPadding,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Subject and Date Row
                                    Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: subject != null
                                                ? Color(
                                                    int.parse(
                                                      subject.color
                                                          .replaceFirst(
                                                            '#',
                                                            '0xff',
                                                          ),
                                                    ),
                                                  )
                                                : Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            subject?.name ?? 'Unknown Subject',
                                            style: AppTheme.subheadingTextStyle
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              record.status,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusText(record.status),
                                            style: AppTheme.captionTextStyle
                                                .copyWith(
                                                  color: _getStatusColor(
                                                    record.status,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Date and Time Row
                                    Row(
                                      children: [
                                        Icon(
                                          PhosphorIcons.calendar(),
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat(
                                            'MMM dd, yyyy',
                                          ).format(record.date),
                                          style: AppTheme.captionTextStyle
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.8),
                                              ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          PhosphorIcons.clock(),
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${DateFormat('HH:mm').format(record.startTime)} - ${DateFormat('HH:mm').format(record.endTime)}',
                                          style: AppTheme.captionTextStyle
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.8),
                                              ),
                                        ),
                                      ],
                                    ),

                                    // Subject details
                                    if (subject != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              subject.teacherName,
                                              style: AppTheme.captionTextStyle
                                                  .copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.getSubjectTypeColor(
                                                    subject.type.toString(),
                                                  ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              subject.type ==
                                                      SubjectType.lecture
                                                  ? 'Lecture'
                                                  : 'Lab',
                                              style: AppTheme.captionTextStyle
                                                  .copyWith(
                                                    color:
                                                        AppTheme.getSubjectTypeColor(
                                                          subject.type
                                                              .toString(),
                                                        ),
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ),
                                          if (record.location != null) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              PhosphorIcons.mapPin(),
                                              size: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              record.location!,
                                              style: AppTheme.captionTextStyle
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.8),
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
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

  Widget _buildFilterTab(String label, int index, int count) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTheme.bodyTextStyle.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: AppTheme.captionTextStyle.copyWith(
                color: isSelected
                    ? Colors.white.withOpacity(0.8)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
