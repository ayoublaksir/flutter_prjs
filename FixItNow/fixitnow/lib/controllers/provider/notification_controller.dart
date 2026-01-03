import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/notification_models.dart';
import '../../services/api_services.dart';
import '../../services/notification_services.dart';
import '../base_controller.dart';

class NotificationController extends BaseController {
  // Services via dependency injection
  final PushNotificationService _notificationServices =
      Get.find<PushNotificationService>();
  final NotificationAPI _notificationAPI = Get.find<NotificationAPI>();

  // Reactive state
  final RxList<UserNotification> notifications = <UserNotification>[].obs;
  final RxList<UserNotification> unreadNotifications = <UserNotification>[].obs;
  final RxInt unreadCount = 0.obs;

  // Filter state
  final RxString filter = 'all'.obs; // all, bookings, messages, system

  @override
  void onInit() {
    super.onInit();
    loadNotifications();

    // Set up notifications listener for real-time updates
    _setupNotificationsListener();
  }

  /// Load notifications
  Future<void> loadNotifications() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Get notifications from API
      final allNotifications = await _notificationAPI.getUserNotifications(
        userId,
      );

      // Apply filter if needed
      final filteredNotifications = _filterNotifications(allNotifications);
      notifications.value = filteredNotifications;

      // Update unread notifications
      final unread = filteredNotifications.where((n) => !n.isRead).toList();
      unreadNotifications.value = unread;
      unreadCount.value = unread.length;
    });
  }

  /// Set up notifications listener for real-time updates
  void _setupNotificationsListener() {
    _notificationServices.subscribeToUserNotifications(
      userId: currentUserId,
      onNotification: (notification) {
        // Add to the list if not already exists
        if (!notifications.any((n) => n.id == notification.id)) {
          notifications.insert(0, notification);

          // Update unread count
          if (!notification.isRead) {
            unreadNotifications.add(notification);
            unreadCount.value++;
          }

          // Show in-app notification if it's a new one
          _showInAppNotification(notification);
        }
      },
    );
  }

  /// Show in-app notification
  void _showInAppNotification(UserNotification notification) {
    Get.snackbar(
      notification.title,
      notification.message,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      borderRadius: 8,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      onTap: (_) {
        // Mark as read and navigate
        markNotificationAsRead(notification.id);
        _handleNotificationTap(notification);
      },
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(UserNotification notification) {
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.booking:
        if (notification.data['bookingId'] != null) {
          Get.toNamed(
            '/booking-details',
            arguments: {'bookingId': notification.data['bookingId']},
          );
        }
        break;
      case NotificationType.message:
        if (notification.data['senderId'] != null) {
          Get.toNamed(
            '/chat',
            arguments: {'userId': notification.data['senderId']},
          );
        }
        break;
      case NotificationType.payment:
        Get.toNamed('/earnings');
        break;
      default:
        break;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) {
    return runWithLoading(() async {
      await _notificationServices.markNotificationAsRead(notificationId);

      // Update local state
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updated = notifications[index].copyWith(isRead: true);
        notifications[index] = updated;
      }

      // Update unread notifications
      unreadNotifications.removeWhere((n) => n.id == notificationId);
      unreadCount.value = unreadNotifications.length;
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      await _notificationServices.markAllNotificationsAsRead(userId);

      // Update local state
      final updated =
          notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifications.value = updated;

      // Clear unread notifications
      unreadNotifications.clear();
      unreadCount.value = 0;

      showSuccess('All notifications marked as read');
    });
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) {
    return runWithLoading(() async {
      await _notificationAPI.deleteNotification(notificationId);

      // Update local state
      notifications.removeWhere((n) => n.id == notificationId);

      // Update unread notifications if needed
      final wasUnread = unreadNotifications.any((n) => n.id == notificationId);
      if (wasUnread) {
        unreadNotifications.removeWhere((n) => n.id == notificationId);
        unreadCount.value = unreadNotifications.length;
      }

      showSuccess('Notification deleted');
    });
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      await _notificationAPI.clearAllNotifications(userId);

      // Update local state
      notifications.clear();
      unreadNotifications.clear();
      unreadCount.value = 0;

      showSuccess('All notifications cleared');
    });
  }

  /// Change filter
  void changeFilter(String newFilter) {
    if (filter.value == newFilter) return;

    filter.value = newFilter;
    loadNotifications();
  }

  /// Filter notifications based on the current filter
  List<UserNotification> _filterNotifications(
    List<UserNotification> allNotifications,
  ) {
    switch (filter.value) {
      case 'bookings':
        return allNotifications
            .where((n) => n.type == NotificationType.booking)
            .toList();
      case 'messages':
        return allNotifications
            .where((n) => n.type == NotificationType.message)
            .toList();
      case 'all':
      default:
        return allNotifications;
    }
  }

  /// Get notification icon based on type
  IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.calendar_today;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.payment:
        return Icons.attach_money;
      default:
        return Icons.notifications;
    }
  }

  /// Get notification color based on type
  Color getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Colors.blue;
      case NotificationType.message:
        return Colors.green;
      case NotificationType.payment:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Format relative time (e.g. "2 hours ago")
  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
