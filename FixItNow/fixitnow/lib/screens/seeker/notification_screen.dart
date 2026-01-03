import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/notification_models.dart';
import '../../routes.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationAPI _notificationAPI = NotificationAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  List<UserNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final notifications = await _notificationAPI.getUserNotifications(
          user.uid,
        );
        setState(() => _notifications = notifications);

        // Mark notifications as read
        _notificationAPI.markNotificationsAsRead(user.uid);
      }
    } catch (e) {
      print('Error loading notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading notifications')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _notificationAPI.clearAllNotifications(user.uid);
        setState(() => _notifications = []);
      }
    } catch (e) {
      print('Error clearing notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error clearing notifications')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'ll see notifications about your bookings and services here',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Dismissible(
                      key: Key(notification.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        try {
                          await _notificationAPI.deleteNotification(
                            notification.id,
                          );
                          setState(() {
                            _notifications.removeAt(index);
                          });
                        } catch (e) {
                          print('Error deleting notification: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error deleting notification'),
                            ),
                          );
                        }
                      },
                      child: ListTile(
                        leading: _getNotificationIcon(notification.type),
                        title: Text(notification.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.message),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'MMM d, y • h:mm a',
                              ).format(notification.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (notification.actionRoute != null) {
                            Navigator.pushNamed(
                              context,
                              notification.actionRoute!,
                              arguments: notification.actionArguments,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'booking':
        iconData = Icons.calendar_today;
        iconColor = Colors.blue;
        break;
      case 'payment':
        iconData = Icons.payment;
        iconColor = Colors.green;
        break;
      case 'chat':
        iconData = Icons.chat;
        iconColor = Colors.purple;
        break;
      case 'promotion':
        iconData = Icons.local_offer;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor),
    );
  }
}
