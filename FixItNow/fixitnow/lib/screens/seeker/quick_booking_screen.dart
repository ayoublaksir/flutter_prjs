import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/service_models.dart';
import '../../models/user_models.dart';
import '../../routes.dart';

class QuickBookingScreen extends StatefulWidget {
  const QuickBookingScreen({Key? key}) : super(key: key);

  @override
  State<QuickBookingScreen> createState() => _QuickBookingScreenState();
}

class _QuickBookingScreenState extends State<QuickBookingScreen> {
  final ServiceAPI _serviceAPI = ServiceAPI();
  final UserAPI _userAPI = UserAPI();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  List<ServiceCategory> _categories = [];
  String? _selectedCategory;
  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _location;
  List<ServiceProvider> _availableProviders = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _serviceAPI.getServiceCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading categories')));
    }
  }

  Future<void> _findAvailableProviders() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final providers = await _userAPI.findAvailableProviders(
        categoryId: _selectedCategory!,
        serviceType: _selectedService!,
        date: DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        ),
        location: _location!,
      );

      setState(() => _availableProviders = providers);

      if (providers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No providers available for selected criteria'),
          ),
        );
      }
    } catch (e) {
      print('Error finding providers: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error finding providers')));
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
      _selectTime();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Booking')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Category
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Service Category',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _categories.map((category) {
                              return DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                            _selectedService = null;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Service Type
                      if (_selectedCategory != null) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedService,
                          decoration: const InputDecoration(
                            labelText: 'Service Type',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _categories
                                  .firstWhere((c) => c.id == _selectedCategory)
                                  .services
                                  .map((service) {
                                    return DropdownMenuItem(
                                      value: service.id,
                                      child: Text(service.name),
                                    );
                                  })
                                  .toList(),
                          onChanged: (value) {
                            setState(() => _selectedService = value);
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a service';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Date and Time
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
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
                      const SizedBox(height: 16),

                      // Location
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Service Location',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _location = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter service location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Find Providers Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _findAvailableProviders,
                          child: const Text('Find Available Providers'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Available Providers List
                      if (_availableProviders.isNotEmpty) ...[
                        Text(
                          'Available Providers',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _availableProviders.length,
                          itemBuilder: (context, index) {
                            final provider = _availableProviders[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      provider.profileImage != null
                                          ? NetworkImage(provider.profileImage!)
                                          : null,
                                  child:
                                      provider.profileImage == null
                                          ? const Icon(Icons.person)
                                          : null,
                                ),
                                title: Text(provider.businessName),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    Text(
                                      ' ${provider.rating.toStringAsFixed(1)} (${provider.reviewCount})',
                                    ),
                                  ],
                                ),
                                trailing: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.bookingForm,
                                      arguments: {
                                        'providerId': provider.id,
                                        'serviceId': _selectedService,
                                        'date': _selectedDate,
                                        'time': _selectedTime,
                                        'location': _location,
                                      },
                                    );
                                  },
                                  child: const Text('Book Now'),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }
}
