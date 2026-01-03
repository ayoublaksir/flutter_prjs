import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/booking_models.dart';
import '../../models/service_models.dart';
import '../../models/user_models.dart';
import '../../services/api_services.dart';
import '../base_controller.dart';

class BookingHistoryController extends BaseController {
  // Services via dependency injection
  final BookingAPI _bookingAPI = Get.find<BookingAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();
  final ServiceAPI _serviceAPI = Get.find<ServiceAPI>();

  // Reactive state
  final RxList<Booking> bookings = <Booking>[].obs;
  final Rx<Map<String, User>> providers = Rx<Map<String, User>>({});
  final Rx<Map<String, ProviderService>> services =
      Rx<Map<String, ProviderService>>({});

  // Filter state
  final RxString selectedFilter =
      'all'.obs; // all, active, completed, cancelled
  final RxList<Booking> filteredBookings = <Booking>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadBookingHistory();
  }

  /// Load booking history
  Future<void> loadBookingHistory() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final result = await _bookingAPI.getSeekerBookings(userId);
      bookings.value = result;

      // Apply filter
      _applyFilter();

      // Load provider and service details
      await _loadProviderAndServiceDetails();
    });
  }

  /// Load provider and service details
  Future<void> _loadProviderAndServiceDetails() async {
    // Extract unique provider and service IDs
    final providerIds = bookings.map((b) => b.providerId).toSet();
    final serviceIds = bookings.map((b) => b.serviceId).toSet();

    // Load providers
    final providerMap = <String, User>{};
    for (final id in providerIds) {
      try {
        final provider = await _userAPI.getProviderProfile(id);
        if (provider != null) {
          providerMap[id] = provider;
        }
      } catch (e) {
        debugPrint('Error loading provider $id: $e');
      }
    }

    // Load services
    final serviceMap = <String, ProviderService>{};
    for (final id in serviceIds) {
      try {
        final service = await _serviceAPI.getServiceDetails(id);
        if (service != null) {
          serviceMap[id] = service;
        }
      } catch (e) {
        debugPrint('Error loading service $id: $e');
      }
    }

    // Update reactive state
    providers.value = providerMap;
    services.value = serviceMap;
  }

  /// Apply filter to bookings
  void _applyFilter() {
    switch (selectedFilter.value) {
      case 'active':
        filteredBookings.value =
            bookings
                .where((b) => b.status == 'pending' || b.status == 'confirmed')
                .toList();
        break;
      case 'completed':
        filteredBookings.value =
            bookings.where((b) => b.status == 'completed').toList();
        break;
      case 'cancelled':
        filteredBookings.value =
            bookings
                .where((b) => b.status == 'cancelled' || b.status == 'declined')
                .toList();
        break;
      case 'all':
      default:
        filteredBookings.value = bookings;
        break;
    }
  }

  /// Change filter
  void changeFilter(String filter) {
    if (selectedFilter.value == filter) return;

    selectedFilter.value = filter;
    _applyFilter();
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, String reason) {
    return runWithLoading(() async {
      await _bookingAPI.updateBookingStatus(
        bookingId: bookingId,
        status: 'cancelled',
      );

      // Update booking status locally
      final index = bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        final booking = bookings[index];
        final updatedBooking = Booking(
          id: booking.id,
          serviceId: booking.serviceId,
          seekerId: booking.seekerId,
          providerId: booking.providerId,
          status: 'cancelled',
          bookingDate: booking.bookingDate,
          createdAt: booking.createdAt,
          bookingTime: booking.bookingTime,
          address: booking.address,
          description: booking.description,
          price: booking.price,
          startTime: booking.startTime,
          endTime: booking.endTime,
          paymentMethod: booking.paymentMethod,
          location: booking.location,
        );

        bookings[index] = updatedBooking;
        _applyFilter();
      }

      showSuccess('Booking cancelled successfully');
    });
  }

  /// Reschedule a booking
  Future<void> rescheduleBooking(
    String bookingId,
    DateTime newDate,
    String newTime,
  ) {
    return runWithLoading(() async {
      await _bookingAPI.updateBookingDateTime(
        bookingId: bookingId,
        date: newDate,
        time: newTime,
      );

      // Update booking locally
      final index = bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        final booking = bookings[index];
        final updatedBooking = Booking(
          id: booking.id,
          serviceId: booking.serviceId,
          seekerId: booking.seekerId,
          providerId: booking.providerId,
          status: booking.status,
          bookingDate: newDate,
          createdAt: booking.createdAt,
          bookingTime: newTime,
          address: booking.address,
          description: booking.description,
          price: booking.price,
          startTime: newDate,
          endTime: booking.endTime,
          paymentMethod: booking.paymentMethod,
          location: booking.location,
        );

        bookings[index] = updatedBooking;
        _applyFilter();
      }

      showSuccess('Booking rescheduled successfully');
    });
  }

  /// Request a refund
  Future<void> requestRefund(String bookingId, String reason) {
    return runWithLoading(() async {
      await _bookingAPI.updateBookingStatus(
        bookingId: bookingId,
        status: 'refunded',
      );
      showSuccess('Refund request submitted');
    });
  }

  /// Get provider name
  String getProviderName(String providerId) {
    return providers.value[providerId]?.name ?? 'Unknown Provider';
  }

  /// Get service name
  String getServiceName(String serviceId) {
    return services.value[serviceId]?.name ?? 'Unknown Service';
  }

  /// Format date
  String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format time
  String formatTime(String time) {
    // Convert 24-hour format to 12-hour format if needed
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

  /// Format price
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
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

  /// Get icon for booking status
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
      case 'accepted':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Navigate to booking details
  void navigateToBookingDetails(String bookingId) {
    Get.toNamed('/booking-details', arguments: {'bookingId': bookingId});
  }

  /// Navigate to provider profile
  void navigateToProviderProfile(String providerId) {
    Get.toNamed('/provider-profile', arguments: {'providerId': providerId});
  }

  /// Navigate to service details
  void navigateToServiceDetails(String serviceId) {
    Get.toNamed('/service-details', arguments: {'serviceId': serviceId});
  }

  /// Navigate to review screen
  void navigateToReviewScreen(String bookingId) {
    final booking = bookings.firstWhereOrNull((b) => b.id == bookingId);
    if (booking == null) return;

    Get.toNamed(
      '/review',
      arguments: {
        'bookingId': bookingId,
        'providerId': booking.providerId,
        'serviceId': booking.serviceId,
      },
    );
  }

  /// Navigate to rebook screen
  void navigateToRebookScreen(String bookingId) {
    final booking = bookings.firstWhereOrNull((b) => b.id == bookingId);
    if (booking == null) return;

    Get.toNamed(
      '/booking-form',
      arguments: {
        'providerId': booking.providerId,
        'serviceId': booking.serviceId,
        'isRebooking': true,
        'originalBookingId': bookingId,
      },
    );
  }
}
