import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place.dart';
import '../models/date_offer.dart';
import '../services/date_offer_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  PlaceDetailsScreen({required this.place});

  @override
  _PlaceDetailsScreenState createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final DateOfferService _dateOfferService = DateOfferService();
  final AuthService _authService = AuthService();
  final List<String> _selectedInterests = [];
  DateTime? _selectedDateTime;

  // Add available interests list
  final List<String> _availableInterests = [
    'Dining',
    'Coffee',
    'Movies',
    'Outdoor',
    'Sports',
    'Music',
    'Art',
    'Adventure',
    'Cultural',
    'Gaming',
    'Shopping',
    'Fitness',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select categories from place if available
    if (widget.place.categories.isNotEmpty) {
      setState(() {
        _selectedInterests.addAll(widget.place.categories);
      });
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.place.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // View on Map Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/map',
                    arguments: {
                      'latitude': widget.place.latitude,
                      'longitude': widget.place.longitude,
                      'name': widget.place.name,
                    },
                  );
                },
                icon: Icon(Icons.map),
                label: Text('View on Map'),
              ),
              SizedBox(height: 16),

              // Date and Time Selection
              ListTile(
                title: Text('Select Date and Time'),
                subtitle: Text(
                  _selectedDateTime != null
                      ? '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} at ${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}'
                      : 'Not selected',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),

              SizedBox(height: 16),
              Text(
                'Select Categories',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              _buildInterestSelector(),

              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_selectedDateTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a date and time')),
                    );
                    return;
                  }

                  try {
                    final user = await _authService.getCurrentUserProfile();
                    await _dateOfferService.createDateOffer(
                      DateOffer(
                        id: '',
                        creatorId: user.uid,
                        creatorName: user.name,
                        creatorImageUrl: user.imageUrl,
                        creatorAge: user.age ?? 0,
                        title: widget.place.name,
                        description: widget.place.description,
                        place: widget.place.name,
                        dateTime: _selectedDateTime!,
                        estimatedCost: widget.place.priceRange,
                        interests: _selectedInterests,
                        createdAt: DateTime.now(),
                        creatorGender: user.gender,
                        location: GeoPoint(
                          widget.place.latitude,
                          widget.place.longitude,
                        ),
                      ),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Date offer created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create date offer'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Create Date Offer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          widget.place.categories.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedInterests.add(interest);
                  } else {
                    _selectedInterests.remove(interest);
                  }
                });
              },
            );
          }).toList(),
    );
  }
}
