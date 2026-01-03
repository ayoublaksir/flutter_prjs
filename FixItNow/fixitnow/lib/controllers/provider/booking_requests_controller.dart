import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_services.dart';
import '../../services/credit_services.dart';
import '../../models/booking_models.dart';
import '../../models/user_models.dart';
import '../../models/credit_models.dart';
import '../base_controller.dart';

class BookingRequestsController extends BaseController
    with GetSingleTickerProviderStateMixin {
  // Services via dependency injection
  final BookingAPI _bookingAPI = Get.find<BookingAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();
  final CreditService _creditService = CreditService();

  late TabController tabController;
  final RxString userId = ''.obs;
  final RxList<Booking> pendingBookings = <Booking>[].obs;
  final RxList<Booking> confirmedBookings = <Booking>[].obs;
  final RxList<Booking> completedBookings = <Booking>[].obs;
  final Rx<Map<String, ServiceSeeker>> seekers = Rx<Map<String, ServiceSeeker>>(
    {},
  );

  // Credit system
  final Rx<ProviderCreditAccount?> creditAccount = Rx<ProviderCreditAccount?>(
    null,
  );
  final RxBool showCreditWarning = false.obs;
  final RxInt creditsNeeded = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);

    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      await loadMockBookings();
      await loadCreditAccount();
    });
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> loadCreditAccount() async {
    try {
      final account = await _creditService.getProviderCreditAccount();
      creditAccount.value = account;
    } catch (e) {
      print('Error loading credit account: $e');
    }
  }

  Future<void> loadMockBookings() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    pendingBookings.value = List.generate(
      5,
      (index) => Booking(
        id: 'booking-$index',
        serviceId: 'service-$index',
        seekerId: 'seeker-$index',
        providerId: 'provider-1',
        status: index < 2 ? 'pending' : (index < 4 ? 'confirmed' : 'completed'),
        bookingDate: DateTime.now().add(Duration(days: index)),
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        bookingTime: '${9 + index}:00 AM',
        address: '${123 + index} Main St, City',
        description: 'Service booking ${index + 1}',
        price: 50.0 + (index * 10),
        startTime: DateTime.now().add(Duration(days: index, hours: 9 + index)),
        endTime: DateTime.now().add(Duration(days: index, hours: 11 + index)),
        paymentMethod: 'Credit Card',
        location: '37.7749,-122.4194',
      ),
    );

    confirmedBookings.value = List.generate(
      5,
      (index) => Booking(
        id: 'booking-${index + 5}',
        serviceId: 'service-${index + 5}',
        seekerId: 'seeker-${index + 5}',
        providerId: 'provider-1',
        status: index < 2 ? 'pending' : (index < 4 ? 'confirmed' : 'completed'),
        bookingDate: DateTime.now().add(Duration(days: index + 5)),
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        bookingTime: '${9 + index + 5}:00 AM',
        address: '${123 + index + 5} Main St, City',
        description: 'Service booking ${index + 6}',
        price: 50.0 + ((index + 5) * 10),
        startTime: DateTime.now().add(
          Duration(days: index + 5, hours: 9 + index + 5),
        ),
        endTime: DateTime.now().add(
          Duration(days: index + 5, hours: 11 + index + 5),
        ),
        paymentMethod: 'Credit Card',
        location: '37.7749,-122.4194',
      ),
    );

    completedBookings.value = List.generate(
      5,
      (index) => Booking(
        id: 'booking-${index + 10}',
        serviceId: 'service-${index + 10}',
        seekerId: 'seeker-${index + 10}',
        providerId: 'provider-1',
        status: index < 2 ? 'pending' : (index < 4 ? 'confirmed' : 'completed'),
        bookingDate: DateTime.now().add(Duration(days: index + 10)),
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        bookingTime: '${9 + index + 10}:00 AM',
        address: '${123 + index + 10} Main St, City',
        description: 'Service booking ${index + 11}',
        price: 50.0 + ((index + 10) * 10),
        startTime: DateTime.now().add(
          Duration(days: index + 10, hours: 9 + index + 10),
        ),
        endTime: DateTime.now().add(
          Duration(days: index + 10, hours: 11 + index + 10),
        ),
        paymentMethod: 'Credit Card',
        location: '37.7749,-122.4194',
      ),
    );

    Map<String, ServiceSeeker> seekersMap = {};

    for (var booking in pendingBookings) {
      seekersMap[booking.seekerId] = ServiceSeeker(
        id: booking.seekerId,
        name: 'Client ${booking.seekerId.substring(7)}',
        email: 'client${booking.seekerId.substring(7)}@example.com',
        phone: '555-000-${booking.seekerId.substring(7)}',
        createdAt: DateTime.now(),
        settings: UserSettings(
          pushNotifications: true,
          emailNotifications: true,
          smsNotifications: false,
          language: 'English',
          theme: 'light',
        ),
      );
    }

    for (var booking in confirmedBookings) {
      seekersMap[booking.seekerId] = ServiceSeeker(
        id: booking.seekerId,
        name: 'Client ${booking.seekerId.substring(7)}',
        email: 'client${booking.seekerId.substring(7)}@example.com',
        phone: '555-000-${booking.seekerId.substring(7)}',
        createdAt: DateTime.now(),
        settings: UserSettings(
          pushNotifications: true,
          emailNotifications: true,
          smsNotifications: false,
          language: 'English',
          theme: 'light',
        ),
      );
    }

    for (var booking in completedBookings) {
      seekersMap[booking.seekerId] = ServiceSeeker(
        id: booking.seekerId,
        name: 'Client ${booking.seekerId.substring(7)}',
        email: 'client${booking.seekerId.substring(7)}@example.com',
        phone: '555-000-${booking.seekerId.substring(7)}',
        createdAt: DateTime.now(),
        settings: UserSettings(
          pushNotifications: true,
          emailNotifications: true,
          smsNotifications: false,
          language: 'English',
          theme: 'light',
        ),
      );
    }

    seekers.value = seekersMap;
    // No need to manually set isLoading to false
    // since it's handled by the runWithLoading method
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) {
    return runWithLoading(() async {
      // Check if this is an acceptance and requires credits
      if (newStatus == 'confirmed') {
        final result = await checkAndDeductCredits(bookingId);
        if (!result['success']) {
          showCreditWarning.value = true;
          creditsNeeded.value =
              result['creditsNeeded'] ??
              5; // Default to 5 credits if not specified
          throw Exception('Insufficient credits');
        }
      }

      await _bookingAPI.updateBookingStatus(
        bookingId: bookingId,
        status: newStatus,
      );
      await loadMockBookings();
      showSuccess('Booking status updated successfully');
    });
  }

  Future<Map<String, dynamic>> checkAndDeductCredits(String bookingId) async {
    try {
      // Determine how many credits are needed for this booking type
      final creditsRequired = 5; // Example: 5 credits per booking acceptance

      // Check if provider has enough credits
      final account = creditAccount.value;
      if (account == null) {
        await loadCreditAccount();
      }

      if (creditAccount.value == null ||
          creditAccount.value!.currentBalance < creditsRequired) {
        return {
          'success': false,
          'message': 'Not enough credits',
          'creditsNeeded': creditsRequired,
          'currentBalance': creditAccount.value?.currentBalance ?? 0,
        };
      }

      // Hold credits
      final holdResult = await _creditService.holdCreditsForOffer(
        amount: creditsRequired,
        requestId: bookingId,
      );

      if (!holdResult['success']) {
        return {
          'success': false,
          'message': holdResult['message'] ?? 'Failed to hold credits',
        };
      }

      // Credits were successfully held
      return {
        'success': true,
        'message': 'Credits successfully held',
        'holdId': holdResult['holdId'],
      };
    } catch (e) {
      print('Error checking credits: $e');
      return {'success': false, 'message': 'Error checking credits: $e'};
    }
  }

  // Apply the held credits when the booking is confirmed
  Future<void> applyHeldCredits(String holdId, String bookingId) async {
    try {
      final result = await _creditService.applyCreditHold(
        holdId: holdId,
        bookingId: bookingId,
      );

      if (!result['success']) {
        print('Warning: Failed to apply credit hold: ${result['message']}');
      }

      // Refresh credit account
      await loadCreditAccount();
    } catch (e) {
      print('Error applying credit hold: $e');
    }
  }

  // Navigate to credits page
  void navigateToBuyCredits() {
    Get.toNamed('/provider/credits/purchase');
  }
}
