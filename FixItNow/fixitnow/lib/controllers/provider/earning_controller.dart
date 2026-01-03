import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/booking_models.dart';
import '../../models/payment_models.dart' as payment;
import '../../services/api_services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../base_controller.dart';

class EarningController extends BaseController {
  // Services via dependency injection
  final PaymentAPI _paymentAPI = Get.find<PaymentAPI>();
  final BookingAPI _bookingAPI = Get.find<BookingAPI>();
  final RxString selectedPeriod = 'week'.obs; // week, month, year
  final RxList<payment.Payment> payments = <payment.Payment>[].obs;
  final RxDouble totalEarnings = 0.0.obs;
  final RxDouble pendingPayouts = 0.0.obs;
  final RxList<payment.Transaction> transactions = <payment.Transaction>[].obs;
  final Rx<Map<String, dynamic>> earningStats = Rx<Map<String, dynamic>>({
    'total': 0.0,
    'pending': 0.0,
    'completed': 0.0,
  });

  final currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void onInit() {
    super.onInit();
    
    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      await loadEarnings();
    });
  }

  Future<void> loadEarnings() async {
    // No need for try-catch block as it's handled by runWithLoading
    final userId = currentUserId;
    if (userId.isEmpty) {
      showError('User not authenticated');
      return;
    }
    
    final DateTime startDate;
    switch (selectedPeriod.value) {
      case 'week':
        startDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case 'year':
        startDate = DateTime.now().subtract(const Duration(days: 365));
        break;
      default:
        startDate = DateTime.now().subtract(const Duration(days: 7));
    }

    final results = await Future.wait<dynamic>([
      _paymentAPI.getProviderPayments(userId, startDate),
      _paymentAPI.getPendingPayouts(userId),
    ]);

    payments.value = results[0] as List<payment.Payment>;
    pendingPayouts.value = (results[1] as double?) ?? 0;
    totalEarnings.value = payments.fold(
      0,
      (sum, payment) => sum + payment.amount,
    );
    transactions.clear();
    earningStats.value = {
      'total': totalEarnings.value,
      'pending': pendingPayouts.value,
      'completed': totalEarnings.value - pendingPayouts.value,
    };
  }

  List<FlSpot> getChartData() {
    final Map<String, double> dailyEarnings = {};

    for (final payment in payments) {
      final date = DateFormat('yyyy-MM-dd').format(payment.timestamp);
      dailyEarnings[date] = (dailyEarnings[date] ?? 0) + payment.amount;
    }

    return dailyEarnings.entries.mapIndexed((index, entry) {
      return FlSpot(index.toDouble(), entry.value);
    }).toList();
  }

  void changeSelectedPeriod(String period) {
    if (selectedPeriod.value == period) return;
    
    selectedPeriod.value = period;
    
    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      await loadEarnings();
    });
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) {
    var index = 0;
    return map((item) => f(index++, item));
  }
}
