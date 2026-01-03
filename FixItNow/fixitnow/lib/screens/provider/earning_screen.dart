import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/provider/earning_controller.dart';
import '../../models/payment_models.dart' as payment;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ProviderEarningsScreen extends StatelessWidget {
  const ProviderEarningsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(EarningController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          PopupMenuButton<String>(
            initialValue: controller.selectedPeriod.value,
            onSelected: (value) {
              controller.changeSelectedPeriod(value);
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'week', child: Text('This Week')),
                  const PopupMenuItem(
                    value: 'month',
                    child: Text('This Month'),
                  ),
                  const PopupMenuItem(value: 'year', child: Text('This Year')),
                ],
          ),
        ],
      ),
      body: Obx(
        () =>
            controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Earnings summary cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Total Earnings',
                              controller.currencyFormat.format(
                                controller.totalEarnings.value,
                              ),
                              Icons.account_balance_wallet,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Pending Payouts',
                              controller.currencyFormat.format(
                                controller.pendingPayouts.value,
                              ),
                              Icons.pending,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Earnings chart
                      Obx(
                        () =>
                            controller.payments.isNotEmpty
                                ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Earnings Trend',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 200,
                                      child: LineChart(
                                        LineChartData(
                                          gridData: const FlGridData(
                                            show: false,
                                          ),
                                          titlesData: const FlTitlesData(
                                            show: false,
                                          ),
                                          borderData: FlBorderData(show: false),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: controller.getChartData(),
                                              isCurved: true,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                              barWidth: 3,
                                              dotData: const FlDotData(
                                                show: false,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                )
                                : const SizedBox.shrink(),
                      ),

                      // Recent transactions
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () =>
                            controller.transactions.isEmpty
                                ? const Center(
                                  child: Text('No transactions in this period'),
                                )
                                : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: controller.transactions.length,
                                  itemBuilder: (context, index) {
                                    final transaction =
                                        controller.transactions[index];
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(Icons.payment),
                                      ),
                                      title: Text(
                                        'Booking #${transaction.bookingId.substring(0, 8)}',
                                      ),
                                      subtitle: Text(
                                        DateFormat.yMMMd().add_jm().format(
                                          transaction.createdAt,
                                        ),
                                      ),
                                      trailing: Chip(
                                        label: Text(
                                          controller.currencyFormat.format(
                                            transaction.amount,
                                          ),
                                          style: TextStyle(
                                            color:
                                                transaction.type == 'payment'
                                                    ? Colors.green
                                                    : Colors.red,
                                          ),
                                        ),
                                        backgroundColor:
                                            transaction.type == 'payment'
                                                ? Colors.green[100]
                                                : Colors.red[100],
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) {
    var index = 0;
    return map((item) => f(index++, item));
  }
}
