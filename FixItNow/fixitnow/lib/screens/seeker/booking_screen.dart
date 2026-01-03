import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/service_models.dart';
import '../../models/booking_models.dart';
import '../../routes.dart';
import 'package:intl/intl.dart';

class SeekerBookingScreen extends StatefulWidget {
  final String serviceId;

  const SeekerBookingScreen({Key? key, required this.serviceId})
    : super(key: key);

  @override
  State<SeekerBookingScreen> createState() => _SeekerBookingScreenState();
}

class _SeekerBookingScreenState extends State<SeekerBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceAPI _serviceAPI = ServiceAPI();
  final BookingAPI _bookingAPI = BookingAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  ProviderService? _service;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedLocation;
  final List<String> _selectedAddons = [];
  final TextEditingController _notesController = TextEditingController();
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceDetails() async {
    setState(() => _isLoading = true);

    try {
      final service = await _serviceAPI.getServiceDetails(widget.serviceId);
      setState(() {
        _service = service;
        _totalPrice = service?.price ?? 0;
      });
    } catch (e) {
      print('Error loading service details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading service details')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
      _selectTime(); // Prompt for time after date selection
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _updateTotalPrice() {
    if (_service == null) return;

    double total = _service!.price;
    for (final addon in _selectedAddons) {
      final option = _service!.additionalOptions.firstWhere(
        (opt) => opt.name == addon,
      );
      total += option.price;
    }
    setState(() => _totalPrice = total);
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null && _service != null) {
        final booking = Booking(
          id: '', // Will be set by Firebase
          serviceId: widget.serviceId,
          seekerId: user.uid,
          providerId: _service!.providerId,
          bookingDate: _selectedDate!,
          bookingTime: '${_selectedTime!.hour}:${_selectedTime!.minute}',
          status: 'pending',
          address: _selectedLocation ?? '',
          description: _notesController.text,
          price: _totalPrice,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
          paymentMethod: 'credit_card',
          createdAt: DateTime.now(),
          location: _selectedLocation ?? '',
        );

        final bookingId = await _bookingAPI.createBooking(booking);

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.bookingConfirmation,
            arguments: {'bookingId': bookingId},
          );
        }
      }
    } catch (e) {
      print('Error creating booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error creating booking')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_service == null) {
      return const Scaffold(body: Center(child: Text('Service not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service summary
              Card(
                child: ListTile(
                  title: Text(_service!.name),
                  subtitle: Text(
                    'Base Price: \$${_service!.price.toStringAsFixed(2)}',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Date and Time
              Text(
                'Select Date & Time',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      ),
                      onPressed: _selectDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime == null
                            ? 'Select Time'
                            : _selectedTime!.format(context),
                      ),
                      onPressed: _selectTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Location
              Text(
                'Service Location',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Enter service location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter service location';
                  }
                  return null;
                },
                onChanged: (value) => setState(() => _selectedLocation = value),
              ),
              const SizedBox(height: 24),

              // Additional Options
              if (_service!.additionalOptions.isNotEmpty) ...[
                Text(
                  'Additional Options',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _service!.additionalOptions.length,
                  itemBuilder: (context, index) {
                    final option = _service!.additionalOptions[index];
                    return CheckboxListTile(
                      title: Text(option.name),
                      subtitle: Text('+ \$${option.price.toStringAsFixed(2)}'),
                      value: _selectedAddons.contains(option.name),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedAddons.add(option.name);
                          } else {
                            _selectedAddons.remove(option.name);
                          }
                          _updateTotalPrice();
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Notes
              Text(
                'Additional Notes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any special instructions...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Total Price
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${_totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
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
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitBooking,
            child:
                _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Confirm Booking'),
          ),
        ),
      ),
    );
  }
}
