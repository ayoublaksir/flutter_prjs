import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_services.dart';
import '../../models/service_models.dart';
import '../../models/user_models.dart';
import '../base_controller.dart';

class SeekerHomeController extends BaseController {
  // Services via dependency injection
  final ServiceAPI _serviceAPI = Get.find<ServiceAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();
  final RxList<ServiceCategory> popularCategories = <ServiceCategory>[].obs;
  final RxList<ServiceProvider> topProviders = <ServiceProvider>[].obs;
  final RxList<ProviderService> featuredServices = <ProviderService>[].obs;

  @override
  void onInit() {
    super.onInit();
    
    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      await loadHomeData();
    });
  }

  Future<void> loadHomeData() async {
    // No need for try-catch block as it's handled by runWithLoading
    final userId = currentUserId;
    if (userId.isEmpty) {
      showError('User not authenticated');
      return;
    }
    
    try {
      // Load data in parallel
      final results = await Future.wait([
        _serviceAPI.getPopularCategories(),
        _userAPI.getTopProviders(),
        _serviceAPI.getFeaturedServices(),
      ]);

      popularCategories.value = results[0] as List<ServiceCategory>;
      topProviders.value = results[1] as List<ServiceProvider>;
      featuredServices.value = results[2] as List<ProviderService>;
    } catch (e) {
      debugPrint('Error loading home data: $e');
      showError('Failed to load home data');
    }
  }
}