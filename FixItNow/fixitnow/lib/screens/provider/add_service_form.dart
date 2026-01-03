// screens/provider/add_service_form.dart
// Form for adding or editing provider services

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/service_models.dart';
import '../../controllers/provider/service_form_controller.dart';
import '../../widgets/common/index.dart';

class AddServiceFormScreen extends StatefulWidget {
  final ProviderService? service; // Pass existing service for editing

  const AddServiceFormScreen({Key? key, this.service}) : super(key: key);

  @override
  State<AddServiceFormScreen> createState() => _AddServiceFormScreenState();
}

class _AddServiceFormScreenState extends State<AddServiceFormScreen> {
  late ServiceFormController controller;
  
  // Local state for UI that doesn't need to be in the controller
  final List<File> _selectedImages = [];
  bool _isActive = true;
  String _pricingType = 'fixed'; // 'fixed', 'hourly', 'variable'
  String? _selectedSubcategory;
  List<String> _subcategories = [];
  List<ServiceCategory> _categories = [];
  bool _isLoading = true;

  // Time slots
  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  Map<String, bool> _availableDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };

  // Time range
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  final TextEditingController _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controller with the service for editing if provided
    controller = Get.put(ServiceFormController(), tag: 'service_form');
    _loadCategories();

    // If editing, populate form with existing data
    if (widget.service != null) {
      _isActive = widget.service!.isActive;
      // Other fields would be populated here
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    Get.delete<ServiceFormController>(tag: 'service_form');
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    // For demo, use real categories
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _categories = [
        ServiceCategory(
          id: 'category-0',
          name: 'Plumbing',
          description: 'Water systems, pipes, fixtures, and drainage services',
          icon: Icons.plumbing,
          imageUrl: 'assets/images/categories/plumbing.jpg',
        ),
        ServiceCategory(
          id: 'category-1',
          name: 'Electrical',
          description: 'Wiring, lighting, electrical panels and installations',
          icon: Icons.electrical_services,
          imageUrl: 'assets/images/categories/electrical.jpg',
        ),
        ServiceCategory(
          id: 'category-2',
          name: 'Cleaning',
          description:
              'Home cleaning, deep cleaning, and specialized cleaning services',
          icon: Icons.cleaning_services,
          imageUrl: 'assets/images/categories/cleaning.jpg',
        ),
        ServiceCategory(
          id: 'category-3',
          name: 'Carpentry',
          description:
              'Woodworking, furniture repair, and custom installations',
          icon: Icons.handyman,
          imageUrl: 'assets/images/categories/carpentry.jpg',
        ),
        ServiceCategory(
          id: 'category-4',
          name: 'Painting',
          description: 'Interior and exterior painting services',
          icon: Icons.format_paint,
          imageUrl: 'assets/images/categories/painting.jpg',
        ),
        ServiceCategory(
          id: 'category-5',
          name: 'HVAC',
          description: 'Heating, ventilation, and air conditioning services',
          icon: Icons.hvac,
          imageUrl: 'assets/images/categories/hvac.jpg',
        ),
        ServiceCategory(
          id: 'category-6',
          name: 'Landscaping',
          description: 'Garden design, lawn care, and outdoor maintenance',
          icon: Icons.grass,
          imageUrl: 'assets/images/categories/landscaping.jpg',
        ),
        ServiceCategory(
          id: 'category-7',
          name: 'Appliance Repair',
          description: 'Repair and maintenance of household appliances',
          icon: Icons.kitchen,
          imageUrl: 'assets/images/categories/appliance.jpg',
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _updateSubcategories(String categoryId) {
    setState(() {
      _selectedSubcategory = null;

      // Find the selected category
      final selectedCategory = _categories.firstWhere(
        (category) => category.id == categoryId,
        orElse: () => ServiceCategory(
          id: '',
          name: '',
          description: '',
          icon: Icons.category,
          imageUrl: '',
        ),
      );

      // Update subcategories
      _subcategories = selectedCategory.subcategories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'Add Service' : 'Edit Service'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: controller.formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Section
                    SectionHeader(title: 'Basic Information'),
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),

                    // Pricing Section
                    SectionHeader(title: 'Pricing'),
                    _buildPricingSection(),
                    const SizedBox(height: 24),

                    // Availability Section
                    SectionHeader(title: 'Availability'),
                    _buildAvailabilitySection(),
                    const SizedBox(height: 24),

                    // Images Section
                    SectionHeader(title: 'Service Images'),
                    _buildImagesSection(),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value 
                              ? null 
                              : controller.saveService,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.service == null
                                      ? 'Add Service'
                                      : 'Update Service',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Service Name
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: 'Service Name',
                hintText: 'Enter service name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a service name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Service Category
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedCategoryId.value.isEmpty 
                    ? null 
                    : controller.selectedCategoryId.value,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Select a category',
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.selectCategory(value);
                    _updateSubcategories(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Service Description
            TextFormField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter service description',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Service Duration
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                hintText: 'Enter service duration',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Service Status
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Service is available for booking'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),

            if (_subcategories.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSubcategory,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory',
                      hintText: 'Select a subcategory',
                      border: OutlineInputBorder(),
                    ),
                    items: _subcategories.map((subcategory) {
                      return DropdownMenuItem(
                        value: subcategory,
                        child: Text(subcategory),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubcategory = value;
                      });
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pricing Type
            const Text(
              'Pricing Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Pricing Type Radio Buttons
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Fixed'),
                    value: 'fixed',
                    groupValue: _pricingType,
                    onChanged: (value) {
                      setState(() {
                        _pricingType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Hourly'),
                    value: 'hourly',
                    groupValue: _pricingType,
                    onChanged: (value) {
                      setState(() {
                        _pricingType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price Input
            TextFormField(
              controller: controller.priceController,
              decoration: InputDecoration(
                labelText:
                    _pricingType == 'fixed' ? 'Price (\$)' : 'Hourly Rate (\$)',
                hintText: 'Enter price',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available Days
            const Text(
              'Available Days',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Weekday Checkboxes
            Wrap(
              spacing: 8,
              children: _weekdays.map((day) {
                return FilterChip(
                  label: Text(day.substring(0, 3)),
                  selected: _availableDays[day]!,
                  onSelected: (selected) {
                    setState(() {
                      _availableDays[day] = selected;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Time Range
            const Text(
              'Time Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Start and End Time Pickers
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(_formatTimeOfDay(_startTime)),
                    onTap: () => _selectTime(context, true),
                    trailing: const Icon(Icons.access_time),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(_formatTimeOfDay(_endTime)),
                    onTap: () => _selectTime(context, false),
                    trailing: const Icon(Icons.access_time),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload Button
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Selected Images Preview
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No images selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}