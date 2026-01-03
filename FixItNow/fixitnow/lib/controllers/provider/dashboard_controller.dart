import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/booking_models.dart';
import '../../services/api_services.dart';
import '../../models/user_models.dart';
import '../base_controller.dart';

class DashboardController extends BaseController {
  // Services via dependency injection
  final BookingAPI _bookingAPI = Get.find<BookingAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();
  final Rx<ServiceProvider?> providerProfile = Rx<ServiceProvider?>(null);
  final RxList<Booking> recentBookings = <Booking>[].obs;
  final Rx<Map<String, dynamic>> stats = Rx<Map<String, dynamic>>({
    'totalBookings': 0,
    'pendingBookings': 0,
    'completedBookings': 0,
    'totalEarnings': 0.0,
  });

  @override
  void onInit() {
    super.onInit();
    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      // Keep using mock data for now
      await loadMockDashboardData();
      // Later we can switch to real API calls:
      // await loadDashboardData();
    });
  }

  Future<void> loadMockDashboardData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock provider profile
    providerProfile.value = ServiceProvider(
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
    );

    // Mock recent bookings
    recentBookings.value = List.generate(
      3,
      (index) => Booking(
        id: 'booking-$index',
        serviceId: 'service-$index',
        seekerId: 'seeker-$index',
        providerId: 'provider-1',
        status:
            index == 0 ? 'pending' : (index == 1 ? 'confirmed' : 'completed'),
        bookingDate: DateTime.now().add(Duration(days: index)),
        createdAt: DateTime.now().subtract(Duration(days: index)),
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

    // Mock stats
    stats.value = {
      'totalBookings': 24,
      'pendingBookings': 3,
      'completedBookings': 18,
      'totalEarnings': 1250.0,
    };
    
    // No need to manually set isLoading to false
    // since it's handled by the runWithLoading method
  }

  // Real API implementation - will replace mock data when ready
  Future<void> loadDashboardData() async {
    // We don't need try/catch here as it's handled by the runWithLoading method
    // Get current user ID directly from BaseController
    final userId = currentUserId;
    if (userId.isNotEmpty) {
      // Load provider profile
      final provider = await _userAPI.getProviderProfile(userId);
      
      // Load recent bookings
      final bookings = await _bookingAPI.getProviderRecentBookings(
        userId,
        limit: 3,
      );
      
      // Load dashboard stats
      final dashboardStats = await _bookingAPI.getProviderBookingStats(userId);
      
      // Update state
      providerProfile.value = provider;
      recentBookings.value = bookings;
      stats.value = dashboardStats;
    } else {
      showError('User not authenticated');
    }
  }

  Widget buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        capitalize(status),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String capitalize(String s) {
    return s.isNotEmpty ? "${s[0].toUpperCase()}${s.substring(1)}" : "";
  }
}
