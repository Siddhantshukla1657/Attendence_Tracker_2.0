import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:attendence_tracker/screens/schedule_screen.dart';
import 'package:attendence_tracker/screens/attendance_screen.dart';
import 'package:attendence_tracker/screens/subjects_screen.dart';
import 'package:attendence_tracker/screens/timetable_screen.dart';
import 'package:attendence_tracker/screens/reports_screen.dart';
import 'package:attendence_tracker/screens/attendance_history_screen.dart';
import 'package:attendence_tracker/screens/profile_screen.dart';
import 'package:attendence_tracker/screens/auth_screen.dart';
import 'package:attendence_tracker/services/backend_service.dart';
import 'package:attendence_tracker/services/storage_service.dart';

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
  bool _isAuthenticated = false;
  final BackendService _backendService = BackendService();

  final List<GlobalKey> _screenKeys = [
    GlobalKey(), // Schedule
    GlobalKey(), // Attendance
    GlobalKey(), // Subjects
    GlobalKey(), // Timetable
    GlobalKey(), // History
    GlobalKey(), // Reports
    GlobalKey(), // Profile
  ];

  List<Widget> get _screens => [
        ScheduleScreen(key: _screenKeys[0]),
        AttendanceScreen(key: _screenKeys[1]),
        SubjectsScreen(key: _screenKeys[2]),
        TimetableScreen(key: _screenKeys[3]),
        AttendanceHistoryScreen(key: _screenKeys[4]),
        ReportsScreen(key: _screenKeys[5]),
        ProfileScreen(
          key: _screenKeys[6],
          onLogout: () {
            setState(() {
              _isAuthenticated = false;
            });
          },
        ),
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
    BottomNavigationBarItem(
      icon: Icon(PhosphorIcons.user()),
      activeIcon: Icon(PhosphorIcons.user(PhosphorIconsStyle.fill)),
      label: 'Profile',
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
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    setState(() {
      _isAuthenticated = _backendService.isAuthenticated;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If Firebase is not available or user is not authenticated, show a simplified version
    if (!_isAuthenticated) {
      return AuthScreen(
        onAuthSuccess: () async {
          // Force sync with backend after successful login
          try {
            await StorageService.forceSyncWithBackend();
            print('Data synced successfully after login');
          } catch (e) {
            print('Failed to sync data after login: $e');
          }
          
          setState(() {
            _isAuthenticated = true;
          });
          
          // Refresh all screens to show the new data
          _refreshCurrentScreen();
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if we're on a wide screen (web/desktop)
        final isWideScreen = constraints.maxWidth > 600;
        
        if (isWideScreen) {
          // For web/desktop, use a responsive layout with side navigation
          return _buildWebLayout(context);
        } else {
          // For mobile, use the standard layout with bottom navigation
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // Build layout for web/desktop
  Widget _buildWebLayout(BuildContext context) {
    // Create navigation destinations dynamically to avoid const evaluation issues
    final destinations = [
      NavigationRailDestination(
        icon: Icon(PhosphorIcons.calendar()),
        selectedIcon: Icon(PhosphorIcons.calendar(PhosphorIconsStyle.fill)),
        label: Text('Schedule'),
      ),
      NavigationRailDestination(
        icon: Icon(PhosphorIcons.checkSquare()),
        selectedIcon: Icon(PhosphorIcons.checkSquare(PhosphorIconsStyle.fill)),
        label: Text('Attendance'),
      ),
      NavigationRailDestination(
        icon: Icon(PhosphorIcons.books()),
        selectedIcon: Icon(PhosphorIcons.books(PhosphorIconsStyle.fill)),
        label: Text('Subjects'),
      ),
      NavigationRailDestination(
        icon: Icon(PhosphorIcons.clock()),
        selectedIcon: Icon(PhosphorIcons.clock(PhosphorIconsStyle.fill)),
        label: Text('Timetable'),
      ),
      NavigationRailDestination(
        icon: Icon(PhosphorIcons.clockCounterClockwise()),
        selectedIcon: Icon(PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill)),
        label: Text('History'),
      ),
      NavigationRailDestination(
        icon: Icon(PhosphorIcons.chartBar()),
        selectedIcon: Icon(PhosphorIcons.chartBar(PhosphorIconsStyle.fill)),
        label: Text('Reports'),
      ),
      NavigationRailDestination(
        icon: Icon(PhosphorIcons.user()),
        selectedIcon: Icon(PhosphorIcons.user(PhosphorIconsStyle.fill)),
        label: Text('Profile'),
      ),
    ];

    // Create app bar actions dynamically
    final appBarActions = [
      IconButton(
        icon: Icon(PhosphorIcons.arrowsClockwise()),
        onPressed: _syncData,
        tooltip: 'Sync data',
      ),
      IconButton(
        icon: Icon(
          widget.isDarkMode ? PhosphorIcons.sun() : PhosphorIcons.moon(),
        ),
        onPressed: widget.onThemeToggle,
        tooltip: 'Toggle theme',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        actions: appBarActions,
      ),
      body: Row(
        children: [
          // Side navigation
          SizedBox(
            width: 250,
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                _refreshCurrentScreen();
              },
              labelType: NavigationRailLabelType.all,
              destinations: destinations,
            ),
          ),
          // Content area
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  // Build layout for mobile
  Widget _buildMobileLayout(BuildContext context) {
    // Create app bar actions dynamically
    final appBarActions = [
      IconButton(
        icon: Icon(PhosphorIcons.arrowsClockwise()),
        onPressed: _syncData,
        tooltip: 'Sync data',
      ),
      IconButton(
        icon: Icon(
          widget.isDarkMode ? PhosphorIcons.sun() : PhosphorIcons.moon(),
        ),
        onPressed: widget.onThemeToggle,
        tooltip: 'Toggle theme',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        actions: appBarActions,
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

  // Sync data with backend - enhanced version
  Future<void> _syncData() async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Syncing data...'),
                ],
              ),
            );
          },
        );
      }

      // Sync with backend bidirectionally
      await StorageService.syncWithBackend(bidirectional: true);

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Refresh current screen
      _refreshCurrentScreen();
    } catch (e) {
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}