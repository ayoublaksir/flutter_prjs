import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/provider/booking_requests_controller.dart';
import '../../routes.dart';
import '../../models/booking_models.dart';
import '../../widgets/common/index.dart';

class BookingRequestsScreen extends StatelessWidget {
  const BookingRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(BookingRequestsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
        bottom: TabBar(
          controller: controller.tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Obx(
        () =>
            controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                  children: [
                    TabBarView(
                      controller: controller.tabController,
                      children: [
                        _buildBookingList(
                          context,
                          controller,
                          controller.pendingBookings,
                          isPending: true,
                        ),
                        _buildBookingList(
                          context,
                          controller,
                          controller.confirmedBookings,
                        ),
                        _buildBookingList(
                          context,
                          controller,
                          controller.completedBookings,
                        ),
                      ],
                    ),

                    // Credit account banner
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Obx(() {
                        if (controller.showCreditWarning.value) {
                          return _buildCreditWarningBanner(context, controller);
                        } else if (controller.creditAccount.value != null) {
                          return _buildCreditBanner(context, controller);
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildCreditBanner(
    BuildContext context,
    BookingRequestsController controller,
  ) {
    final account = controller.creditAccount.value;
    if (account == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.blue.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Available Credits: ${account.currentBalance}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: controller.navigateToBuyCredits,
            child: const Text('Buy More'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditWarningBanner(
    BuildContext context,
    BookingRequestsController controller,
  ) {
    return Container(
      width: double.infinity,
      color: Colors.red.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Insufficient credits to accept this booking. You need ${controller.creditsNeeded.value} more credits.',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              controller.showCreditWarning.value = false;
              controller.navigateToBuyCredits();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Buy Credits Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    BookingRequestsController controller,
    List<Booking> bookings, {
    bool isPending = false,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          'No ${isPending ? 'pending' : 'confirmed'} bookings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final seeker = controller.seekers.value[booking.seekerId];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ProfileAvatar(
              imageUrl: seeker?.profileImage,
              radius: 20,
              iconSize: 20,
            ),
            title: Text(seeker?.name ?? 'Unknown User'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${_formatDate(booking.bookingDate)}'),
                Text('Time: ${booking.bookingTime}'),
                if (!isPending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: StatusChip(status: booking.status),
                  ),
              ],
            ),
            trailing:
                isPending
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed:
                              () =>
                                  _confirmBooking(context, controller, booking),
                          tooltip: 'Confirm',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed:
                              () => controller.updateBookingStatus(
                                booking.id,
                                'rejected',
                              ),
                          tooltip: 'Reject',
                        ),
                      ],
                    )
                    : const Icon(Icons.chevron_right),
            onTap: () {
              Get.toNamed(
                AppRoutes.bookingDetails,
                arguments: {'bookingId': booking.id},
              );
            },
          ),
        );
      },
    );
  }

  void _confirmBooking(
    BuildContext context,
    BookingRequestsController controller,
    Booking booking,
  ) {
    // Check if the provider has enough credits first
    final account = controller.creditAccount.value;
    if (account == null || account.currentBalance < 5) {
      // Assuming 5 credits needed
      controller.showCreditWarning.value = true;
      controller.creditsNeeded.value = 5 - (account?.currentBalance ?? 0);
      return;
    }

    // If they have enough credits, show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accepting this booking will use 5 credits from your account.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Current balance: ${account.currentBalance} credits'),
                Text(
                  'Balance after confirmation: ${account.currentBalance - 5} credits',
                ),
                const SizedBox(height: 16),
                const Text('Are you sure you want to confirm this booking?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller.updateBookingStatus(booking.id, 'confirmed');
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
