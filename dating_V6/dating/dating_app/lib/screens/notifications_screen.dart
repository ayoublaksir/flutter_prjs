import 'package:flutter/material.dart';
import '../widgets/modern_app_bar.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _authService = AuthService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      // Placeholder for actual notification loading
      // Replace with your actual notification service
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _notifications = [
          NotificationModel(
            id: '1',
            title: 'New Match!',
            message: 'You have a new match with Sarah',
            timestamp: DateTime.now().subtract(Duration(minutes: 5)),
            isRead: false,
            type: NotificationType.match,
            relatedId: 'user123',
          ),
          NotificationModel(
            id: '2',
            title: 'Date Offer Response',
            message: 'John is interested in your coffee date offer',
            timestamp: DateTime.now().subtract(Duration(hours: 2)),
            isRead: true,
            type: NotificationType.dateOffer,
            relatedId: 'offer456',
          ),
          NotificationModel(
            id: '3',
            title: 'New Message',
            message: 'You have a new message from Emma',
            timestamp: DateTime.now().subtract(Duration(days: 1)),
            isRead: false,
            type: NotificationType.message,
            relatedId: 'chat789',
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(title: 'Notifications', showNotifications: false),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We\'ll notify you when something happens',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationTile(notification);
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            notification.isRead
                ? Colors.grey[200]
                : Theme.of(context).colorScheme.primary.withOpacity(0.2),
        child: Icon(
          _getNotificationIcon(notification.type),
          color:
              notification.isRead
                  ? Colors.grey[600]
                  : Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.message),
          SizedBox(height: 4),
          Text(
            _formatTimestamp(notification.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      onTap: () => _handleNotificationTap(notification),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.match:
        return Icons.favorite;
      case NotificationType.dateOffer:
        return Icons.calendar_today;
      case NotificationType.message:
        return Icons.chat;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    setState(() {
      notification.isRead = true;
    });

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.match:
        Navigator.pushNamed(
          context,
          '/user_profile',
          arguments: notification.relatedId,
        );
        break;
      case NotificationType.dateOffer:
        Navigator.pushNamed(
          context,
          '/date_offer_details',
          arguments: notification.relatedId,
        );
        break;
      case NotificationType.message:
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: notification.relatedId,
        );
        break;
      default:
        break;
    }
  }
}

// Add this enum to your notification_model.dart file
enum NotificationType { match, dateOffer, message, system }

// Add this class to your notification_model.dart file
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;
  final String relatedId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    required this.relatedId,
  });
}
