import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/service_models.dart';
import '../../services/api_services.dart';
import '../base_controller.dart';

class SavedServicesController extends BaseController {
  // Services via dependency injection
  final ServiceAPI _serviceAPI = Get.find<ServiceAPI>();

  // Reactive state
  final RxList<ProviderService> savedServices = <ProviderService>[].obs;
  final RxMap<String, bool> isAvailableNow = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedServices();
  }

  /// Load saved services
  Future<void> loadSavedServices() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final services = await _serviceAPI.getSavedServices(userId);
      savedServices.value = services;

      // Check availability for each service
      await _checkServicesAvailability();
    });
  }

  /// Check availability for all services
  Future<void> _checkServicesAvailability() async {
    final now = DateTime.now();
    final dayOfWeek = now.weekday.toString();

    for (final service in savedServices) {
      // Get provider details to check availability
      try {
        final provider = await _serviceAPI.getServiceProvider(service.id);

        // Check if it's a vacation day
        if (provider.vacationDays.contains(now)) {
          isAvailableNow[service.id] = false;
          continue;
        }

        // Check working hours
        final workingHours = provider.workingHours[dayOfWeek];
        if (workingHours == null || !workingHours.isWorking) {
          isAvailableNow[service.id] = false;
          continue;
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

          isAvailableNow[service.id] =
              currentMinutes >= startMinutes && currentMinutes <= endMinutes;
        } catch (e) {
          debugPrint(
            'Error parsing working hours for service ${service.id}: $e',
          );
          isAvailableNow[service.id] = false;
        }
      } catch (e) {
        debugPrint('Error checking availability for service ${service.id}: $e');
        isAvailableNow[service.id] = false;
      }
    }
  }

  /// Remove service from saved list
  Future<void> removeSavedService(String serviceId) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      await _serviceAPI.unsaveService(userId, serviceId);

      // Update local state
      savedServices.removeWhere((service) => service.id == serviceId);
      isAvailableNow.remove(serviceId);

      showSuccess('Service removed from saved list');
    });
  }

  /// Navigate to service details
  void navigateToServiceDetails(String serviceId) {
    Get.toNamed('/service-details', arguments: {'serviceId': serviceId});
  }

  /// Navigate to booking screen
  void navigateToBooking(String serviceId, String providerId) {
    Get.toNamed(
      '/booking-form',
      arguments: {'serviceId': serviceId, 'providerId': providerId},
    );
  }

  /// Format price
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Format rating
  String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Get availability text
  String getAvailabilityText(String serviceId) {
    final available = isAvailableNow[serviceId] ?? false;
    return available ? 'Available now' : 'Not available now';
  }

  /// Get availability color
  Color getAvailabilityColor(String serviceId) {
    final available = isAvailableNow[serviceId] ?? false;
    return available ? Colors.green : Colors.red;
  }

  /// Sort services by price (ascending)
  void sortByPriceAscending() {
    savedServices.sort((a, b) => a.price.compareTo(b.price));
  }

  /// Sort services by price (descending)
  void sortByPriceDescending() {
    savedServices.sort((a, b) => b.price.compareTo(a.price));
  }

  /// Filter services by availability
  void filterByAvailability(bool available) {
    if (available) {
      savedServices.sort((a, b) {
        final aAvailable = isAvailableNow[a.id] ?? false;
        final bAvailable = isAvailableNow[b.id] ?? false;

        if (aAvailable && !bAvailable) return -1;
        if (!aAvailable && bAvailable) return 1;
        return 0;
      });
    }
  }

  /// Check if list is empty
  bool get isEmpty => savedServices.isEmpty;
}
