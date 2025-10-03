import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:attendence_tracker/services/backend_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BackendService _backendService = BackendService();
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = _backendService.currentUser;
    if (user != null) {
      // First try to get the display name from Firebase user
      String? name = user.displayName;

      // If not available, try to get it from Firestore
      if (name == null || name.isEmpty) {
        name = await _backendService.getUserName();
      }

      // If still not available, use the email as fallback
      if (name == null || name.isEmpty) {
        name = user.email;
      }

      setState(() {
        _userName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _backendService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(child: Icon(PhosphorIcons.user())),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName ?? 'Loading...',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email ?? 'No email',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await _backendService.signOut();
                  widget.onLogout();
                },
                icon: Icon(PhosphorIcons.signOut()),
                label: const Text('Sign Out'),
              ),
            ] else
              const Text('No user logged in'),
          ],
        ),
      ),
    );
  }
}
