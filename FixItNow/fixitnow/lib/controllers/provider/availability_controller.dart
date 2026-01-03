import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/user_models.dart' as user_models;
import '../../models/provider_models.dart' as provider_models;
import '../../services/api_services.dart';
import '../base_controller.dart';

class AvailabilityController extends BaseController {
  // Services via dependency injection
  final UserAPI _userAPI = Get.find<UserAPI>();

  // Reactive state
  final Rx<Map<String, user_models.WorkingHours>> workingHours =
      Rx<Map<String, user_models.WorkingHours>>({});
  final RxList<DateTime> vacationDays = <DateTime>[].obs;
  final RxList<DateTime> selectedDays = <DateTime>[].obs;

  // Date range for vacation selection
  final Rx<DateTime?> vacationStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> vacationEndDate = Rx<DateTime?>(null);

  // Form validation
  final formKey = GlobalKey<FormState>();

  // Time controllers
  final Map<String, TextEditingController> startTimeControllers = {};
  final Map<String, TextEditingController> endTimeControllers = {};

  @override
  void onInit() {
    super.onInit();

    // Initialize time controllers for each day
    for (int i = 1; i <= 7; i++) {
      startTimeControllers[i.toString()] = TextEditingController();
      endTimeControllers[i.toString()] = TextEditingController();
    }

    loadAvailabilitySettings();
  }

  @override
  void onClose() {
    // Dispose all controllers
    startTimeControllers.forEach((_, controller) => controller.dispose());
    endTimeControllers.forEach((_, controller) => controller.dispose());
    super.onClose();
  }

  /// Load availability settings
  Future<void> loadAvailabilitySettings() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final provider = await _userAPI.getProviderProfile(userId);
      if (provider != null) {
        // Working hours
        final hours = provider.workingHours ?? {};
        workingHours.value = hours;

        // Initialize time controllers with loaded values
        hours.forEach((day, hours) {
          if (hours.isWorking) {
            startTimeControllers[day]?.text = hours.start;
            endTimeControllers[day]?.text = hours.end;
          } else {
            startTimeControllers[day]?.text = '09:00';
            endTimeControllers[day]?.text = '17:00';
          }
        });

        // For days not in the map, initialize with defaults
        for (int i = 1; i <= 7; i++) {
          final day = i.toString();
          if (!hours.containsKey(day)) {
            startTimeControllers[day]?.text = '09:00';
            endTimeControllers[day]?.text = '17:00';
          }
        }

        // Vacation days
        vacationDays.value = provider.vacationDays ?? [];
      }
    });
  }

  /// Save working hours
  Future<void> saveWorkingHours() {
    if (!formKey.currentState!.validate()) {
      showError('Please correct the errors in the form');
      return Future.value();
    }

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Create updated working hours map
      final Map<String, user_models.WorkingHours> updatedHours = {};

      workingHours.value.forEach((day, hours) {
        updatedHours[day] = user_models.WorkingHours(
          isWorking: hours.isWorking,
          start: startTimeControllers[day]?.text ?? hours.start,
          end: endTimeControllers[day]?.text ?? hours.end,
        );
      });

      // Convert to provider_models.WorkingHours for API call
      final Map<String, provider_models.WorkingHours> apiHours = {};
      updatedHours.forEach((day, hours) {
        apiHours[day] = provider_models.WorkingHours(
          isWorking: hours.isWorking,
          start: hours.start,
          end: hours.end,
        );
      });

      await _userAPI.updateProviderWorkingHours(userId, apiHours);
      workingHours.value = updatedHours;

      showSuccess('Working hours updated successfully');
    });
  }

  /// Toggle working day
  void toggleWorkingDay(String day, bool isWorking) {
    final updatedHours = Map<String, user_models.WorkingHours>.from(
      workingHours.value,
    );

    updatedHours[day] = user_models.WorkingHours(
      isWorking: isWorking,
      start: startTimeControllers[day]?.text ?? '09:00',
      end: endTimeControllers[day]?.text ?? '17:00',
    );

    workingHours.value = updatedHours;
  }

  /// Set time for a day
  void setTime(String day, String type, String time) {
    final updatedHours = Map<String, user_models.WorkingHours>.from(
      workingHours.value,
    );
    final currentHours =
        updatedHours[day] ??
        user_models.WorkingHours(isWorking: true, start: '09:00', end: '17:00');

    if (type == 'start') {
      updatedHours[day] = user_models.WorkingHours(
        isWorking: currentHours.isWorking,
        start: time,
        end: currentHours.end,
      );
      startTimeControllers[day]?.text = time;
    } else {
      updatedHours[day] = user_models.WorkingHours(
        isWorking: currentHours.isWorking,
        start: currentHours.start,
        end: time,
      );
      endTimeControllers[day]?.text = time;
    }

    workingHours.value = updatedHours;
  }

  /// Add vacation days
  Future<void> addVacationDays() {
    if (vacationStartDate.value == null) {
      showError('Please select a start date');
      return Future.value();
    }

    final start = vacationStartDate.value!;
    final end = vacationEndDate.value ?? start;

    // Validate dates
    if (end.isBefore(start)) {
      showError('End date cannot be before start date');
      return Future.value();
    }

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Generate list of dates
      final days = <DateTime>[];
      for (
        DateTime date = start;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))
      ) {
        days.add(DateTime(date.year, date.month, date.day));
      }

      // Filter out existing vacation days
      final newDays =
          days
              .where(
                (day) =>
                    !vacationDays.any((existing) => isSameDay(existing, day)),
              )
              .toList();

      if (newDays.isEmpty) {
        showInfo('All selected days are already marked as vacation');
        return;
      }

      // Add to existing vacation days
      final updatedVacationDays = [...vacationDays, ...newDays];

      // Update provider profile
      await _userAPI.updateProviderVacationDays(userId, updatedVacationDays);

      // Update local state
      vacationDays.value = updatedVacationDays;

      // Reset selection
      vacationStartDate.value = null;
      vacationEndDate.value = null;

      showSuccess('Vacation days added successfully');
    });
  }

  /// Remove vacation day
  Future<void> removeVacationDay(DateTime day) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Remove from list
      final updatedVacationDays =
          vacationDays.where((date) => !isSameDay(date, day)).toList();

      // Update provider profile
      await _userAPI.updateProviderVacationDays(userId, updatedVacationDays);

      // Update local state
      vacationDays.value = updatedVacationDays;

      showSuccess('Vacation day removed');
    });
  }

  /// Remove multiple vacation days
  Future<void> removeSelectedVacationDays() {
    if (selectedDays.isEmpty) {
      showInfo('No days selected');
      return Future.value();
    }

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Remove selected days
      final updatedVacationDays =
          vacationDays
              .where(
                (date) =>
                    !selectedDays.any((selected) => isSameDay(selected, date)),
              )
              .toList();

      // Update provider profile
      await _userAPI.updateProviderVacationDays(userId, updatedVacationDays);

      // Update local state
      vacationDays.value = updatedVacationDays;
      selectedDays.clear();

      showSuccess('Selected vacation days removed');
    });
  }

  /// Toggle day selection for bulk delete
  void toggleDaySelection(DateTime day) {
    final isSelected = selectedDays.any((date) => isSameDay(date, day));

    if (isSelected) {
      selectedDays.removeWhere((date) => isSameDay(date, day));
    } else {
      selectedDays.add(day);
    }
  }

  /// Clear all selections
  void clearSelections() {
    selectedDays.clear();
  }

  /// Check if a day is selected
  bool isDaySelected(DateTime day) {
    return selectedDays.any((date) => isSameDay(date, day));
  }

  /// Check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Format date
  String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Get day name from day number (1-7)
  String getDayName(String dayNumber) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final index = int.tryParse(dayNumber);

    if (index != null && index >= 1 && index <= 7) {
      return days[index - 1];
    }

    return 'Unknown';
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

  /// Validate time format
  bool isValidTimeFormat(String time) {
    final pattern = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return pattern.hasMatch(time);
  }

  /// Validate start and end times
  bool validateTimeRange(String day) {
    final start = startTimeControllers[day]?.text ?? '';
    final end = endTimeControllers[day]?.text ?? '';

    if (!isValidTimeFormat(start) || !isValidTimeFormat(end)) {
      return false;
    }

    final startHour = int.parse(start.split(':')[0]);
    final startMinute = int.parse(start.split(':')[1]);
    final endHour = int.parse(end.split(':')[0]);
    final endMinute = int.parse(end.split(':')[1]);

    if (startHour > endHour) {
      return false;
    }

    if (startHour == endHour && startMinute >= endMinute) {
      return false;
    }

    return true;
  }
}
