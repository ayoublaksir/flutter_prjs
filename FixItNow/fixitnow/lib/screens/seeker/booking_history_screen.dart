import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/booking_models.dart';
import '../../models/service_models.dart';
import '../../routes.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  final BookingAPI _bookingAPI = BookingAPI();
  final AuthService _authService = AuthService();
  final ServiceAPI _serviceAPI = ServiceAPI();

  late TabController _tabController;
  bool _isLoading = true;
  List<Booking> _upcomingBookings = [];
  List<Booking> _completedBookings = [];
  List<Booking> _cancelledBookings = [];
  Map<String, ProviderService> _services = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final bookings = await _bookingAPI.getSeekerBookings(user.uid);

        // Load service details for all bookings
        final serviceIds = bookings.map((b) => b.serviceId).toSet();
        final services = await Future.wait(
          serviceIds.map((id) => _serviceAPI.getServiceDetails(id)),
        );

        setState(() {
          _upcomingBookings =
              bookings
                  .where(
                    (b) =>
                        b.status == 'pending' ||
                        b.status == 'confirmed' ||
                        b.status == 'in_progress',
                  )
                  .toList();
          _completedBookings =
              bookings.where((b) => b.status == 'completed').toList();
          _cancelledBookings =
              bookings.where((b) => b.status == 'cancelled').toList();
          _services = {
            for (var service in services.whereType<ProviderService>())
              service.id: service,
          };
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading bookings')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _bookingAPI.updateBookingStatus(
        bookingId: bookingId,
        status: 'cancelled',
      );
      _loadBookings();
    } catch (e) {
      print('Error cancelling booking: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error cancelling booking')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingList(_upcomingBookings, canCancel: true),
                  _buildBookingList(_completedBookings),
                  _buildBookingList(_cancelledBookings),
                ],
              ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, {bool canCancel = false}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No bookings found'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.search);
              },
              child: const Text('Book a Service'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final service = _services[booking.serviceId];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.bookingDetails,
                arguments: {'bookingId': booking.id},
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service?.name ?? 'Service',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _buildStatusChip(booking.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(booking.bookingDate),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(_formatTimeString(booking.bookingTime)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(booking.location)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${booking.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (canCancel && booking.status == 'pending')
                        TextButton(
                          onPressed: () => _cancelBooking(booking.id),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'confirmed':
        color = Colors.blue;
        label = 'Confirmed';
        break;
      case 'in_progress':
        color = Colors.purple;
        label = 'In Progress';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) return timeString;

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
