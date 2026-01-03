import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/api_services.dart';
import '../base_controller.dart';

class AnalyticsController extends BaseController {
  // Services via dependency injection
  final BookingAPI _bookingAPI = Get.find<BookingAPI>();
  final RxString selectedPeriod = 'week'.obs;

  // Analytics data
  final Rx<Map<String, dynamic>> stats = Rx<Map<String, dynamic>>({});
  final RxList<Map<String, dynamic>> bookingData = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> earningsData =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> serviceData = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    
    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      await loadMockAnalytics();
    });
  }

  Future<void> loadMockAnalytics() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Overall stats
    stats.value = {
      'totalBookings': 48,
      'completedBookings': 42,
      'canceledBookings': 6,
      'totalEarnings': 3250.0,
      'averageRating': 4.7,
      'reviewCount': 38,
    };

    // Booking data for chart
    bookingData.value = [
      {'date': DateTime.now().subtract(const Duration(days: 6)), 'count': 3},
      {'date': DateTime.now().subtract(const Duration(days: 5)), 'count': 2},
      {'date': DateTime.now().subtract(const Duration(days: 4)), 'count': 4},
      {'date': DateTime.now().subtract(const Duration(days: 3)), 'count': 1},
      {'date': DateTime.now().subtract(const Duration(days: 2)), 'count': 3},
      {'date': DateTime.now().subtract(const Duration(days: 1)), 'count': 2},
      {'date': DateTime.now(), 'count': 3},
    ];

    // Earnings data for chart
    earningsData.value = [
      {
        'date': DateTime.now().subtract(const Duration(days: 6)),
        'amount': 250.0,
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'amount': 180.0,
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 4)),
        'amount': 320.0,
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'amount': 90.0,
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'amount': 240.0,
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'amount': 160.0,
      },
      {'date': DateTime.now(), 'amount': 210.0},
    ];

    // Service popularity data
    serviceData.value = [
      {'name': 'Plumbing Repair', 'count': 18, 'earnings': 1260.0},
      {'name': 'Pipe Installation', 'count': 12, 'earnings': 960.0},
      {'name': 'Drain Cleaning', 'count': 8, 'earnings': 560.0},
      {'name': 'Fixture Installation', 'count': 6, 'earnings': 420.0},
      {'name': 'Leak Detection', 'count': 4, 'earnings': 280.0},
    ];
    
    // No need to manually set isLoading to false
    // since it's handled by the runWithLoading method
  }

  void changePeriod(String period) {
    if (selectedPeriod.value == period) return;
    
    selectedPeriod.value = period;
    
    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      await loadMockAnalytics();
    });
  }

  Widget buildBookingTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index >= 0 && index < bookingData.length) {
      final date = bookingData[index]['date'] as DateTime;
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          DateFormat('E').format(date),
          style: const TextStyle(fontSize: 10),
        ),
      );
    }
    return const Text('');
  }

  Widget buildEarningTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index >= 0 && index < earningsData.length) {
      final date = earningsData[index]['date'] as DateTime;
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          DateFormat('E').format(date),
          style: const TextStyle(fontSize: 10),
        ),
      );
    }
    return const Text('');
  }

  Widget buildLeftTitles(double value, TitleMeta meta) {
    return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10));
  }
}
