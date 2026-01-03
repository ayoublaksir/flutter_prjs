import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/booking_models.dart';
import '../../models/provider_models.dart';
import '../../models/notification_models.dart';
import '../../models/user_models.dart';
import '../../services/api_services.dart';
import '../../services/notification_services.dart';
import '../base_controller.dart';
import '../../models/app_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderHomeController extends BaseController {
  // Services via dependency injection
  final BookingAPI _bookingAPI = Get.find<BookingAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();
  final PushNotificationService _notificationServices =
      Get.find<PushNotificationService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive state
  final Rx<ServiceProvider?> providerProfile = Rx<ServiceProvider?>(null);
  final RxList<Booking> upcomingBookings = <Booking>[].obs;
  final RxList<UserNotification> notifications = <UserNotification>[].obs;
  final RxInt pendingBookingCount = 0.obs;
  final RxInt unreadNotificationCount = 0.obs;
  final Rx<ProviderStats> providerStats =
      ProviderStats(
        totalEarnings: 0,
        totalBookings: 0,
        completedBookings: 0,
        cancelledBookings: 0,
        pendingBookings: 0,
        rating: 0,
        totalReviews: 0,
      ).obs;

  // Navigation
  final RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadHomeData();

    // Set up notification listener
    _setupNotificationListener();
  }

  /// Load home screen data
  Future<void> loadHomeData() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Load data in parallel
      await Future.wait([
        _loadProviderProfile(),
        _loadUpcomingBookings(),
        _loadNotifications(),
        _loadStats(),
      ]);
    });
  }

  /// Set up notification listener
  void _setupNotificationListener() {
    _notificationServices.subscribeToUserNotifications(
      userId: currentUserId,
      onNotification: (notification) {
        // Add to notifications list if not already there
        if (!notifications.any((n) => n.id == notification.id)) {
          notifications.insert(0, notification);

          // Update unread count
          if (!notification.isRead) {
            unreadNotificationCount.value++;
          }

          // Show in-app notification
          _showInAppNotification(notification);

          // If it's a booking notification, refresh bookings
          if (notification.type == NotificationType.booking) {
            _loadUpcomingBookings();
            _loadStats();
          }
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
        // Handle notification tap
        _handleNotificationTap(notification);
      },
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(UserNotification notification) {
    // Mark as read
    _markNotificationAsRead(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.booking:
        Get.toNamed('/booking-requests');
        break;
      case NotificationType.message:
        Get.toNamed(
          '/provider-chat',
          arguments: {'seekerId': notification.data['senderId']},
        );
        break;
      case NotificationType.payment:
        Get.toNamed('/earnings');
        break;
      case NotificationType.review:
        Get.toNamed('/reviews');
        break;
      default:
        break;
    }
  }

  /// Mark notification as read
  Future<void> _markNotificationAsRead(String notificationId) async {
    await _notificationServices.markNotificationAsRead(notificationId);

    // Update local state
    final notificationIndex = notifications.indexWhere(
      (n) => n.id == notificationId,
    );
    if (notificationIndex != -1) {
      final notification = notifications[notificationIndex];
      if (!notification.isRead) {
        final updatedNotification = notification.copyWith(isRead: true);
        notifications[notificationIndex] = updatedNotification;
        unreadNotificationCount.value--;
      }
    }
  }

  /// Load provider profile
  Future<void> _loadProviderProfile() async {
    final userId = currentUserId;
    if (userId.isEmpty) return;

    final profile = await _userAPI.getProviderProfile(userId);
    providerProfile.value = profile;
  }

  /// Load upcoming bookings
  Future<void> _loadUpcomingBookings() async {
    final userId = currentUserId;
    if (userId.isEmpty) return;

    final bookings = await _bookingAPI.getUpcomingBookings(
      providerId: userId,
      limit: 5,
    );
    upcomingBookings.value = bookings;

    // Count pending bookings
    pendingBookingCount.value = await _bookingAPI.getPendingBookingCount(
      providerId: userId,
    );
  }

  /// Load notifications
  Future<void> _loadNotifications() async {
    final userId = currentUserId;
    if (userId.isEmpty) return;

    final snapshot =
        await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();

    final userNotifications =
        snapshot.docs
            .map(
              (doc) => UserNotification.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();

    notifications.value = userNotifications;

    // Count unread notifications
    unreadNotificationCount.value =
        userNotifications.where((n) => !n.isRead).length;
  }

  /// Load provider stats
  Future<void> _loadStats() async {
    final userId = currentUserId;
    if (userId.isEmpty) return;

    final stats = await _bookingAPI.getProviderStats(userId);
    providerStats.value = stats;
  }

  /// Handle bottom navigation bar taps
  void changePage(int index) {
    if (index == currentIndex.value) return;

    currentIndex.value = index;

    // Navigate based on index
    switch (index) {
      case 0: // Home
        Get.offAllNamed('/provider-home');
        break;
      case 1: // Bookings
        Get.toNamed('/booking-requests');
        break;
      case 2: // Messages
        Get.toNamed('/provider-messages');
        break;
      case 3: // Profile
        Get.toNamed('/provider-profile');
        break;
    }
  }

  /// Accept a booking
  Future<void> acceptBooking(String bookingId) {
    return runWithLoading(() async {
      await _bookingAPI.updateBookingStatus(
        bookingId: bookingId,
        status: BookingStatus.accepted.name,
      );

      // Refresh data
      await Future.wait([_loadUpcomingBookings(), _loadStats()]);

      showSuccess('Booking accepted');
    });
  }

  /// Decline a booking
  Future<void> declineBooking(String bookingId) {
    return runWithLoading(() async {
      await _bookingAPI.updateBookingStatus(
        bookingId: bookingId,
        status: BookingStatus.declined.name,
      );

      // Refresh data
      await Future.wait([_loadUpcomingBookings(), _loadStats()]);

      showSuccess('Booking declined');
    });
  }

  /// Format currency
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Format date
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format time
  String formatTime(String time) {
    // Convert 24-hour format to 12-hour format
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  /// Get color for booking status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
