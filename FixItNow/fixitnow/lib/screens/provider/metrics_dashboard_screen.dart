import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/provider_models.dart';
import '../../models/booking_models.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';

class ProviderMetricsDashboardScreen extends StatefulWidget {
  const ProviderMetricsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProviderMetricsDashboardScreen> createState() =>
      _ProviderMetricsDashboardScreenState();
}

class _ProviderMetricsDashboardScreenState
    extends State<ProviderMetricsDashboardScreen>
    with SingleTickerProviderStateMixin {
  final BookingAPI _bookingAPI = BookingAPI();
  final UserAPI _userAPI = UserAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  late TabController _tabController;

  // Metrics data
  int _totalBookings = 0;
  int _completedBookings = 0;
  int _cancelledBookings = 0;
  double _totalEarnings = 0;
  double _averageRating = 0;
  List<Booking> _recentBookings = [];

  // Chart data
  List<FlSpot> _earningsData = [];
  List<FlSpot> _bookingsData = [];
  String _selectedPeriod = 'Monthly'; // Weekly, Monthly, Yearly

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMetricsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetricsData() async {
    setState(() => _isLoading = true);

    try {
      final providerId = _authService.currentUser?.uid;
      if (providerId == null) {
        throw Exception('User not authenticated');
      }

      // Get provider bookings
      final bookings = await _bookingAPI.getProviderBookings(providerId);

      // Calculate metrics
      _totalBookings = bookings.length;
      _completedBookings =
          bookings.where((b) => b.status == 'completed').length;
      _cancelledBookings =
          bookings.where((b) => b.status == 'cancelled').length;

      // Calculate earnings
      _totalEarnings = bookings
          .where((b) => b.status == 'completed')
          .fold(0, (sum, booking) => sum + booking.price);

      // Get provider ratings
      final provider = await _userAPI.getProviderProfile(providerId);
      _averageRating = provider?.rating ?? 0;

      // Get recent bookings
      _recentBookings =
          bookings.where((b) => b.status == 'completed').take(5).toList();

      // Prepare chart data
      _prepareChartData(bookings);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load metrics data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _prepareChartData(List<Booking> bookings) {
    // Sort bookings by date
    bookings.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    // Group by period
    final Map<DateTime, double> earningsByDate = {};
    final Map<DateTime, int> bookingsByDate = {};

    DateTime Function(DateTime) getPeriodStart;

    switch (_selectedPeriod) {
      case 'Weekly':
        getPeriodStart =
            (date) =>
                DateTime(date.year, date.month, date.day - date.weekday % 7);
        break;
      case 'Yearly':
        getPeriodStart = (date) => DateTime(date.year, 1, 1);
        break;
      case 'Monthly':
      default:
        getPeriodStart = (date) => DateTime(date.year, date.month, 1);
        break;
    }

    for (final booking in bookings.where((b) => b.status == 'completed')) {
      final periodStart = getPeriodStart(booking.bookingDate);

      earningsByDate[periodStart] =
          (earningsByDate[periodStart] ?? 0) + booking.price;
      bookingsByDate[periodStart] = (bookingsByDate[periodStart] ?? 0) + 1;
    }

    // Convert to FlSpot data points
    final earningsEntries =
        earningsByDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final bookingsEntries =
        bookingsByDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Using relative x values for the chart (0, 1, 2, etc.)
    _earningsData =
        earningsEntries
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
            .toList();

    _bookingsData =
        bookingsEntries
            .asMap()
            .entries
            .map(
              (entry) =>
                  FlSpot(entry.key.toDouble(), entry.value.value.toDouble()),
            )
            .toList();
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadMetricsData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Performance Metrics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Metrics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Earnings'),
            Tab(text: 'Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildEarningsTab(),
          _buildBookingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary metrics cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Bookings',
                  value: _totalBookings.toString(),
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Completion Rate',
                  value:
                      _totalBookings > 0
                          ? '${(_completedBookings / _totalBookings * 100).round()}%'
                          : '0%',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Avg. Rating',
                  value: _averageRating.toStringAsFixed(1),
                  icon: Icons.star,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Earnings',
                  value: '\$${_totalEarnings.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          // Period selector
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Trend',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPeriodButton('Weekly'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('Monthly'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('Yearly'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child:
                        _earningsData.isEmpty
                            ? const Center(
                              child: Text('No earnings data available'),
                            )
                            : LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >=
                                            _earningsData.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(value.toInt().toString()),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _earningsData,
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 4,
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
                ],
              ),
            ),
          ),

          // Recent bookings
          const SizedBox(height: 24),
          Text(
            'Recent Bookings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _recentBookings.isEmpty
              ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No recent bookings')),
                ),
              )
              : Column(
                children:
                    _recentBookings
                        .map((booking) => _buildBookingItem(booking))
                        .toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings summary
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earnings Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildEarningsMetric(
                        title: 'Total',
                        amount: _totalEarnings,
                      ),
                      _buildEarningsMetric(
                        title: 'Average',
                        amount:
                            _totalBookings > 0
                                ? _totalEarnings / _completedBookings
                                : 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Earnings chart
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earnings Trend',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPeriodButton('Weekly'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('Monthly'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('Yearly'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child:
                        _earningsData.isEmpty
                            ? const Center(
                              child: Text('No earnings data available'),
                            )
                            : LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _earningsData,
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 4,
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
                ],
              ),
            ),
          ),

          // Payout history (placeholder)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payout History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.account_balance, color: Colors.blue),
                    title: Text('Deposit to Bank Account'),
                    subtitle: Text('07/15/2023'),
                    trailing: Text('\$120.00'),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.account_balance, color: Colors.blue),
                    title: Text('Deposit to Bank Account'),
                    subtitle: Text('06/30/2023'),
                    trailing: Text('\$85.50'),
                  ),
                  const Divider(),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // View all payouts
                      },
                      child: const Text('View All Payouts'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking statistics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Completed',
                  value: _completedBookings.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Cancelled',
                  value: _cancelledBookings.toString(),
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Booking trend chart
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Trend',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPeriodButton('Weekly'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('Monthly'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('Yearly'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child:
                        _bookingsData.isEmpty
                            ? const Center(
                              child: Text('No bookings data available'),
                            )
                            : LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _bookingsData,
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.blue.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),

          // Service popularity (placeholder)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Popularity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: 8,
                                color: Colors.blue,
                                width: 20,
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: 12,
                                color: Colors.blue,
                                width: 20,
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: 5,
                                color: Colors.blue,
                                width: 20,
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(
                                toY: 9,
                                color: Colors.blue,
                                width: 20,
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 4,
                            barRods: [
                              BarChartRodData(
                                toY: 4,
                                color: Colors.blue,
                                width: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text('Plumbing'),
                      Text('Cleaning'),
                      Text('Repair'),
                      Text('Install'),
                      Text('Other'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsMetric({required String title, required double amount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;

    return ElevatedButton(
      onPressed: () => _changePeriod(period),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(period),
    );
  }

  Widget _buildBookingItem(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(booking.serviceId),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(booking.bookingDate)),
        trailing: Text(
          '\$${booking.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        onTap: () {
          // View booking details
        },
      ),
    );
  }
}
