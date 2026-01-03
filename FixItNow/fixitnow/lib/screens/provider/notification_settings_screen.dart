// screens/provider/notification_settings_screen.dart
// Provider notification settings screen

import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final UserAPI _userAPI = UserAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  Map<String, bool> _notificationSettings = {
    'bookingRequests': true,
    'bookingUpdates': true,
    'messages': true,
    'payments': true,
    'promotions': false,
    'appUpdates': true,
  };

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load notification settings from API
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Manage which notifications you receive',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const Divider(),

                  SwitchListTile(
                    title: const Text('Booking Requests'),
                    subtitle: const Text(
                      'Notifications for new booking requests',
                    ),
                    value: _notificationSettings['bookingRequests'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _notificationSettings['bookingRequests'] = value;
                      });
                    },
                  ),

                  const Divider(),

                  SwitchListTile(
                    title: const Text('Booking Updates'),
                    subtitle: const Text(
                      'Notifications for changes to your bookings',
                    ),
                    value: _notificationSettings['bookingUpdates'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _notificationSettings['bookingUpdates'] = value;
                      });
                    },
                  ),

                  const Divider(),

                  SwitchListTile(
                    title: const Text('Messages'),
                    subtitle: const Text('Notifications for new messages'),
                    value: _notificationSettings['messages'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _notificationSettings['messages'] = value;
                      });
                    },
                  ),

                  const Divider(),

                  SwitchListTile(
                    title: const Text('Payments'),
                    subtitle: const Text(
                      'Notifications for payments and earnings',
                    ),
                    value: _notificationSettings['payments'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _notificationSettings['payments'] = value;
                      });
                    },
                  ),

                  const Divider(),

                  SwitchListTile(
                    title: const Text('Promotions'),
                    subtitle: const Text(
                      'Marketing and promotional notifications',
                    ),
                    value: _notificationSettings['promotions'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _notificationSettings['promotions'] = value;
                      });
                    },
                  ),

                  const Divider(),

                  SwitchListTile(
                    title: const Text('App Updates'),
                    subtitle: const Text(
                      'Notifications about app updates and new features',
                    ),
                    value: _notificationSettings['appUpdates'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _notificationSettings['appUpdates'] = value;
                      });
                    },
                  ),

                  const Divider(),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Save notification settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings saved'),
                          ),
                        );
                      },
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
    );
  }
}
