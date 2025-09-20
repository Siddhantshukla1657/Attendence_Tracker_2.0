import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/services/storage_service.dart';
import 'package:attendence_tracker/theme/app_theme.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('SubjectsScreen: initState called');
    _loadSubjects();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('SubjectsScreen: didChangeDependencies called');
    // Reload data when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('SubjectsScreen: Post frame callback - reloading subjects');
        _loadSubjects();
      }
    });
  }

  @override
  void didUpdateWidget(SubjectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('SubjectsScreen: didUpdateWidget called');
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);

    try {
      _subjects = await StorageService.getSubjects();
      print('SubjectsScreen: Loaded ${_subjects.length} subjects');
      for (final subject in _subjects) {
        print(
          'Subject loaded: ${subject.name} - ${subject.teacherName} (${subject.id})',
        );
      }
    } catch (e) {
      print('SubjectsScreen: Error loading subjects: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading subjects: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method that can be called externally to force refresh
  void forceRefresh() {
    print('SubjectsScreen: forceRefresh called');
    _loadSubjects();
  }

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSubjectDialog(
        onSubjectAdded: (subject) {
          setState(() {
            _subjects.add(subject);
          });
        },
      ),
    );
  }

  void _showSubjectOptions(Subject subject) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PhosphorIcons.pencil()),
              title: const Text('Edit Subject'),
              onTap: () {
                Navigator.pop(context);
                _showEditSubjectDialog(subject);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.trash(), color: Colors.red),
              title: const Text('Delete Subject'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(subject);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubjectDialog(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => EditSubjectDialog(
        subject: subject,
        onSubjectUpdated: (updatedSubject) {
          setState(() {
            final index = _subjects.indexWhere((s) => s.id == subject.id);
            if (index != -1) {
              _subjects[index] = updatedSubject;
            }
          });
        },
      ),
    );
  }

  void _showDeleteConfirmation(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to delete "${subject.name}"?\n\nThis will also delete all related attendance records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSubject(subject);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(Subject subject) async {
    try {
      await StorageService.deleteSubject(subject.id);
      setState(() {
        _subjects.removeWhere((s) => s.id == subject.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting subject: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
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
                    'No subjects added yet',
                    style: AppTheme.bodyTextStyle.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddSubjectDialog,
                    icon: Icon(PhosphorIcons.plus()),
                    label: const Text('Add Subject'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Category tabs
                Container(
                  margin: const EdgeInsets.all(AppTheme.defaultPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCategoryTab(
                          'Lectures',
                          SubjectType.lecture,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCategoryTab('Labs', SubjectType.lab),
                      ),
                    ],
                  ),
                ),

                // Subjects list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.defaultPadding,
                    ),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: AppTheme.smallPadding,
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  subject.color.replaceFirst('#', '0xff'),
                                ),
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(subject.name),
                          subtitle: Text(
                            'Teacher: ${subject.teacherName}\nClassroom: ${subject.classroom}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                  subject.type == SubjectType.lecture
                                      ? 'Lecture (1h)'
                                      : 'Lab (2h)',
                                  style: AppTheme.captionTextStyle.copyWith(
                                    color: AppTheme.getSubjectTypeColor(
                                      subject.type.toString(),
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(PhosphorIcons.dotsThreeVertical()),
                                onPressed: () => _showSubjectOptions(subject),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        child: Icon(PhosphorIcons.plus()),
      ),
    );
  }

  Widget _buildCategoryTab(String label, SubjectType type) {
    final count = _subjects.where((s) => s.type == type).length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.bodyTextStyle.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$count subjects',
            style: AppTheme.captionTextStyle.copyWith(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showStorageInfo() async {
    final info = await StorageService.getStorageInfo();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subjects: ${info['subjects_count']}'),
              Text('Attendance Records: ${info['attendance_records_count']}'),
              Text('Timetables: ${info['timetables_count']}'),
              Text('Data Version: ${info['data_version']}'),
              Text('Has Backup: ${info['has_backup'] ? 'Yes' : 'No'}'),
              if (info['last_backup'] != null)
                Text(
                  'Last Backup: ${DateTime.parse(info['last_backup']).toString().split('.')[0]}',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

class AddSubjectDialog extends StatefulWidget {
  final Function(Subject) onSubjectAdded;

  const AddSubjectDialog({super.key, required this.onSubjectAdded});

  @override
  State<AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _classroomController = TextEditingController();
  SubjectType _selectedType = SubjectType.lecture;
  String _selectedColor = '#2196F3';

  final List<String> _colors = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#9C27B0',
    '#F44336',
    '#009688',
    '#795548',
    '#607D8B',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Add Subject',
                    style: AppTheme.headingTextStyle.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                          hintText: 'e.g. Data Structures',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter subject name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _teacherController,
                        decoration: const InputDecoration(
                          labelText: 'Teacher Name',
                          hintText: 'e.g. Dr. Smith',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter teacher name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _classroomController,
                        decoration: const InputDecoration(
                          labelText: 'Classroom',
                          hintText: 'e.g. Room 101, Lab A',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter classroom location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SubjectType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Subject Type',
                          border: OutlineInputBorder(),
                        ),
                        items: SubjectType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type == SubjectType.lecture
                                  ? 'Lecture (1 hour)'
                                  : 'Lab (2 hours)',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Color picker
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Color:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _colors.map((color) {
                          final isSelected = color == _selectedColor;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(color.replaceFirst('#', '0xff')),
                                ),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.black, width: 3)
                                    : Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1,
                                      ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      PhosphorIcons.check(),
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveSubject,
                    child: const Text('Add Subject'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSubject() async {
    if (_formKey.currentState!.validate()) {
      final subject = Subject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        teacherName: _teacherController.text.trim(),
        classroom: _classroomController.text.trim(),
        type: _selectedType,
        color: _selectedColor,
        createdAt: DateTime.now(),
      );

      print(
        'AddSubjectDialog: Attempting to save subject: ${subject.name} - ${subject.teacherName}',
      );

      try {
        await StorageService.addSubject(subject);
        print('AddSubjectDialog: Subject saved successfully');
        widget.onSubjectAdded(subject);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject added successfully')),
          );
        }
      } catch (e) {
        print('AddSubjectDialog: Error saving subject: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding subject: $e')));
        }
      }
    }
  }
}

class EditSubjectDialog extends StatefulWidget {
  final Subject subject;
  final Function(Subject) onSubjectUpdated;

  const EditSubjectDialog({
    super.key,
    required this.subject,
    required this.onSubjectUpdated,
  });

  @override
  State<EditSubjectDialog> createState() => _EditSubjectDialogState();
}

class _EditSubjectDialogState extends State<EditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _teacherController;
  late final TextEditingController _classroomController;
  late SubjectType _selectedType;
  late String _selectedColor;

  final List<String> _colors = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#9C27B0',
    '#F44336',
    '#009688',
    '#795548',
    '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject.name);
    _teacherController = TextEditingController(
      text: widget.subject.teacherName,
    );
    _classroomController = TextEditingController(
      text: widget.subject.classroom,
    );
    _selectedType = widget.subject.type;
    _selectedColor = widget.subject.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Edit Subject',
                    style: AppTheme.headingTextStyle.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                          hintText: 'e.g. Data Structures',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter subject name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _teacherController,
                        decoration: const InputDecoration(
                          labelText: 'Teacher Name',
                          hintText: 'e.g. Dr. Smith',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter teacher name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _classroomController,
                        decoration: const InputDecoration(
                          labelText: 'Classroom',
                          hintText: 'e.g. Room 101, Lab A',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter classroom location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SubjectType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Subject Type',
                          border: OutlineInputBorder(),
                        ),
                        items: SubjectType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type == SubjectType.lecture
                                  ? 'Lecture (1 hour)'
                                  : 'Lab (2 hours)',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Color picker
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Color:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _colors.map((color) {
                          final isSelected = color == _selectedColor;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(color.replaceFirst('#', '0xff')),
                                ),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.black, width: 3)
                                    : Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1,
                                      ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      PhosphorIcons.check(),
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _updateSubject,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSubject() async {
    if (_formKey.currentState!.validate()) {
      final updatedSubject = widget.subject.copyWith(
        name: _nameController.text.trim(),
        teacherName: _teacherController.text.trim(),
        classroom: _classroomController.text.trim(),
        type: _selectedType,
        color: _selectedColor,
      );

      print('EditSubjectDialog: Updating subject: ${updatedSubject.name}');

      try {
        await StorageService.updateSubject(updatedSubject);
        print('EditSubjectDialog: Subject updated successfully');
        widget.onSubjectUpdated(updatedSubject);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject updated successfully')),
          );
        }
      } catch (e) {
        print('EditSubjectDialog: Error updating subject: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating subject: $e')));
        }
      }
    }
  }
}
