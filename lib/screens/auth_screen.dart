import 'package:flutter/material.dart';
import 'package:attendence_tracker/services/backend_service.dart';
import 'package:attendence_tracker/services/storage_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthScreen({super.key, required this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _backendService = BackendService();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true; // For toggling password visibility

  // Animation controller for loading
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    // Create animation
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        final user = await _backendService.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (user != null) {
          // Fetch data from backend after successful login
          await _fetchDataFromBackend();
          widget.onAuthSuccess();
        } else {
          _showError('Failed to sign in. Please check your credentials.');
        }
      } else {
        // For signup, we need to provide the name as well
        final user = await _backendService.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
        if (user != null) {
          widget.onAuthSuccess();
        } else {
          _showError('Failed to create account. Please try again.');
        }
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Fetch data from backend and update local storage
  Future<void> _fetchDataFromBackend() async {
    try {
      print('Fetching data from backend after login...');

      // Get data from backend
      final backendSubjects = await _backendService.getSubjects();
      final backendAttendance = await _backendService.getAttendanceRecords();
      final backendTimetables = await _backendService.getTimetables();

      // Update local storage with backend data
      await StorageService.saveSubjects(backendSubjects);
      await StorageService.saveAttendanceRecords(backendAttendance);
      await StorageService.saveTimetables(backendTimetables);

      print(
        'Local storage updated with backend data: '
        '${backendSubjects.length} subjects, '
        '${backendAttendance.length} attendance records, '
        '${backendTimetables.length} timetables',
      );
    } catch (e) {
      print('Error fetching data from backend: $e');
      // Continue with local data if fetch fails
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Adjust layout based on screen size
              final isWideScreen = constraints.maxWidth > 600;

              return Padding(
                padding: EdgeInsets.all(isWideScreen ? 32.0 : 24.0),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo/Title
                        Icon(
                          PhosphorIcons.calendarCheck(),
                          size: isWideScreen ? 100 : 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Attendance Tracker',
                          style: TextStyle(
                            fontSize: isWideScreen ? 32 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin
                              ? 'Sign in to your account'
                              : 'Create a new account',
                          style: TextStyle(
                            fontSize: isWideScreen ? 18 : 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Auth Card
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWideScreen ? 500 : double.infinity,
                          ),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                isWideScreen ? 32.0 : 24.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Name field (only shown during signup)
                                  if (!_isLogin) ...[
                                    TextField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: 'Full Name',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: Icon(PhosphorIcons.user()),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: Icon(PhosphorIcons.at()),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  // Password field with visibility toggle
                                  TextField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: Icon(PhosphorIcons.lock()),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? PhosphorIcons.eye()
                                              : PhosphorIcons.eyeSlash(),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    obscureText: _obscurePassword,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _isLoading
                                        ? AnimatedBuilder(
                                            animation: _animation,
                                            builder: (context, child) {
                                              return Container(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    RotationTransition(
                                                      turns: _animation,
                                                      child: Icon(
                                                        PhosphorIcons.spinner(),
                                                        size: 24,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    const Text('Processing...'),
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                        : ElevatedButton(
                                            onPressed: _submit,
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                vertical: isWideScreen
                                                    ? 18
                                                    : 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              _isLogin ? 'Sign In' : 'Sign Up',
                                              style: TextStyle(
                                                fontSize: isWideScreen
                                                    ? 18
                                                    : 16,
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLogin = !_isLogin;
                                        // Clear the name field when switching modes
                                        if (_isLogin) {
                                          _nameController.clear();
                                        }
                                      });
                                    },
                                    child: Text(
                                      _isLogin
                                          ? 'Don\'t have an account? Sign Up'
                                          : 'Already have an account? Sign In',
                                      style: TextStyle(
                                        fontSize: isWideScreen ? 16 : 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
