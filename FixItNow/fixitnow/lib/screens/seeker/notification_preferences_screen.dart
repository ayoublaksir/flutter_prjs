import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user_models.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final UserAPI _userAPI = UserAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isSaving = false;

  // Notification preferences
  bool _bookingUpdates = true;
  bool _providerMessages = true;
  bool _promotions = false;
  bool _appUpdates = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load user settings
      final user = await _userAPI.getUserProfile(userId);
      if (user != null) {
        // Try to cast to ServiceSeeker to access settings
        if (user is ServiceSeeker) {
          final settings = user.settings;
          setState(() {
            _bookingUpdates =
                settings.notificationPreferences?['bookingUpdates'] ?? true;
            _providerMessages =
                settings.notificationPreferences?['providerMessages'] ?? true;
            _promotions =
                settings.notificationPreferences?['promotions'] ?? false;
            _appUpdates =
                settings.notificationPreferences?['appUpdates'] ?? true;
            _emailNotifications = settings.pushNotifications;
            _pushNotifications = settings.emailNotifications;
            _smsNotifications = settings.smsNotifications;
          });
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load notification preferences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationPreferences() async {
    setState(() => _isSaving = true);

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create updated settings
      final notificationPreferences = {
        'bookingUpdates': _bookingUpdates,
        'providerMessages': _providerMessages,
        'promotions': _promotions,
        'appUpdates': _appUpdates,
      };

      // Update user settings using the correct method
      await _userAPI.updateSeekerSettings(
        userId,
        UserSettings(
          pushNotifications: _pushNotifications,
          emailNotifications: _emailNotifications,
          smsNotifications: _smsNotifications,
          notificationPreferences: notificationPreferences,
        ),
      );

      Get.snackbar('Success', 'Notification preferences updated');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save notification preferences: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Preferences')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification types
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Booking Updates'),
                    subtitle: const Text('Notifications about your bookings'),
                    value: _bookingUpdates,
                    onChanged: (value) {
                      setState(() => _bookingUpdates = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Provider Messages'),
                    subtitle: const Text('Messages from service providers'),
                    value: _providerMessages,
                    onChanged: (value) {
                      setState(() => _providerMessages = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Promotions & Offers'),
                    subtitle: const Text('Special offers and discounts'),
                    value: _promotions,
                    onChanged: (value) {
                      setState(() => _promotions = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('App Updates'),
                    subtitle: const Text('Information about app updates'),
                    value: _appUpdates,
                    onChanged: (value) {
                      setState(() => _appUpdates = value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification channels
            Text(
              'Notification Channels',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    secondary: const Icon(Icons.email),
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() => _emailNotifications = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    secondary: const Icon(Icons.notifications),
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() => _pushNotifications = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('SMS Notifications'),
                    secondary: const Icon(Icons.sms),
                    value: _smsNotifications,
                    onChanged: (value) {
                      setState(() => _smsNotifications = value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info text
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'You must have at least one notification channel enabled to receive important updates about your bookings.',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveNotificationPreferences,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSaving
                        ? const CircularProgressIndicator()
                        : const Text('Save Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
