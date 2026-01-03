import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../controllers/provider/analytics_controller.dart';
import '../../widgets/common/index.dart';

class ProviderAnalyticsScreen extends StatelessWidget {
  const ProviderAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(AnalyticsController());

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    _buildPeriodSelector(controller),
                    const SizedBox(height: 24),

                    // Stats cards
                    _buildStatsCards(controller, context),
                    const SizedBox(height: 24),

                    // Bookings chart
                    SectionHeader(title: 'Booking Trends'),
                    const SizedBox(height: 8),
                    _buildBookingsChart(controller),
                    const SizedBox(height: 24),

                    // Earnings chart
                    SectionHeader(title: 'Earnings Trends'),
                    const SizedBox(height: 8),
                    _buildEarningsChart(controller),
                    const SizedBox(height: 24),

                    // Popular services
                    SectionHeader(title: 'Popular Services'),
                    const SizedBox(height: 8),
                    _buildPopularServices(controller),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPeriodSelector(AnalyticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPeriodButton(controller, 'week', 'Week'),
            _buildPeriodButton(controller, 'month', 'Month'),
            _buildPeriodButton(controller, 'quarter', 'Quarter'),
            _buildPeriodButton(controller, 'year', 'Year'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(
    AnalyticsController controller,
    String period,
    String label,
  ) {
    return Obx(() {
      final isSelected = controller.selectedPeriod.value == period;
      return TextButton(
        onPressed: () => controller.changePeriod(period),
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Get.theme.primaryColor : null,
          foregroundColor: isSelected ? Colors.white : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label),
      );
    });
  }

  Widget _buildStatsCards(
    AnalyticsController controller,
    BuildContext context,
  ) {
    return Obx(
      () => GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StatCard(
            title: 'Total Bookings',
            value: controller.stats.value['totalBookings'].toString(),
            icon: Icons.calendar_today,
            iconColor: Colors.blue,
            onTap: () => Get.toNamed('/booking-requests'),
          ),
          StatCard(
            title: 'Completed',
            value: controller.stats.value['completedBookings'].toString(),
            icon: Icons.check_circle,
            iconColor: Colors.green,
          ),
          StatCard(
            title: 'Total Earnings',
            value: '\$${controller.stats.value['totalEarnings'].toStringAsFixed(2)}',
            icon: Icons.attach_money,
            iconColor: Colors.amber,
            onTap: () => Get.toNamed('/earnings'),
          ),
          StatCard(
            title: 'Rating',
            value: '${controller.stats.value['averageRating']} (${controller.stats.value['reviewCount']})',
            icon: Icons.star,
            iconColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsChart(AnalyticsController controller) {
    return Obx(
      () => SizedBox(
        height: 200,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${controller.bookingData[groupIndex]['count']} bookings',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: controller.buildBookingTitles,
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups:
                    controller.bookingData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data['count'].toDouble(),
                            color: Colors.blue,
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsChart(AnalyticsController controller) {
    return Obx(
      () => SizedBox(
        height: 200,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 &&
                            index < controller.earningsData.length) {
                          final amount =
                              controller.earningsData[index]['amount']
                                  as double;
                          return LineTooltipItem(
                            '\$${amount.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white),
                          );
                        }
                        return LineTooltipItem('', const TextStyle());
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: controller.buildEarningTitles,
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: controller.buildLeftTitles,
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: controller.earningsData.length - 1.0,
                minY: 0,
                maxY: 400,
                lineBarsData: [
                  LineChartBarData(
                    spots:
                        controller.earningsData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          return FlSpot(
                            index.toDouble(),
                            data['amount'].toDouble(),
                          );
                        }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularServices(AnalyticsController controller) {
    return Obx(
      () => Card(
        elevation: 2,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.serviceData.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final service = controller.serviceData[index];
            return ListTile(
              title: Text(service['name']),
              subtitle: Text('${service['count']} bookings'),
              trailing: Text(
                '\$${service['earnings'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}