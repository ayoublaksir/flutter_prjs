// widgets/forms.dart
// Reusable form components

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_services.dart';
import '../models/service_models.dart';

// Search Bar widget
class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String) onSearch;
  final bool autofocus;

  const CustomSearchBar({
    Key? key,
    required this.hintText,
    required this.onSearch,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onSubmitted: widget.onSearch,
        onChanged: (value) {
          setState(() {});
        },
        textInputAction: TextInputAction.search,
      ),
    );
  }
}

// Filter Form widget
class FilterForm extends StatefulWidget {
  final List<String> initialFilters;
  final Function(List<String>) onApply;

  const FilterForm({
    Key? key,
    required this.initialFilters,
    required this.onApply,
  }) : super(key: key);

  @override
  State<FilterForm> createState() => _FilterFormState();
}

class _FilterFormState extends State<FilterForm> {
  late List<String> _selectedFilters;
  final ServiceAPI _serviceAPI = ServiceAPI();
  List<ServiceCategory> _categories = [];
  bool _isLoading = true;
  double _minPrice = 0;
  double _maxPrice = 500;
  RangeValues _priceRange = const RangeValues(0, 500);
  bool _onlyAvailableNow = false;

  @override
  void initState() {
    super.initState();
    _selectedFilters = List.from(widget.initialFilters);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _serviceAPI.getServiceCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedFilters = [];
      _priceRange = const RangeValues(0, 500);
      _onlyAvailableNow = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset All'),
              ),
            ],
          ),
          const Divider(),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categories section
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _categories.map((category) {
                              return FilterChip(
                                label: Text(category!.name),
                                selected: _selectedFilters.contains(
                                  category!.id,
                                ),
                                onSelected: (selected) {
                                  _toggleFilter(category!.id);
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Price range section
                      Text(
                        'Price Range',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      RangeSlider(
                        values: _priceRange,
                        min: _minPrice,
                        max: _maxPrice,
                        divisions: 50,
                        labels: RangeLabels(
                          '\${_priceRange.start.round()}',
                          '\${_priceRange.end.round()}',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('\${_priceRange.start.round()}'),
                          Text('\${_priceRange.end.round()}'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Additional filters
                      CheckboxListTile(
                        title: const Text('Available Now'),
                        value: _onlyAvailableNow,
                        onChanged: (value) {
                          setState(() {
                            _onlyAvailableNow = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Common tags section
                      Text(
                        'Common Tags',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                              'Emergency',
                              'Weekends',
                              'Flexible Hours',
                              'Highly Rated',
                              'Certified',
                              'Eco-Friendly',
                            ].map((tag) {
                              return FilterChip(
                                label: Text(tag),
                                selected: _selectedFilters.contains(tag),
                                onSelected: (selected) {
                                  _toggleFilter(tag);
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedFilters);
                Navigator.pop(context);
              },
              child: Text('Apply (${_selectedFilters.length} Filters)'),
            ),
          ),
        ],
      ),
    );
  }
}

// Date Time Picker form
class DateTimePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;
  final Function(TimeOfDay) onTimeSelected;
  final DateTime? minDate;
  final DateTime? maxDate;

  const DateTimePicker({
    Key? key,
    required this.initialDate,
    required this.onDateSelected,
    required this.onTimeSelected,
    this.minDate,
    this.maxDate,
  }) : super(key: key);

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.minDate ?? DateTime.now(),
      lastDate: widget.maxDate ?? DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateSelected(picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      widget.onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Rating Input widget
class RatingInput extends StatelessWidget {
  final double rating;
  final Function(double) onRatingChanged;
  final int starCount;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;

  const RatingInput({
    Key? key,
    required this.rating,
    required this.onRatingChanged,
    this.starCount = 5,
    this.starSize = 40,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(starCount, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: index < rating ? activeColor : inactiveColor,
            size: starSize,
          ),
          onPressed: () {
            onRatingChanged(index + 1);
          },
          splashRadius: starSize * 0.7,
        );
      }),
    );
  }
}

// Service Details Form
class ServiceDetailsForm extends StatefulWidget {
  final Function(String, List<String>, String) onSubmit;
  final Map<String, dynamic>? additionalOptions;
  final bool isLoading;

  const ServiceDetailsForm({
    Key? key,
    required this.onSubmit,
    this.additionalOptions,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<ServiceDetailsForm> createState() => _ServiceDetailsFormState();
}

class _ServiceDetailsFormState extends State<ServiceDetailsForm> {
  final TextEditingController _detailsController = TextEditingController();
  List<String> _selectedOptions = [];
  String _specialInstructions = '';

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Details',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _detailsController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the issue or service you need...',
            border: OutlineInputBorder(),
          ),
        ),
        if (widget.additionalOptions != null &&
            widget.additionalOptions!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Additional Options',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...widget.additionalOptions!.entries.map((entry) {
            final option = entry.key;
            final price = entry.value;
            return CheckboxListTile(
              title: Text(option),
              subtitle: Text('\${price.toStringAsFixed(2)}'),
              value: _selectedOptions.contains(option),
              onChanged: (checked) {
                setState(() {
                  if (checked ?? false) {
                    _selectedOptions.add(option);
                  } else {
                    _selectedOptions.remove(option);
                  }
                });
              },
            );
          }),
        ],
        const SizedBox(height: 24),
        Text(
          'Special Instructions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Any special requests or instructions...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _specialInstructions = value;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                widget.isLoading
                    ? null
                    : () {
                      widget.onSubmit(
                        _detailsController.text,
                        _selectedOptions,
                        _specialInstructions,
                      );
                    },
            child:
                widget.isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text('Continue'),
          ),
        ),
      ],
    );
  }
}
