import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/service_models.dart';
import '../../models/provider_models.dart' as provider_models;
import '../../models/user_models.dart';
import '../../models/review_models.dart';
import '../../models/app_models.dart';
import '../../services/api_services.dart';
import '../base_controller.dart';

class ServiceDetailsController extends BaseController {
  // Services via dependency injection
  final ServiceAPI _serviceAPI = Get.find<ServiceAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();
  final ReviewAPI _reviewAPI = Get.find<ReviewAPI>();

  // Service ID (passed from arguments)
  final String serviceId;

  // Reactive state
  final Rx<ProviderService?> serviceDetails = Rx<ProviderService?>(null);
  final Rx<ServiceProvider?> providerDetails = Rx<ServiceProvider?>(null);
  final RxList<Review> reviews = <Review>[].obs;
  final RxBool isSaved = false.obs;
  final RxBool isAvailableNow = false.obs;

  // UI state
  final RxBool showFullDescription = false.obs;
  final RxInt selectedImageIndex = 0.obs;

  ServiceDetailsController({required this.serviceId});

  @override
  void onInit() {
    super.onInit();
    loadServiceDetails();
  }

  /// Load service details
  Future<void> loadServiceDetails() {
    return runWithLoading(() async {
      // Load everything in parallel
      await Future.wait([
        _loadServiceData(),
        _loadProviderData(),
        _loadReviews(),
        _checkIfSaved(),
      ]);

      // Check availability
      _checkAvailability();
    });
  }

  /// Load service data
  Future<void> _loadServiceData() async {
    final service = await _serviceAPI.getServiceDetails(serviceId);
    serviceDetails.value = service;
  }

  /// Load provider data
  Future<void> _loadProviderData() async {
    if (serviceDetails.value == null) {
      final service = await _serviceAPI.getServiceDetails(serviceId);
      serviceDetails.value = service;
    }

    if (serviceDetails.value != null) {
      final provider = await _userAPI.getProviderProfile(
        serviceDetails.value!.providerId,
      );
      providerDetails.value = provider;
    }
  }

  /// Load reviews
  Future<void> _loadReviews() async {
    final reviewsList = await _reviewAPI.getProviderReviews(serviceId);
    reviews.value = reviewsList;
  }

  /// Check if service is saved
  Future<void> _checkIfSaved() async {
    final userId = currentUserId;
    if (userId.isEmpty) return;

    final saved = await _serviceAPI.isServiceFavorite(serviceId);
    isSaved.value = saved;
  }

  /// Check if service is available now
  void _checkAvailability() {
    if (serviceDetails.value == null || providerDetails.value == null) return;

    final now = DateTime.now();
    final dayOfWeek = now.weekday.toString();

    // Check if it's a vacation day
    if (providerDetails.value!.vacationDays.contains(now)) {
      isAvailableNow.value = false;
      return;
    }

    // Check working hours
    final workingHours = providerDetails.value!.workingHours[dayOfWeek];
    if (workingHours == null || !workingHours.isWorking) {
      isAvailableNow.value = false;
      return;
    }

    // Parse start and end times
    try {
      final startParts = workingHours.start.split(':');
      final endParts = workingHours.end.split(':');

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final startTime = TimeOfDay(hour: startHour, minute: startMinute);
      final endTime = TimeOfDay(hour: endHour, minute: endMinute);
      final currentTime = TimeOfDay.fromDateTime(now);

      // Convert to minutes for comparison
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;

      isAvailableNow.value =
          currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } catch (e) {
      debugPrint('Error parsing working hours: $e');
      isAvailableNow.value = false;
    }
  }

  /// Toggle saved status
  Future<void> toggleSaved() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('Please log in to save services');
        return;
      }

      if (isSaved.value) {
        await _serviceAPI.unsaveService(userId, serviceId);
        isSaved.value = false;
        showSuccess('Service removed from saved list');
      } else {
        await _serviceAPI.addToFavorites(serviceId);
        isSaved.value = true;
        showSuccess('Service saved');
      }
    });
  }

  /// Toggle full description
  void toggleFullDescription() {
    showFullDescription.value = !showFullDescription.value;
  }

  /// Set selected image
  void setSelectedImage(int index) {
    if (index >= 0 &&
        serviceDetails.value != null &&
        index < serviceDetails.value!.images.length) {
      selectedImageIndex.value = index;
    }
  }

  /// Navigate to booking screen
  void navigateToBooking() {
    Get.toNamed(
      '/booking-form',
      arguments: {
        'serviceId': serviceId,
        'providerId': serviceDetails.value?.providerId ?? '',
      },
    );
  }

  /// Navigate to provider profile
  void navigateToProviderProfile() {
    if (serviceDetails.value == null) return;

    Get.toNamed(
      '/provider-profile',
      arguments: {'providerId': serviceDetails.value!.providerId},
    );
  }

  /// Navigate to reviews screen
  void navigateToReviews() {
    Get.toNamed(
      '/reviews',
      arguments: {
        'serviceId': serviceId,
        'providerId': serviceDetails.value?.providerId ?? '',
      },
    );
  }

  /// Navigate to chat with provider
  void navigateToChat() {
    if (serviceDetails.value == null) return;

    Get.toNamed(
      '/chat',
      arguments: {'recipientId': serviceDetails.value!.providerId},
    );
  }

  /// Format price
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Format duration
  String formatDuration(int durationMinutes) {
    if (durationMinutes < 60) {
      return '$durationMinutes mins';
    }

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (minutes == 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes mins';
  }

  /// Format rating
  String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Get availability text
  String getAvailabilityText() {
    if (isAvailableNow.value) {
      return 'Available now';
    }
    return 'Not available now';
  }

  /// Format working hours
  String formatWorkingHours(String day) {
    if (providerDetails.value == null) return 'Not available';

    final hours = providerDetails.value!.workingHours[day];
    if (hours == null || !hours.isWorking) {
      return 'Closed';
    }

    return '${hours.start} - ${hours.end}';
  }

  /// Get day name
  String getDayName(String day) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final index = int.tryParse(day);

    if (index != null && index >= 1 && index <= 7) {
      return days[index - 1];
    }

    return day;
  }

  /// Get current day of week
  String getCurrentDay() {
    return DateTime.now().weekday.toString();
  }

  /// Get review summary text
  String getReviewSummary() {
    if (reviews.isEmpty) {
      return 'No reviews yet';
    }

    final count = reviews.length;
    final rating =
        reviews.fold(0.0, (sum, review) => sum + review.rating) / count;

    return '${formatRating(rating)} (${count} ${count == 1 ? 'review' : 'reviews'})';
  }
}
