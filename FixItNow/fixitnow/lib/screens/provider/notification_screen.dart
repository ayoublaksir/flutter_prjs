import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/notification_models.dart';
import '../../routes.dart';

class ProviderNotificationsScreen extends StatefulWidget {
  const ProviderNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<ProviderNotificationsScreen> createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState
    extends State<ProviderNotificationsScreen> {
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
        final notifications = await _notificationAPI.getNotifications(user.uid);
        setState(() => _notifications = notifications);

        // Mark all as read
        _notificationAPI.markAllAsRead(user.uid);
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

  void _handleNotificationTap(UserNotification notification) {
    switch (notification.type) {
      case 'booking_request':
        Navigator.pushNamed(
          context,
          AppRoutes.bookingDetails,
          arguments: {'bookingId': notification.data['bookingId']},
        );
        break;
      case 'review':
        Navigator.pushNamed(context, AppRoutes.reviews);
        break;
      case 'payment':
        Navigator.pushNamed(context, AppRoutes.earnings);
        break;
      default:
        // Handle other notification types
        break;
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
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Clear All'),
                        content: const Text(
                          'Are you sure you want to clear all notifications?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  final user = _authService.currentUser;
                  if (user != null) {
                    await _notificationAPI.clearAllNotifications(user.uid);
                    setState(() => _notifications.clear());
                  }
                }
              },
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
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text('No notifications'),
                  ],
                ),
              )
              : ListView.builder(
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
                      await _notificationAPI.deleteNotification(
                        notification.id,
                      );
                      setState(() {
                        _notifications.removeAt(index);
                      });
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getNotificationColor(
                          notification.type,
                        ),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(notification.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.message),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      onTap: () => _handleNotificationTap(notification),
                    ),
                  );
                },
              ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking_request':
        return Colors.blue;
      case 'review':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.calendar_today;
      case 'review':
        return Icons.star;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
