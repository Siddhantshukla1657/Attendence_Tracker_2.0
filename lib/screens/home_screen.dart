import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:attendence_tracker/screens/schedule_screen.dart';
import 'package:attendence_tracker/screens/attendance_screen.dart';
import 'package:attendence_tracker/screens/subjects_screen.dart';
import 'package:attendence_tracker/screens/timetable_screen.dart';
import 'package:attendence_tracker/screens/reports_screen.dart';
import 'package:attendence_tracker/screens/attendance_history_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<GlobalKey> _screenKeys = [
    GlobalKey(), // Schedule
    GlobalKey(), // Attendance
    GlobalKey(), // Subjects
    GlobalKey(), // Timetable
    GlobalKey(), // History
    GlobalKey(), // Reports
  ];

  List<Widget> get _screens => [
    ScheduleScreen(key: _screenKeys[0]),
    AttendanceScreen(key: _screenKeys[1]),
    SubjectsScreen(key: _screenKeys[2]),
    TimetableScreen(key: _screenKeys[3]),
    AttendanceHistoryScreen(key: _screenKeys[4]),
    ReportsScreen(key: _screenKeys[5]),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(PhosphorIcons.calendar()),
      activeIcon: Icon(PhosphorIcons.calendar(PhosphorIconsStyle.fill)),
      label: 'Schedule',
    ),
    BottomNavigationBarItem(
      icon: Icon(PhosphorIcons.checkSquare()),
      activeIcon: Icon(PhosphorIcons.checkSquare(PhosphorIconsStyle.fill)),
      label: 'Attendance',
    ),
    BottomNavigationBarItem(
      icon: Icon(PhosphorIcons.books()),
      activeIcon: Icon(PhosphorIcons.books(PhosphorIconsStyle.fill)),
      label: 'Subjects',
    ),
    BottomNavigationBarItem(
      icon: Icon(PhosphorIcons.clock()),
      activeIcon: Icon(PhosphorIcons.clock(PhosphorIconsStyle.fill)),
      label: 'Timetable',
    ),
    BottomNavigationBarItem(
      icon: Icon(PhosphorIcons.clockCounterClockwise()),
      activeIcon: Icon(
        PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
      ),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Icon(PhosphorIcons.chartBar()),
      activeIcon: Icon(PhosphorIcons.chartBar(PhosphorIconsStyle.fill)),
      label: 'Reports',
    ),
  ];

  void _refreshCurrentScreen() {
    // Force refresh by rebuilding the current screen
    print('HomeScreen: Refreshing screen at index $_selectedIndex');

    // Force rebuild by updating the state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // This will cause all screens to rebuild with fresh data
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? PhosphorIcons.sun() : PhosphorIcons.moon(),
            ),
            onPressed: widget.onThemeToggle,
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          print('HomeScreen: Switching to tab $index');
          setState(() {
            _selectedIndex = index;
          });
          // Trigger refresh after switching
          _refreshCurrentScreen();
        },
        items: _bottomNavItems,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        iconSize: 20,
      ),
    );
  }
}
