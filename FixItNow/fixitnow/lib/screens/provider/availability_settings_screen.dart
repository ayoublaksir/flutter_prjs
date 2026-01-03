import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/user_models.dart';

class AvailabilitySettingsScreen extends StatefulWidget {
  const AvailabilitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<AvailabilitySettingsScreen> createState() =>
      _AvailabilitySettingsScreenState();
}

class _AvailabilitySettingsScreenState
    extends State<AvailabilitySettingsScreen> {
  final UserAPI _userAPI = UserAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  Map<String, WorkingHours> _workingHours = {};
  List<DateTime> _vacationDays = [];
  int _bufferTime = 15; // minutes
  bool _isAvailable = true;

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final provider = await _userAPI.getProviderProfile(user.uid);
        if (provider != null) {
          setState(() {
            _workingHours = provider.workingHours;
            _vacationDays = provider.vacationDays;
            _bufferTime = provider.bufferTime;
            _isAvailable = provider.isAvailable;

            // Initialize working hours if empty
            if (_workingHours.isEmpty) {
              for (final day in _weekDays) {
                _workingHours[day] = WorkingHours(
                  isWorking: day != 'Sunday',
                  start: '09:00',
                  end: '17:00',
                  breaks: [],
                );
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error loading availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading availability settings')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final provider = await _userAPI.getProviderProfile(user.uid);
        if (provider != null) {
          await _userAPI.updateProviderProfile(
            provider.copyWith(
              workingHours: _workingHours,
              vacationDays: _vacationDays,
              bufferTime: _bufferTime,
              isAvailable: _isAvailable,
            ),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Availability settings saved')),
            );
          }
        }
      }
    } catch (e) {
      print('Error saving availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving availability settings')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay initialTime) {
    return showTimePicker(context: context, initialTime: initialTime);
  }

  String _timeOfDayToString(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Settings'),
        actions: [
          Switch(
            value: _isAvailable,
            onChanged: (value) {
              setState(() => _isAvailable = value);
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Availability status
                    Card(
                      child: ListTile(
                        leading: Icon(
                          _isAvailable ? Icons.check_circle : Icons.block,
                          color: _isAvailable ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          _isAvailable
                              ? 'Available for Bookings'
                              : 'Not Available',
                        ),
                        subtitle: const Text(
                          'Toggle to control booking availability',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Working hours
                    Text(
                      'Working Hours',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ..._weekDays.map((day) => _buildDaySchedule(day)),
                    const SizedBox(height: 24),

                    // Buffer time
                    Text(
                      'Buffer Time Between Appointments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _bufferTime,
                      items:
                          [15, 30, 45, 60].map((minutes) {
                            return DropdownMenuItem(
                              value: minutes,
                              child: Text('$minutes minutes'),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _bufferTime = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Vacation days
                    Text(
                      'Vacation Days',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildVacationDays(),
                  ],
                ),
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _saveAvailability,
          child: const Text('Save Availability'),
        ),
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final hours = _workingHours[day]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(day)),
                Switch(
                  value: hours.isWorking,
                  onChanged: (value) {
                    setState(() {
                      _workingHours[day] = hours.copyWith(isWorking: value);
                    });
                  },
                ),
              ],
            ),
            if (hours.isWorking) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        'Start: ${_stringToTimeOfDay(hours.start).format(context)}',
                      ),
                      onPressed: () async {
                        final time = await _selectTime(
                          context,
                          _stringToTimeOfDay(hours.start),
                        );
                        if (time != null) {
                          setState(() {
                            _workingHours[day] = hours.copyWith(
                              start: _timeOfDayToString(time),
                            );
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        'End: ${_stringToTimeOfDay(hours.end).format(context)}',
                      ),
                      onPressed: () async {
                        final time = await _selectTime(
                          context,
                          _stringToTimeOfDay(hours.end),
                        );
                        if (time != null) {
                          setState(() {
                            _workingHours[day] = hours.copyWith(
                              end: _timeOfDayToString(time),
                            );
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              // Break times
              if (hours.breaks.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Breaks:'),
                ...hours.breaks.map((break_) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${_stringToTimeOfDay(break_.start).format(context)} - ${_stringToTimeOfDay(break_.end).format(context)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          final newBreaks = List<Break>.from(hours.breaks)
                            ..remove(break_);
                          _workingHours[day] = hours.copyWith(
                            breaks: newBreaks,
                          );
                        });
                      },
                    ),
                  );
                }),
              ],
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Break'),
                onPressed: () async {
                  final start = await _selectTime(
                    context,
                    _stringToTimeOfDay(hours.start),
                  );
                  if (start != null) {
                    final end = await _selectTime(
                      context,
                      TimeOfDay(hour: start.hour + 1, minute: start.minute),
                    );
                    if (end != null) {
                      setState(() {
                        final newBreaks = List<Break>.from(hours.breaks)..add(
                          Break(
                            start: _timeOfDayToString(start),
                            end: _timeOfDayToString(end),
                          ),
                        );
                        _workingHours[day] = hours.copyWith(breaks: newBreaks);
                      });
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVacationDays() {
    return Column(
      children: [
        if (_vacationDays.isNotEmpty) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vacationDays.length,
            itemBuilder: (context, index) {
              final date = _vacationDays[index];
              return ListTile(
                title: Text(date.toString().split(' ')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _vacationDays.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Vacation Day'),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _vacationDays.add(date);
                _vacationDays.sort();
              });
            }
          },
        ),
      ],
    );
  }
}
