import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user_models.dart';
import '../../services/api_services.dart';
import '../../services/notification_services.dart';
import '../base_controller.dart';

class NotificationSettingsController extends BaseController {
  // Services via dependency injection
  final UserAPI _userAPI = Get.find<UserAPI>();
  final PushNotificationService _notificationServices =
      Get.find<PushNotificationService>();

  // Reactive state for notification settings
  final RxBool pushNotifications = true.obs;
  final RxBool emailNotifications = true.obs;
  final RxBool smsNotifications = false.obs;

  // Category-specific settings
  final RxBool newBookingNotification = true.obs;
  final RxBool bookingUpdatesNotification = true.obs;
  final RxBool bookingReminderNotification = true.obs;
  final RxBool messageNotification = true.obs;
  final RxBool paymentNotification = true.obs;
  final RxBool reviewNotification = true.obs;
  final RxBool promotionNotification = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadNotificationSettings();
  }
  
  /// Load notification settings
  Future<void> loadNotificationSettings() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }
      
      final user = await _userAPI.getProviderProfile(userId);
      if (user != null && user.settings != null) {
        // General notification channels
        pushNotifications.value = user.settings!.pushNotifications;
        emailNotifications.value = user.settings!.emailNotifications;
        smsNotifications.value = user.settings!.smsNotifications;
        
        // Category-specific settings
        final notificationPreferences = user.settings!.notificationPreferences; 
        if (notificationPreferences != null) {
          newBookingNotification.value = notificationPreferences['newBooking'] ?? true;
          bookingUpdatesNotification.value = notificationPreferences['bookingUpdates'] ?? true;
          bookingReminderNotification.value = notificationPreferences['bookingReminder'] ?? true;
          messageNotification.value = notificationPreferences['message'] ?? true;
          paymentNotification.value = notificationPreferences['payment'] ?? true;
          reviewNotification.value = notificationPreferences['review'] ?? true;
          promotionNotification.value = notificationPreferences['promotion'] ?? false;
        }
      }
    });
  }
  
  /// Update notification settings
  Future<void> updateNotificationSettings() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }
      
      // Create updated settings
      final updatedSettings = UserSettings(
        pushNotifications: pushNotifications.value,
        emailNotifications: emailNotifications.value,
        smsNotifications: smsNotifications.value,
        language: 'English', // Keep existing value or get from user data
        theme: 'light', // Keep existing value or get from user data
        notificationPreferences: {
          'newBooking': newBookingNotification.value,
          'bookingUpdates': bookingUpdatesNotification.value,
          'bookingReminder': bookingReminderNotification.value,
          'message': messageNotification.value,
          'payment': paymentNotification.value,
          'review': reviewNotification.value,
          'promotion': promotionNotification.value,
        },
      );

      // Update in database
      await _userAPI.updateProviderSettings(userId, updatedSettings);

      // Update device token if push notifications enabled/disabled
      await _updateDeviceToken(pushNotifications.value);
      
      showSuccess('Notification settings updated');
    });
  }
  
  /// Toggle push notifications
  Future<void> togglePushNotifications(bool value) {
    return runWithLoading(() async {
      pushNotifications.value = value;
      
      // Update device token
      await _updateDeviceToken(value);
      
      // Update settings in database
      await updateNotificationSettings();
    });
  }
  
  /// Toggle email notifications
  void toggleEmailNotifications(bool value) {
    emailNotifications.value = value;
  }
  
  /// Toggle SMS notifications
  void toggleSmsNotifications(bool value) {
    smsNotifications.value = value;
  }
  
  /// Toggle category-specific notification
  void toggleCategoryNotification(String category, bool value) {
    switch (category) {
      case 'newBooking':
        newBookingNotification.value = value;
        break;
      case 'bookingUpdates':
        bookingUpdatesNotification.value = value;
        break;
      case 'bookingReminder':
        bookingReminderNotification.value = value;
        break;
      case 'message':
        messageNotification.value = value;
        break;
      case 'payment':
        paymentNotification.value = value;
        break;
      case 'review':
        reviewNotification.value = value;
        break;
      case 'promotion':
        promotionNotification.value = value;
        break;
    }
  }
  
  /// Update device token for push notifications
  Future<void> _updateDeviceToken(bool enablePush) async {
    final userId = currentUserId;
    if (userId.isEmpty) return;
    
    if (enablePush) {
      // Register device for push notifications
      final token = await _notificationServices.getDeviceToken();
      if (token != null) {
        await _notificationServices.registerDeviceToken(userId, token);
      }
    } else {
      // Unregister device from push notifications
      final token = await _notificationServices.getDeviceToken();
      if (token != null) {
        await _notificationServices.unregisterDeviceToken(userId, token);
      }
    }
  }
  
  /// Enable all notifications
  void enableAllNotifications() {
    newBookingNotification.value = true;
    bookingUpdatesNotification.value = true;
    bookingReminderNotification.value = true;
    messageNotification.value = true;
    paymentNotification.value = true;
    reviewNotification.value = true;
    promotionNotification.value = true;
  }
  
  /// Disable all notifications
  void disableAllNotifications() {
    newBookingNotification.value = false;
    bookingUpdatesNotification.value = false;
    bookingReminderNotification.value = false;
    messageNotification.value = false;
    paymentNotification.value = false;
    reviewNotification.value = false;
    promotionNotification.value = false;
  }
  
  /// Get category title
  String getCategoryTitle(String category) {
    switch (category) {
      case 'newBooking':
        return 'New Booking Requests';
      case 'bookingUpdates':
        return 'Booking Updates';
      case 'bookingReminder':
        return 'Booking Reminders';
      case 'message':
        return 'New Messages';
      case 'payment':
        return 'Payment Updates';
      case 'review':
        return 'New Reviews';
      case 'promotion':
        return 'Promotions & Offers';
      default:
        return 'Unknown Category';
    }
  }
  
  /// Get category description
  String getCategoryDescription(String category) {
    switch (category) {
      case 'newBooking':
        return 'Get notified when you receive a new booking request';
      case 'bookingUpdates':
        return 'Updates about booking status changes or cancellations';
      case 'bookingReminder':
        return 'Reminders about upcoming bookings';
      case 'message':
        return 'Get notified when you receive new messages';
      case 'payment':
        return 'Notifications about payments received or pending';
      case 'review':
        return 'Get notified when clients leave reviews';
      case 'promotion':
        return 'Offers, discounts, and promotional updates';
      default:
        return '';
    }
  }
  
  /// Get category icon
  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'newBooking':
        return Icons.book_online;
      case 'bookingUpdates':
        return Icons.update;
      case 'bookingReminder':
        return Icons.alarm;
      case 'message':
        return Icons.message;
      case 'payment':
        return Icons.payment;
      case 'review':
        return Icons.star;
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }
}