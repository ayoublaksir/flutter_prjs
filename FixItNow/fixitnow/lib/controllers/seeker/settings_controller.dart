import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user_models.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../services/notification_services.dart';
import '../base_controller.dart';

class SeekerSettingsController extends BaseController {
  // Services via dependency injection
  final UserAPI _userAPI = Get.find<UserAPI>();
  final AuthService _authService = Get.find<AuthService>();
  final PushNotificationService _notificationServices =
      Get.find<PushNotificationService>();

  // Reactive state for settings
  final RxBool pushNotifications = true.obs;
  final RxBool emailNotifications = true.obs;
  final RxBool smsNotifications = false.obs;
  final RxString selectedLanguage = 'English'.obs;
  final RxString selectedTheme = 'light'.obs;

  // Category-specific settings
  final RxBool bookingUpdatesNotification = true.obs;
  final RxBool bookingReminderNotification = true.obs;
  final RxBool messageNotification = true.obs;
  final RxBool paymentNotification = true.obs;
  final RxBool promotionNotification = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Load user settings
  Future<void> loadSettings() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final user = await _userAPI.getSeekerProfile(userId);
      if (user != null && user.settings != null) {
        // General settings
        pushNotifications.value = user.settings!.pushNotifications;
        emailNotifications.value = user.settings!.emailNotifications;
        smsNotifications.value = user.settings!.smsNotifications;
        selectedLanguage.value = user.settings!.language;
        selectedTheme.value = user.settings!.theme;

        // Category-specific settings
        final notificationPreferences = user.settings!.notificationPreferences;
        if (notificationPreferences != null) {
          bookingUpdatesNotification.value =
              notificationPreferences['bookingUpdates'] ?? true;
          bookingReminderNotification.value =
              notificationPreferences['bookingReminder'] ?? true;
          messageNotification.value =
              notificationPreferences['message'] ?? true;
          paymentNotification.value =
              notificationPreferences['payment'] ?? true;
          promotionNotification.value =
              notificationPreferences['promotion'] ?? false;
        }
      }
    });
  }

  /// Update user settings
  Future<void> updateSettings() {
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
        language: selectedLanguage.value,
        theme: selectedTheme.value,
        notificationPreferences: {
          'bookingUpdates': bookingUpdatesNotification.value,
          'bookingReminder': bookingReminderNotification.value,
          'message': messageNotification.value,
          'payment': paymentNotification.value,
          'promotion': promotionNotification.value,
        },
      );

      // Update in database
      await _userAPI.updateSeekerSettings(userId, updatedSettings);

      // Update device token if push notifications enabled/disabled
      if (pushNotifications.value) {
        await _registerDeviceToken();
      } else {
        await _unregisterDeviceToken();
      }

      // Update app theme
      Get.changeThemeMode(
        selectedTheme.value == 'dark' ? ThemeMode.dark : ThemeMode.light,
      );

      showSuccess('Settings updated successfully');
    });
  }

  /// Toggle push notifications
  void togglePushNotifications(bool value) {
    pushNotifications.value = value;
  }

  /// Toggle email notifications
  void toggleEmailNotifications(bool value) {
    emailNotifications.value = value;
  }

  /// Toggle SMS notifications
  void toggleSmsNotifications(bool value) {
    smsNotifications.value = value;
  }

  /// Change language
  void changeLanguage(String language) {
    selectedLanguage.value = language;
  }

  /// Change theme
  void changeTheme(String theme) {
    selectedTheme.value = theme;

    // Update app theme
    Get.changeThemeMode(theme == 'dark' ? ThemeMode.dark : ThemeMode.light);
  }

  /// Toggle category-specific notification
  void toggleCategoryNotification(String category, bool value) {
    switch (category) {
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
      case 'promotion':
        promotionNotification.value = value;
        break;
    }
  }

  /// Sign out
  Future<void> signOut() {
    return runWithLoading(() async {
      await _authService.signOut();
      Get.offAllNamed('/login');
    });
  }

  /// Delete account
  Future<void> deleteAccount(String password) {
    return runWithLoading(() async {
      await _authService.deleteAccount(password);
      Get.offAllNamed('/login');
    });
  }

  /// Change password
  Future<void> changePassword(String currentPassword, String newPassword) {
    return runWithLoading(() async {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      showSuccess('Password changed successfully');
    });
  }

  /// Register device token for push notifications
  Future<void> _registerDeviceToken() async {
    final userId = currentUserId;
    if (userId.isEmpty) return;

    final token = await _notificationServices.getDeviceToken();
    if (token != null) {
      await _notificationServices.registerDeviceToken(userId, token);
    }
  }

  /// Unregister device token
  Future<void> _unregisterDeviceToken() async {
    final userId = currentUserId;
    if (userId.isEmpty) return;

    final token = await _notificationServices.getDeviceToken();
    if (token != null) {
      await _notificationServices.unregisterDeviceToken(userId, token);
    }
  }

  /// Navigate to profile screen
  void navigateToProfile() {
    Get.toNamed('/seeker-profile');
  }

  /// Navigate to payment methods
  void navigateToPaymentMethods() {
    Get.toNamed('/payment-methods');
  }

  /// Navigate to address management
  void navigateToAddressManagement() {
    Get.toNamed('/address-management');
  }

  /// Navigate to help and support
  void navigateToHelpSupport() {
    Get.toNamed('/help-support');
  }

  /// Navigate to privacy policy
  void navigateToPrivacyPolicy() {
    Get.toNamed('/privacy-policy');
  }

  /// Navigate to terms and conditions
  void navigateToTermsConditions() {
    Get.toNamed('/terms-conditions');
  }
}
