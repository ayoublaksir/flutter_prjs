import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user_models.dart';
import '../../services/api_services.dart';
import '../base_controller.dart';

class ProfileController extends BaseController {
  // Services via dependency injection
  final UserAPI _userAPI = Get.find<UserAPI>();
  final Rx<ServiceProvider?> provider = Rx<ServiceProvider?>(null);

  @override
  void onInit() {
    super.onInit();
    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      // Keep using mock data for now
      await loadMockProfile();
      // Later we can switch to real API calls:
      // await loadProfile();
    });
  }

  Future<void> loadMockProfile() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    provider.value = ServiceProvider(
      id: 'provider-1',
      name: 'John Smith',
      email: 'john.smith@example.com',
      phone: '(555) 123-4567',
      profileImage: '',
      services: ['Plumbing', 'Electrical', 'Carpentry'],
      rating: 4.8,
      reviewCount: 24,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      role: 'provider',
      businessName: 'Smith Home Services',
      businessAddress: '123 Main St, Anytown, USA',
      workingHours: {
        '1': WorkingHours(isWorking: true, start: '09:00', end: '17:00'),
        '2': WorkingHours(isWorking: true, start: '09:00', end: '17:00'),
        '3': WorkingHours(isWorking: true, start: '09:00', end: '17:00'),
        '4': WorkingHours(isWorking: true, start: '09:00', end: '17:00'),
        '5': WorkingHours(isWorking: true, start: '09:00', end: '17:00'),
        '6': WorkingHours(isWorking: false, start: '', end: ''),
        '7': WorkingHours(isWorking: false, start: '', end: ''),
      },
      vacationDays: [],
      pricingSettings: {},
      bankDetails: {},
      completedJobs: 24,
    );
    
    // No need to manually set isLoading to false
    // since it's handled by the runWithLoading method
  }

  // Real API implementation - will replace mock data when ready
  Future<void> loadProfile() async {
    // We don't need try/catch here as it's handled by the runWithLoading method
    // Get current user ID directly from BaseController
    final userId = currentUserId;
    if (userId.isNotEmpty) {
      final providerData = await _userAPI.getProviderProfile(userId);
      provider.value = providerData;
    } else {
      showError('User not authenticated');
    }
  }
}
