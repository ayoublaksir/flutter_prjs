import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_services.dart';
import '../../services/api_services.dart';
import '../../models/user_models.dart';
import '../base_controller.dart';

class SettingsController extends BaseController {
  // Services via dependency injection
  final UserAPI _userAPI = Get.find<UserAPI>();
  final AuthService _authService = Get.find<AuthService>();
  final Rx<ServiceProvider?> profile = Rx<ServiceProvider?>(null);
  final RxBool pushNotifications = true.obs;
  final RxBool emailNotifications = true.obs;
  final RxBool smsNotifications = false.obs;
  final RxString selectedLanguage = 'English'.obs;
  final RxString selectedTheme = 'system'.obs;

  @override
  void onInit() {
    super.onInit();

    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      // Original API call once ready
      // await loadSettings();

      // Use mock data for now
      await loadMockSettings();
    });
  }

  Future<void> loadMockSettings() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    pushNotifications.value = true;
    emailNotifications.value = true;
    smsNotifications.value = false;
    selectedLanguage.value = 'English';
    selectedTheme.value = 'light';

    // No need to manually set isLoading to false
    // since it's handled by the runWithLoading method
  }

  Future<void> loadSettings() async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      showError('User not authenticated');
      return;
    }

    final provider = await _userAPI.getProviderProfile(userId);
    if (provider != null) {
      profile.value = provider;
      final settings = provider.settings as UserSettings;
      pushNotifications.value = settings.pushNotifications;
      emailNotifications.value = settings.emailNotifications;
      smsNotifications.value = settings.smsNotifications;
      selectedLanguage.value = settings.language;
      selectedTheme.value = settings.theme;
    }
  }

  Future<void> updateSettings() {
    return runWithLoading(() async {
      if (profile.value != null) {
        final updatedSettings = UserSettings(
          pushNotifications: pushNotifications.value,
          emailNotifications: emailNotifications.value,
          smsNotifications: smsNotifications.value,
          language: selectedLanguage.value,
          theme: selectedTheme.value,
        );

        await _userAPI.updateProviderSettings(
          profile.value!.id,
          updatedSettings,
        );

        showSuccess('Settings updated successfully');
      } else {
        showError('Profile not loaded');
      }
    });
  }

  Future<bool> signOut() async {
    try {
      await runWithLoading(() async {
        await _authService.signOut();
      });
      Get.offAllNamed('/login');
      return true;
    } catch (e) {
      showError('Failed to sign out');
      return false;
    }
  }

  String capitalize(String s) {
    return s.isNotEmpty ? "${s[0].toUpperCase()}${s.substring(1)}" : "";
  }
}
