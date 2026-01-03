import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/service_models.dart';
import '../../models/provider_models.dart';
import '../../models/user_models.dart';
import '../../models/booking_models.dart';
import '../../models/app_models.dart';
import '../../services/api_services.dart';
import '../../services/location_services.dart';
import '../base_controller.dart';

class BookingController extends BaseController {
  // Services via dependency injection
  final ServiceAPI _serviceAPI = Get.find<ServiceAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();
  final BookingAPI _bookingAPI = Get.find<BookingAPI>();
  final LocationService _locationServices = Get.find<LocationService>();

  // Service and provider IDs (passed from arguments)
  final String serviceId;
  final String providerId;
  final bool isRebooking;
  final String? originalBookingId;

  // Reactive state
  final Rx<ProviderService?> serviceDetails = Rx<ProviderService?>(null);
  final Rx<ServiceProvider?> providerDetails = Rx<ServiceProvider?>(null);
  final Rx<ServiceSeeker?> seekerProfile = Rx<ServiceSeeker?>(null);
  final RxList<Address> addresses = <Address>[].obs;

  // Form state
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rx<String?> selectedTime = Rx<String?>(null);
  final Rx<Address?> selectedAddress = Rx<Address?>(null);
  final RxString notes = ''.obs;
  final RxInt quantity = 1.obs;
  final RxString selectedPaymentMethod = 'Credit Card'.obs;
  final RxBool useEmergencyRate = false.obs;

  // Form controllers
  final notesController = TextEditingController();

  // Available time slots
  final RxList<String> availableTimeSlots = <String>[].obs;

  // Final price calculation
  final RxDouble basePrice = 0.0.obs;
  final RxDouble totalPrice = 0.0.obs;

  BookingController({
    required this.serviceId,
    required this.providerId,
    this.isRebooking = false,
    this.originalBookingId,
  });

  @override
  void onInit() {
    super.onInit();

    // Set up notes listener
    notesController.addListener(() {
      notes.value = notesController.text;
    });

    // Load initial data
    loadBookingData();
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }

  /// Load booking data
  Future<void> loadBookingData() {
    return runWithLoading(() async {
      // Load everything in parallel
      await Future.wait([
        _loadServiceDetails(),
        _loadProviderDetails(),
        _loadUserProfile(),
      ]);

      // If this is a rebooking, load the original booking details
      if (isRebooking && originalBookingId != null) {
        await _loadOriginalBooking();
      }

      // Generate available time slots
      _generateTimeSlots();

      // Calculate prices
      _calculatePrices();
    });
  }

  /// Load service details
  Future<void> _loadServiceDetails() async {
    final service = await _serviceAPI.getServiceDetails(serviceId);
    serviceDetails.value = service;
    basePrice.value = service?.price ?? 0.0;
  }

  /// Load provider details
  Future<void> _loadProviderDetails() async {
    final provider = await _userAPI.getProviderProfile(providerId);
    providerDetails.value = provider;
  }

  /// Load user profile
  Future<void> _loadUserProfile() async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      showError('User not authenticated');
      return;
    }

    final seeker = await _userAPI.getSeekerProfile(userId);
    seekerProfile.value = seeker;

    // Load addresses
    addresses.value = seeker?.addresses ?? [];

    // Select default address if available
    if (seeker?.defaultAddressId != null && addresses.isNotEmpty) {
      selectedAddress.value = addresses.firstWhereOrNull(
        (addr) => addr.id == seeker?.defaultAddressId,
      );
    } else if (addresses.isNotEmpty) {
      selectedAddress.value = addresses.first;
    }
  }

  /// Load original booking details
  Future<void> _loadOriginalBooking() async {
    if (originalBookingId == null) return;

    final booking = await _bookingAPI.getBooking(originalBookingId!);

    // Pre-fill form fields
    if (booking?.bookingDate != null) {
      selectedDate.value = booking!.bookingDate!;
    }

    if (booking?.bookingTime != null) {
      selectedTime.value = booking!.bookingTime;
    }

    if (booking?.description != null) {
      notes.value = booking!.description!;
      notesController.text = booking.description!;
    }
  }

  /// Generate available time slots
  void _generateTimeSlots() {
    // Clear existing slots
    availableTimeSlots.clear();

    if (providerDetails.value == null) return;

    final dayOfWeek = selectedDate.value.weekday.toString();
    final workingHours = providerDetails.value!.workingHours[dayOfWeek];

    // Check if provider works on selected day
    if (workingHours == null || !workingHours.isWorking) {
      return;
    }

    // Check if it's a vacation day
    if (providerDetails.value!.vacationDays.contains(selectedDate.value)) {
      return;
    }

    // Parse working hours
    try {
      final startParts = workingHours.start.split(':');
      final endParts = workingHours.end.split(':');

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      // Generate time slots (30 minute intervals)
      final slots = <String>[];

      for (int hour = startHour; hour <= endHour; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          // Skip times before start time or after end time
          if (hour == startHour && minute < startMinute) continue;
          if (hour == endHour && minute > endMinute) continue;

          final time = '$hour:${minute.toString().padLeft(2, '0')}';
          slots.add(time);
        }
      }

      // Filter out slots that are in the past if booking for today
      final now = DateTime.now();
      if (isSameDay(selectedDate.value, now)) {
        final currentTime = TimeOfDay.fromDateTime(now);
        final currentMinutes = currentTime.hour * 60 + currentTime.minute;

        slots.removeWhere((slot) {
          final parts = slot.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final slotMinutes = hour * 60 + minute;

          return slotMinutes <= currentMinutes;
        });
      }

      availableTimeSlots.value = slots;

      // If there was a previously selected time that's still available, keep it
      if (selectedTime.value != null &&
          !availableTimeSlots.contains(selectedTime.value)) {
        selectedTime.value = null;
      }

      // If no time is selected and slots are available, select the first one
      if (selectedTime.value == null && availableTimeSlots.isNotEmpty) {
        selectedTime.value = availableTimeSlots.first;
      }
    } catch (e) {
      debugPrint('Error generating time slots: $e');
    }
  }

  /// Calculate prices
  void _calculatePrices() {
    if (serviceDetails.value == null || providerDetails.value == null) return;

    double price = basePrice.value * quantity.value;

    // Apply emergency rate if selected
    if (useEmergencyRate.value &&
        providerDetails.value!.pricingSettings != null) {
      price +=
          providerDetails.value!.pricingSettings!['emergencyRate'] as double;
    }

    // Apply weekend rate if booking for weekend
    final isWeekend =
        selectedDate.value.weekday == DateTime.saturday ||
        selectedDate.value.weekday == DateTime.sunday;

    if (isWeekend && providerDetails.value!.pricingSettings != null) {
      price += providerDetails.value!.pricingSettings!['weekendRate'] as double;
    }

    totalPrice.value = price;
  }

  /// Change selected date
  void changeSelectedDate(DateTime date) {
    selectedDate.value = date;

    // Regenerate time slots
    _generateTimeSlots();

    // Recalculate price
    _calculatePrices();
  }

  /// Change selected time
  void changeSelectedTime(String time) {
    selectedTime.value = time;
  }

  /// Change selected address
  void changeSelectedAddress(Address address) {
    selectedAddress.value = address;
  }

  /// Change quantity
  void changeQuantity(int value) {
    if (value < 1) return;

    quantity.value = value;
    _calculatePrices();
  }

  /// Toggle emergency rate
  void toggleEmergencyRate(bool value) {
    useEmergencyRate.value = value;
    _calculatePrices();
  }

  /// Change payment method
  void changePaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  /// Validate form
  bool validateForm() {
    if (selectedDate.value == null) {
      showError('Please select a date');
      return false;
    }

    if (selectedTime.value == null) {
      showError('Please select a time');
      return false;
    }

    if (selectedAddress.value == null) {
      showError('Please select an address');
      return false;
    }

    return true;
  }

  /// Create booking
  Future<void> createBooking() {
    if (!validateForm()) {
      return Future.value();
    }

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Create booking object
      final booking = Booking(
        id: '', // Will be generated by the API
        serviceId: serviceId,
        seekerId: userId,
        providerId: providerId,
        status: 'pending',
        bookingDate: selectedDate.value,
        createdAt: DateTime.now(),
        bookingTime: selectedTime.value!,
        address: formatAddress(selectedAddress.value!),
        description: notes.value,
        price: totalPrice.value,
        startTime: combineDateAndTime(selectedDate.value, selectedTime.value!),
        endTime: DateTime.now(), // Will be calculated by the API
        paymentMethod: selectedPaymentMethod.value,
        location: selectedAddress.value!.coordinates,
      );

      // Create booking
      final bookingId = await _bookingAPI.createBooking(booking);

      // Navigate to confirmation screen
      Get.offNamed(
        '/booking-confirmation',
        arguments: {'bookingId': bookingId},
      );
    });
  }

  /// Add new address
  Future<void> addNewAddress(Address address) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Get coordinates for the address
      try {
        final coordinates = await _locationServices.getCoordinatesFromAddress(
          '${address.street}, ${address.city}, ${address.state} ${address.zipCode}, ${address.country}',
        );

        final newAddress = Address(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          label: address.label,
          street: address.street,
          city: address.city,
          state: address.state,
          zipCode: address.zipCode,
          country: address.country,
          isDefault: address.isDefault,
          coordinates:
              '${coordinates.first.latitude},${coordinates.first.longitude}',
        );

        // Add to user's addresses
        final updatedAddresses = [...addresses, newAddress];

        // Update in database
        await _userAPI.updateSeekerAddresses(
          userId,
          updatedAddresses,
          address.isDefault ? newAddress.id : null,
        );

        // Update local state
        addresses.value = updatedAddresses;
        selectedAddress.value = newAddress;

        showSuccess('Address added successfully');
      } catch (e) {
        debugPrint('Error adding address: $e');
        showError('Failed to add address');
      }
    });
  }

  /// Format address
  String formatAddress(Address address) {
    return '${address.street}, ${address.city}, ${address.state} ${address.zipCode}, ${address.country}';
  }

  /// Format date
  String formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
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

  /// Format price
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Combine date and time into a DateTime object
  DateTime combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Get day name
  String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Check if date is selectable
  bool isDateSelectable(DateTime date) {
    if (providerDetails.value == null) return false;

    // Can't book in the past
    if (date.isBefore(DateTime.now()) && !isSameDay(date, DateTime.now())) {
      return false;
    }

    // Check if it's a vacation day
    if (providerDetails.value!.vacationDays.contains(date)) {
      return false;
    }

    // Check if provider works on this day
    final dayOfWeek = date.weekday.toString();
    final workingHours = providerDetails.value!.workingHours[dayOfWeek];

    return workingHours != null && workingHours.isWorking;
  }
}
