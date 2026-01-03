import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/booking_models.dart';
import '../../models/provider_models.dart' as provider_models;
import '../../services/api_services.dart';
import '../base_controller.dart';

class ScheduleController extends BaseController {
  // Services via dependency injection
  final BookingAPI _bookingAPI = Get.find<BookingAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();

  // Reactive state
  final RxList<Booking> bookings = <Booking>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rx<Map<String, List<Booking>>> bookingsByDate =
      Rx<Map<String, List<Booking>>>({});
  final Rx<Map<String, provider_models.WorkingHours>> workingHours =
      Rx<Map<String, provider_models.WorkingHours>>({});
  final RxList<DateTime> vacationDays = <DateTime>[].obs;

  // UI state
  final ScrollController scrollController = ScrollController();
  final Rx<CalendarView> calendarView = CalendarView.week.obs;

  @override
  void onInit() {
    super.onInit();
    loadScheduleData();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Load schedule data
  Future<void> loadScheduleData() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Load provider's working hours and vacation days
      final provider = await _userAPI.getProviderProfile(userId);
      if (provider != null) {
        workingHours.value = Map<String, provider_models.WorkingHours>.from(
          provider.workingHours ?? {},
        );
        vacationDays.value = provider.vacationDays ?? [];
      }

      // Load bookings
      await loadBookingsForMonth(selectedDate.value);
    });
  }

  /// Load bookings for a specific month
  Future<void> loadBookingsForMonth(DateTime month) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final firstDayOfMonth = DateTime(month.year, month.month, 1);
      final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

      final bookingsList = await _bookingAPI.getProviderBookings(
        userId,
        startDate: firstDayOfMonth,
        endDate: lastDayOfMonth,
      );

      bookings.value = bookingsList;

      // Group bookings by date
      final Map<String, List<Booking>> grouped = {};
      for (final booking in bookingsList) {
        final dateKey = DateFormat('yyyy-MM-dd').format(booking.bookingDate);
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(booking);
      }

      bookingsByDate.value = grouped;
    });
  }

  /// Change selected date
  void changeSelectedDate(DateTime date) {
    selectedDate.value = date;

    // If changing month, reload bookings
    if (date.month != selectedDate.value.month ||
        date.year != selectedDate.value.year) {
      loadBookingsForMonth(date);
    }
  }

  /// Change calendar view
  void changeCalendarView(CalendarView view) {
    calendarView.value = view;
  }

  /// Toggle working day status
  Future<void> toggleWorkingDay(String dayKey, bool isWorking) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final currentHours = workingHours.value[dayKey];
      final updatedHours = provider_models.WorkingHours(
        isWorking: isWorking,
        start: currentHours?.start ?? '09:00',
        end: currentHours?.end ?? '17:00',
      );

      final updatedWorkingHours =
          Map<String, provider_models.WorkingHours>.from(workingHours.value);
      updatedWorkingHours[dayKey] = updatedHours;

      await _userAPI.updateProviderWorkingHours(userId, updatedWorkingHours);
      workingHours.value = updatedWorkingHours;

      showSuccess('Working hours updated');
    });
  }

  /// Update working hours for a specific day
  Future<void> updateWorkingHours(String dayKey, String start, String end) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final currentHours = workingHours.value[dayKey];
      final updatedHours = provider_models.WorkingHours(
        isWorking: currentHours?.isWorking ?? true,
        start: start,
        end: end,
      );

      final updatedWorkingHours =
          Map<String, provider_models.WorkingHours>.from(workingHours.value);
      updatedWorkingHours[dayKey] = updatedHours;

      await _userAPI.updateProviderWorkingHours(userId, updatedWorkingHours);
      workingHours.value = updatedWorkingHours;

      showSuccess('Working hours updated');
    });
  }

  /// Add vacation day
  Future<void> addVacationDay(DateTime date) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Check if date already exists
      if (vacationDays.any((d) => isSameDay(d, date))) {
        showInfo('This date is already marked as vacation');
        return;
      }

      final updatedVacationDays = [...vacationDays, date];
      await _userAPI.updateProviderVacationDays(userId, updatedVacationDays);
      vacationDays.value = updatedVacationDays;

      showSuccess('Vacation day added');
    });
  }

  /// Remove vacation day
  Future<void> removeVacationDay(DateTime date) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final updatedVacationDays =
          vacationDays.where((d) => !isSameDay(d, date)).toList();
      await _userAPI.updateProviderVacationDays(userId, updatedVacationDays);
      vacationDays.value = updatedVacationDays;

      showSuccess('Vacation day removed');
    });
  }

  /// Complete a booking
  Future<void> completeBooking(String bookingId) {
    return runWithLoading(() async {
      await _bookingAPI.updateBookingStatus(
        bookingId: bookingId,
        status: 'completed',
      );

      // Refresh bookings
      await loadBookingsForMonth(selectedDate.value);

      showSuccess('Booking marked as completed');
    });
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, String reason) {
    return runWithLoading(() async {
      await _bookingAPI.updateBookingStatus(
        bookingId: bookingId,
        status: 'cancelled',
      );

      // Store cancellation reason in a separate update
      await _bookingAPI.updateBookingNotes(bookingId, reason);

      // Refresh bookings
      await loadBookingsForMonth(selectedDate.value);

      showSuccess('Booking cancelled');
    });
  }

  /// Reschedule a booking
  Future<void> rescheduleBooking(
    String bookingId,
    DateTime newDate,
    String newTime,
  ) {
    return runWithLoading(() async {
      // Get the current booking
      final booking = await _bookingAPI.getBooking(bookingId);
      if (booking == null) {
        showError('Booking not found');
        return;
      }

      // Update booking with new date and time
      await _bookingAPI.updateBookingDateTime(
        bookingId: bookingId,
        date: newDate,
        time: newTime,
      );

      // Refresh bookings
      await loadBookingsForMonth(selectedDate.value);

      showSuccess('Booking rescheduled');
    });
  }

  // Helper methods

  /// Get bookings for a specific date
  List<Booking> getBookingsForDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return bookingsByDate.value[dateKey] ?? [];
  }

  /// Check if a date is a working day
  bool isWorkingDay(DateTime date) {
    // First check if it's a vacation day
    if (isVacationDay(date)) {
      return false;
    }

    // Then check working hours for that day of week
    final dayOfWeek = date.weekday.toString();
    final hours = workingHours.value[dayOfWeek];

    return hours?.isWorking ?? false;
  }

  /// Check if a date is a vacation day
  bool isVacationDay(DateTime date) {
    return vacationDays.any((d) => isSameDay(d, date));
  }

  /// Compare if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Format date
  String formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  /// Format time
  String formatTime(String time) {
    // Convert 24-hour format to 12-hour format
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  /// Get working hours for a specific day
  provider_models.WorkingHours? getWorkingHoursForDay(int dayOfWeek) {
    return workingHours.value[dayOfWeek.toString()];
  }

  /// Get color for booking status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

enum CalendarView { day, week, month }
