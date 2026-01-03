import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/booking_models.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final BookingAPI _bookingAPI = BookingAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Booking>> _bookings = {};

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final bookings = await _bookingAPI.getProviderBookings(
          user.uid,
          startDate: DateTime(_focusedDay.year, _focusedDay.month, 1),
          endDate: DateTime(_focusedDay.year, _focusedDay.month + 1, 0),
        );

        final bookingMap = <DateTime, List<Booking>>{};
        for (final booking in bookings) {
          final date = DateTime(
            booking.bookingDate.year,
            booking.bookingDate.month,
            booking.bookingDate.day,
          );
          bookingMap[date] = [...(bookingMap[date] ?? []), booking];
        }

        setState(() => _bookings = bookingMap);
      }
    } catch (e) {
      print('Error loading schedule: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading schedule')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2025, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadSchedule();
                    },
                    eventLoader: (day) => _bookings[day] ?? [],
                  ),
                  Expanded(child: _buildBookingsList()),
                ],
              ),
    );
  }

  Widget _buildBookingsList() {
    final dayBookings = _bookings[_selectedDay] ?? [];

    if (dayBookings.isEmpty) {
      return const Center(child: Text('No bookings for this day'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayBookings.length,
      itemBuilder: (context, index) {
        final booking = dayBookings[index];
        return Card(
          child: ListTile(
            title: Text('Booking #${booking.id}'),
            subtitle: Text('Time: ${booking.bookingTime}'),
            trailing: Chip(
              label: Text(booking.status),
              backgroundColor:
                  booking.status == 'confirmed'
                      ? Colors.green[100]
                      : Colors.orange[100],
            ),
          ),
        );
      },
    );
  }
}
