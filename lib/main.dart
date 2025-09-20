import 'package:flutter/material.dart';
import 'package:attendence_tracker/theme/app_theme.dart';
import 'package:attendence_tracker/services/storage_service.dart';
import 'package:attendence_tracker/services/navigation_service.dart';
import 'package:attendence_tracker/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage with enhanced persistence
  try {
    await StorageService.init();
    print('Storage initialized successfully');
  } catch (e) {
    print('Storage initialization error: $e');
    // Even if there's an error, we'll continue with the app
    // The storage service has recovery mechanisms
  }

  runApp(const AttendanceTrackerApp());
}

class AttendanceTrackerApp extends StatefulWidget {
  const AttendanceTrackerApp({super.key});

  @override
  State<AttendanceTrackerApp> createState() => _AttendanceTrackerAppState();
}

class _AttendanceTrackerAppState extends State<AttendanceTrackerApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final isDark = await StorageService.isDarkMode();
    setState(() {
      _isDarkMode = isDark;
    });
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await StorageService.setDarkMode(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Tracker',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}
