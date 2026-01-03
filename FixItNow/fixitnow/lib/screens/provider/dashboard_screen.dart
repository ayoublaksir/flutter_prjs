// screens/provider/dashboard_screen.dart
// Provider dashboard screen

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/provider/dashboard_controller.dart';
import '../../routes.dart';
import '../../widgets/common/index.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider info card
                    _buildProviderInfoCard(controller),
                    const SizedBox(height: 24),

                    // Stats overview
                    SectionHeader(title: 'Overview'),
                    const SizedBox(height: 16),
                    _buildStatsOverview(controller),
                    const SizedBox(height: 24),

                    // Recent bookings
                    SectionHeader(
                      title: 'Recent Bookings',
                      actionText: 'View All',
                      onAction: () => Get.toNamed(AppRoutes.bookingRequests),
                    ),
                    const SizedBox(height: 8),
                    _buildRecentBookings(controller),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProviderInfoCard(DashboardController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ProfileAvatar(
              imageUrl: controller.providerProfile.value?.profileImage,
              radius: 30,
              iconSize: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.providerProfile.value?.name ?? 'Provider',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RatingDisplay(
                    rating: controller.providerProfile.value?.rating ?? 0,
                    reviewCount: controller.providerProfile.value?.reviewCount ?? 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(DashboardController controller) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          title: 'Total Bookings',
          value: controller.stats.value['totalBookings'].toString(),
          icon: Icons.calendar_today,
          iconColor: Colors.blue,
          onTap: () => Get.toNamed(AppRoutes.bookingRequests),
        ),
        StatCard(
          title: 'Pending',
          value: controller.stats.value['pendingBookings'].toString(),
          icon: Icons.pending_actions,
          iconColor: Colors.orange,
          onTap: () => Get.toNamed(AppRoutes.bookingRequests),
        ),
        StatCard(
          title: 'Earnings',
          value: '\$${controller.stats.value['totalEarnings']}',
          icon: Icons.attach_money,
          iconColor: Colors.purple,
          onTap: () => Get.toNamed(AppRoutes.earnings),
        ),
        StatCard(
          title: 'Analytics',
          value: 'View',
          icon: Icons.analytics,
          iconColor: Colors.green,
          onTap: () => Get.toNamed(AppRoutes.analytics),
        ),
      ],
    );
  }

  Widget _buildRecentBookings(DashboardController controller) {
    return Obx(
      () => controller.recentBookings.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No recent bookings'),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.recentBookings.length,
              itemBuilder: (context, index) {
                final booking = controller.recentBookings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text('Service ${index + 1}'),
                    subtitle: Text(
                      'Client ${index + 1} • ${controller.formatDate(booking.bookingDate)}',
                    ),
                    trailing: StatusChip(status: booking.status),
                    onTap: () {
                      Get.toNamed(
                        AppRoutes.bookingDetails,
                        arguments: {'bookingId': booking.id},
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}