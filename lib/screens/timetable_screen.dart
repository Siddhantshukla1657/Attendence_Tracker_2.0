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
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeTimetable == null
          ? _buildEmptyState()
          : Column(
              children: [
                // Day selector
                _buildDaySelector(),

                // Time slots
                Expanded(child: _buildTimeSlotsList()),
              ],
            ),
      floatingActionButton: _activeTimetable != null
          ? FloatingActionButton(
              onPressed: () => _editTimeSlot(null),
              child: Icon(PhosphorIcons.plus()),
            )
          : FloatingActionButton.extended(
              onPressed: _showCreateTimetableDialog,
              icon: Icon(PhosphorIcons.plus()),
              label: const Text('Create Timetable'),
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
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: DayOfWeek.values.length,
        itemBuilder: (context, index) {
          final day = DayOfWeek.values[index];
          final isSelected = day == _selectedDay;
          final daySlots = _activeTimetable?.getScheduleForDay(day) ?? [];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = day;
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.shortName,
                    style: AppTheme.bodyTextStyle.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${daySlots.length} slots',
                    style: AppTheme.captionTextStyle.copyWith(
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
            Icon(
              PhosphorIcons.calendarBlank(),
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _editTimeSlot(null),
              icon: Icon(PhosphorIcons.plus()),
              label: const Text('Add Time Slot'),
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

        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.smallPadding),
          child: ListTile(
            leading: Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: subject != null
                    ? Color(int.parse(subject.color.replaceFirst('#', '0xff')))
                    : AppTheme.freeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Text(
              subject?.name ?? 'Free Period',
              style: AppTheme.subheadingTextStyle.copyWith(
                color: subject != null ? null : AppTheme.freeColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.timeRange),
                if (subject != null) ...[
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
                if (slot.location != null && subject == null)
                  Text(
                    'Location: ${slot.location!}',
                    style: AppTheme.captionTextStyle,
                  ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: Icon(PhosphorIcons.dotsThreeVertical()),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.pencil()),
                      const SizedBox(width: 8),
                      const Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.trash(), color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Delete', style: TextStyle(color: Colors.red)),
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
