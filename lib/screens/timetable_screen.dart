import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:attendence_tracker/models/timetable.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/services/storage_service.dart';
import 'package:attendence_tracker/theme/app_theme.dart';
import 'package:intl/intl.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<Timetable> _timetables = [];
  List<Subject> _subjects = [];
  Timetable? _activeTimetable;
  DayOfWeek _selectedDay = DayOfWeek.monday;
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0 for timetable list, 1 for active timetable

  @override
  void initState() {
    super.initState();
    print('TimetableScreen: initState called');
    _loadTimetableData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('TimetableScreen: didChangeDependencies called');
    // Reload data every time this screen is focused/opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('TimetableScreen: Post frame callback - reloading data');
        _loadTimetableData();
      }
    });
  }

  @override
  void didUpdateWidget(TimetableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('TimetableScreen: didUpdateWidget called');
    _loadTimetableData();
  }

  Future<void> _loadTimetableData() async {
    setState(() => _isLoading = true);

    try {
      _timetables = await StorageService.getTimetables();
      _subjects = await StorageService.getSubjects();
      _activeTimetable = await StorageService.getActiveTimetable();

      // Debug logging
      print(
        'TimetableScreen: Loaded ${_subjects.length} subjects and ${_timetables.length} timetables',
      );
      for (final subject in _subjects) {
        print(
          'Subject: ${subject.name} - ${subject.teacherName} (${subject.id})',
        );
      }
    } catch (e) {
      print('TimetableScreen: Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading timetables: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method that can be called externally to force refresh
  void forceRefresh() {
    print('TimetableScreen: forceRefresh called');
    _loadTimetableData();
  }

  void _showCreateTimetableDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTimetableDialog(
        onTimetableCreated: (timetable) {
          setState(() {
            _timetables.add(timetable);
            if (_activeTimetable == null) {
              _activeTimetable = timetable;
            }
          });
        },
      ),
    );
  }

  void _editTimeSlot(TimeSlot? existingSlot) async {
    // Refresh subjects list before opening dialog
    await _loadTimetableData();

    print('EditTimeSlot: Subjects available: ${_subjects.length}');
    for (final subject in _subjects) {
      print('Available subject: ${subject.name} - ${subject.teacherName}');
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => EditTimeSlotDialog(
          subjects: _subjects,
          dayOfWeek: _selectedDay,
          existingSlot: existingSlot,
          onSlotSaved: (slot) {
            _updateTimeSlot(slot, existingSlot);
          },
        ),
      );
    }
  }

  Future<void> _updateTimeSlot(TimeSlot newSlot, TimeSlot? existingSlot) async {
    if (_activeTimetable == null) return;

    final updatedSchedule = Map<DayOfWeek, List<TimeSlot>>.from(
      _activeTimetable!.schedule,
    );
    final daySlots = List<TimeSlot>.from(updatedSchedule[_selectedDay] ?? []);

    if (existingSlot != null) {
      final index = daySlots.indexWhere((s) => s.id == existingSlot.id);
      if (index != -1) {
        daySlots[index] = newSlot;
      }
    } else {
      daySlots.add(newSlot);
    }

    // Sort slots by start time
    daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));
    updatedSchedule[_selectedDay] = daySlots;

    final updatedTimetable = _activeTimetable!.copyWith(
      schedule: updatedSchedule,
    );

    try {
      await StorageService.updateTimetable(updatedTimetable);
      setState(() {
        _activeTimetable = updatedTimetable;
        final index = _timetables.indexWhere(
          (t) => t.id == updatedTimetable.id,
        );
        if (index != -1) {
          _timetables[index] = updatedTimetable;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating timetable: $e')));
      }
    }
  }

  void _showDeleteTimetableConfirmation(Timetable timetable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timetable'),
        content: Text(
          'Are you sure you want to delete "${timetable.name}"? This action cannot be undone and will remove all associated time slots.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTimetable(timetable);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTimetable(Timetable timetable) async {
    try {
      await StorageService.deleteTimetable(timetable.id);
      setState(() {
        _timetables.removeWhere((t) => t.id == timetable.id);
        // If the deleted timetable was active, set a new active one or clear
        if (_activeTimetable?.id == timetable.id) {
          if (_timetables.isNotEmpty) {
            _activeTimetable = _timetables.first;
            StorageService.setActiveTimetable(_activeTimetable!.id);
          } else {
            _activeTimetable = null;
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Timetable "${timetable.name}" deleted successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting timetable: $e')));
      }
    }
  }

  Future<void> _setActiveTimetable(Timetable timetable) async {
    try {
      await StorageService.setActiveTimetable(timetable.id);
      setState(() {
        _activeTimetable = timetable;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${timetable.name}" is now active')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting active timetable: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(TimeSlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Slot'),
        content: const Text('Are you sure you want to delete this time slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTimeSlot(slot);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTimeSlot(TimeSlot slot) async {
    if (_activeTimetable == null) return;

    final updatedSchedule = Map<DayOfWeek, List<TimeSlot>>.from(
      _activeTimetable!.schedule,
    );
    final daySlots = List<TimeSlot>.from(updatedSchedule[_selectedDay] ?? []);
    daySlots.removeWhere((s) => s.id == slot.id);
    updatedSchedule[_selectedDay] = daySlots;

    final updatedTimetable = _activeTimetable!.copyWith(
      schedule: updatedSchedule,
    );

    try {
      await StorageService.updateTimetable(updatedTimetable);
      setState(() {
        _activeTimetable = updatedTimetable;
        final index = _timetables.indexWhere(
          (t) => t.id == updatedTimetable.id,
        );
        if (index != -1) {
          _timetables[index] = updatedTimetable;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting time slot: $e')));
      }
    }
  }

  Subject? _getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Timetable'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'All Timetables', icon: Icon(PhosphorIcons.list())),
              Tab(
                text: 'Active Schedule',
                icon: Icon(PhosphorIcons.calendar()),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Timetables List Tab
                  _buildTimetableListView(),
                  // Active Timetable Tab
                  _activeTimetable == null
                      ? _buildEmptyState()
                      : Column(
                          children: [
                            // Day selector
                            _buildDaySelector(),
                            // Time slots
                            Expanded(child: _buildTimeSlotsList()),
                          ],
                        ),
                ],
              ),
        floatingActionButton: _activeTimetable != null
            ? FloatingActionButton.extended(
                onPressed: () => _editTimeSlot(null),
                icon: Icon(PhosphorIcons.plus()),
                label: const Text('Add Slot'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              )
            : FloatingActionButton.extended(
                onPressed: _showCreateTimetableDialog,
                icon: Icon(PhosphorIcons.plus()),
                label: const Text('Create Timetable'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
      ),
    );
  }

  Widget _buildTimetableListView() {
    if (_timetables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.calendarBlank(),
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Timetables Yet',
              style: AppTheme.headingTextStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first timetable to get started\nwith organizing your schedule',
              textAlign: TextAlign.center,
              style: AppTheme.bodyTextStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateTimetableDialog,
              icon: Icon(PhosphorIcons.plus()),
              label: const Text('Create First Timetable'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with create button
        Container(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Timetables',
                    style: AppTheme.headingTextStyle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_timetables.length} timetable${_timetables.length != 1 ? 's' : ''} created',
                    style: AppTheme.captionTextStyle.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showCreateTimetableDialog,
                icon: Icon(PhosphorIcons.plus(), size: 18),
                label: const Text('New'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Timetables list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.defaultPadding),
            itemCount: _timetables.length,
            itemBuilder: (context, index) {
              final timetable = _timetables[index];
              final isActive = timetable.id == _activeTimetable?.id;
              final totalSlots = timetable.schedule.values
                  .expand((slots) => slots)
                  .length;
              final daysWithSlots = timetable.schedule.values
                  .where((slots) => slots.isNotEmpty)
                  .length;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isActive
                      ? null
                      : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: isActive ? 12 : 8,
                      offset: Offset(0, isActive ? 6 : 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isActive
                        ? null
                        : () => _setActiveTimetable(timetable),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.white.withOpacity(0.2)
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        PhosphorIcons.calendar(),
                                        size: 20,
                                        color: isActive
                                            ? Colors.white
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            timetable.name,
                                            style: AppTheme.subheadingTextStyle
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: isActive
                                                      ? Colors.white
                                                      : Theme.of(
                                                          context,
                                                        ).colorScheme.onSurface,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Created ${DateFormat('MMM dd, yyyy').format(timetable.createdAt)}',
                                            style: AppTheme.captionTextStyle
                                                .copyWith(
                                                  color: isActive
                                                      ? Colors.white
                                                            .withOpacity(0.8)
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.6),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: AppTheme.captionTextStyle
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton(
                                    icon: Icon(
                                      PhosphorIcons.dotsThreeVertical(),
                                      color: isActive
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                    itemBuilder: (context) => [
                                      if (!isActive)
                                        PopupMenuItem(
                                          value: 'activate',
                                          child: Row(
                                            children: [
                                              Icon(
                                                PhosphorIcons.checkCircle(),
                                                color: Colors.green,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('Set as Active'),
                                            ],
                                          ),
                                        ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              PhosphorIcons.trash(),
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'activate') {
                                        _setActiveTimetable(timetable);
                                      } else if (value == 'delete') {
                                        _showDeleteTimetableConfirmation(
                                          timetable,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Stats row
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: PhosphorIcons.clock(),
                                  label: 'Total Slots',
                                  value: totalSlots.toString(),
                                  isActive: isActive,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatItem(
                                  icon: PhosphorIcons.calendarCheck(),
                                  label: 'Active Days',
                                  value: daysWithSlots.toString(),
                                  isActive: isActive,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.1)
            : Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive
                ? Colors.white.withOpacity(0.8)
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTheme.subheadingTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: AppTheme.captionTextStyle.copyWith(
                    fontSize: 11,
                    color: isActive
                        ? Colors.white.withOpacity(0.7)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.clock(),
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No timetable created yet',
            style: AppTheme.bodyTextStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showCreateTimetableDialog,
            icon: Icon(PhosphorIcons.plus()),
            label: const Text('Create Timetable'),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.defaultPadding),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: DayOfWeek.values.map((day) {
          final isSelected = day == _selectedDay;
          final daySlots = _activeTimetable?.getScheduleForDay(day) ?? [];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = day;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day.shortName,
                      style: AppTheme.bodyTextStyle.copyWith(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${daySlots.length}',
                        style: AppTheme.captionTextStyle.copyWith(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeSlotsList() {
    final daySlots = _activeTimetable?.getScheduleForDay(_selectedDay) ?? [];

    if (daySlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.calendarPlus(),
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No classes on ${_selectedDay.displayName}',
              style: AppTheme.subheadingTextStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first time slot to get started',
              style: AppTheme.bodyTextStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _editTimeSlot(null),
              icon: Icon(PhosphorIcons.plus(), size: 18),
              label: const Text('Add Time Slot'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      itemCount: daySlots.length,
      itemBuilder: (context, index) {
        final slot = daySlots[index];
        final subject = slot.subjectId != null
            ? _getSubjectById(slot.subjectId!)
            : null;
        final isFreePeriod = subject == null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: !isFreePeriod
                ? LinearGradient(
                    colors: [
                      Color(
                        int.parse(subject!.color.replaceFirst('#', '0xff')),
                      ).withOpacity(0.1),
                      Color(
                        int.parse(subject.color.replaceFirst('#', '0xff')),
                      ).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isFreePeriod ? Theme.of(context).colorScheme.surface : null,
            border: Border.all(
              color: !isFreePeriod
                  ? Color(
                      int.parse(subject!.color.replaceFirst('#', '0xff')),
                    ).withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: !isFreePeriod
                    ? Color(
                        int.parse(subject!.color.replaceFirst('#', '0xff')),
                      ).withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _editTimeSlot(slot),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Time indicator
                    Container(
                      width: 4,
                      height: 50,
                      decoration: BoxDecoration(
                        color: !isFreePeriod
                            ? Color(
                                int.parse(
                                  subject!.color.replaceFirst('#', '0xff'),
                                ),
                              )
                            : AppTheme.freeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Subject icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !isFreePeriod
                            ? Color(
                                int.parse(
                                  subject!.color.replaceFirst('#', '0xff'),
                                ),
                              ).withOpacity(0.1)
                            : AppTheme.freeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        !isFreePeriod
                            ? PhosphorIcons.book()
                            : PhosphorIcons.coffee(),
                        size: 20,
                        color: !isFreePeriod
                            ? Color(
                                int.parse(
                                  subject!.color.replaceFirst('#', '0xff'),
                                ),
                              )
                            : AppTheme.freeColor,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject name and time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  subject?.name ?? 'Free Period',
                                  style: AppTheme.subheadingTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: !isFreePeriod
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : AppTheme.freeColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: !isFreePeriod
                                      ? Color(
                                          int.parse(
                                            subject!.color.replaceFirst(
                                              '#',
                                              '0xff',
                                            ),
                                          ),
                                        ).withOpacity(0.1)
                                      : AppTheme.freeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  slot.timeRange,
                                  style: AppTheme.captionTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: !isFreePeriod
                                        ? Color(
                                            int.parse(
                                              subject!.color.replaceFirst(
                                                '#',
                                                '0xff',
                                              ),
                                            ),
                                          )
                                        : AppTheme.freeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Details
                          if (subject != null) ...[
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.user(),
                                  size: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  subject.teacherName,
                                  style: AppTheme.captionTextStyle.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            if (subject.classroom.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    PhosphorIcons.mapPin(),
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    subject.classroom,
                                    style: AppTheme.captionTextStyle.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                          if (slot.location != null && isFreePeriod) ...[
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.mapPin(),
                                  size: 14,
                                  color: AppTheme.freeColor.withOpacity(0.8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  slot.location!,
                                  style: AppTheme.captionTextStyle.copyWith(
                                    color: AppTheme.freeColor.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Actions menu
                    PopupMenuButton(
                      icon: Icon(
                        PhosphorIcons.dotsThreeVertical(),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.pencil(), size: 16),
                              const SizedBox(width: 8),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.trash(),
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editTimeSlot(slot);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(slot);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Create Timetable Dialog
class CreateTimetableDialog extends StatefulWidget {
  final Function(Timetable) onTimetableCreated;

  const CreateTimetableDialog({super.key, required this.onTimetableCreated});

  @override
  State<CreateTimetableDialog> createState() => _CreateTimetableDialogState();
}

class _CreateTimetableDialogState extends State<CreateTimetableDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Timetable'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Timetable Name',
            hintText: 'e.g. Semester 1',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a timetable name';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createTimetable,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createTimetable() async {
    if (_formKey.currentState!.validate()) {
      final timetable = Timetable(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        schedule: {},
        createdAt: DateTime.now(),
        isActive: true,
      );

      try {
        await StorageService.addTimetable(timetable);
        await StorageService.setActiveTimetable(timetable.id);
        widget.onTimetableCreated(timetable);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timetable created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating timetable: $e')),
          );
        }
      }
    }
  }
}

// Edit Time Slot Dialog
class EditTimeSlotDialog extends StatefulWidget {
  final List<Subject> subjects;
  final DayOfWeek dayOfWeek;
  final TimeSlot? existingSlot;
  final Function(TimeSlot) onSlotSaved;

  const EditTimeSlotDialog({
    super.key,
    required this.subjects,
    required this.dayOfWeek,
    this.existingSlot,
    required this.onSlotSaved,
  });

  @override
  State<EditTimeSlotDialog> createState() => _EditTimeSlotDialogState();
}

class _EditTimeSlotDialogState extends State<EditTimeSlotDialog> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    if (widget.existingSlot != null) {
      final slot = widget.existingSlot!;
      _startTime = TimeOfDay.fromDateTime(slot.startTime);
      _endTime = TimeOfDay.fromDateTime(slot.endTime);
      _selectedSubjectId = slot.subjectId;
      _locationController.text = slot.location ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingSlot != null ? 'Edit Time Slot' : 'Add Time Slot',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Debug warning when no subjects available
            if (widget.subjects.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No subjects found! Please add subjects first from the Subjects tab.',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Subject selection
            DropdownButtonFormField<String?>(
              value: _selectedSubjectId,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Free Period')),
                ...widget.subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject.id,
                    child: Text('${subject.name} - ${subject.teacherName}'),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubjectId = value;
                  // Auto-set duration based on subject type
                  if (value != null) {
                    final subject = widget.subjects.firstWhere(
                      (s) => s.id == value,
                    );
                    final duration = subject.duration;
                    final startDateTime = DateTime(
                      2000,
                      1,
                      1,
                      _startTime.hour,
                      _startTime.minute,
                    );
                    final endDateTime = startDateTime.add(duration);
                    _endTime = TimeOfDay.fromDateTime(endDateTime);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Time selection
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(_startTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (time != null) {
                        setState(() {
                          _startTime = time;
                          // Auto-adjust end time if subject is selected
                          if (_selectedSubjectId != null) {
                            final subject = widget.subjects.firstWhere(
                              (s) => s.id == _selectedSubjectId,
                            );
                            final duration = subject.duration;
                            final startDateTime = DateTime(
                              2000,
                              1,
                              1,
                              time.hour,
                              time.minute,
                            );
                            final endDateTime = startDateTime.add(duration);
                            _endTime = TimeOfDay.fromDateTime(endDateTime);
                          }
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(_endTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (time != null) {
                        setState(() {
                          _endTime = time;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                hintText: 'e.g. Room 101',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTimeSlot,
          child: Text(widget.existingSlot != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveTimeSlot() {
    // Validate time range
    final startDateTime = DateTime(
      2000,
      1,
      1,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(2000, 1, 1, _endTime.hour, _endTime.minute);

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final slot = TimeSlot(
      id:
          widget.existingSlot?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: startDateTime,
      endTime: endDateTime,
      subjectId: _selectedSubjectId,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      dayOfWeek: widget.dayOfWeek,
      createdAt: widget.existingSlot?.createdAt ?? DateTime.now(),
    );

    widget.onSlotSaved(slot);
    Navigator.of(context).pop();
  }
}
