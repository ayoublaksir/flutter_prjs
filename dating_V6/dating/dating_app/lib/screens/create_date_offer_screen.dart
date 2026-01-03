import 'package:flutter/material.dart';
import '../widgets/modern_app_bar.dart';
import '../models/date_offer.dart';
import '../services/date_offer_service.dart';
import '../services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/premium_popup.dart';
import '../services/place_search_service.dart';
import '../models/place.dart';
import 'place_search_screen.dart';
import '../widgets/premium_badge.dart';

class CreateDateOfferScreen extends StatefulWidget {
  @override
  _CreateDateOfferScreenState createState() => _CreateDateOfferScreenState();
}

class _CreateDateOfferScreenState extends State<CreateDateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _estimatedCostController =
      TextEditingController();
  DateTime? _selectedDateTime;
  Place? _selectedPlace;
  GeoPoint? _selectedLocation;
  List<String> _selectedInterests = [];
  final DateOfferService _dateOfferService = DateOfferService();
  final AuthService _authService = AuthService();
  final PlaceSearchService _placeSearchService = PlaceSearchService();
  bool _isLoading = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String _selectedPlaceName = '';

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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _placeController.dispose();
    _estimatedCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Create Date Offer',
        showNotifications: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PremiumBadge(
              mini: true,
              onTap: () => Navigator.pushNamed(context, '/premium'),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Basic Details Card
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Basic Details',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: 'Title',
                                  border: OutlineInputBorder(),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Please enter a title'
                                            : null,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Description (Optional)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Location Card
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 16),

                              // Place search field
                              _buildPlaceField(),

                              // Show selected place details if available
                              if (_selectedPlace != null) ...[
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedPlace!.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(_selectedPlace!.address),
                                      if (_selectedPlace!.rating > 0) ...[
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '${_selectedPlace!.rating}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              SizedBox(height: 16),

                              // Map preview (optional)
                              if (_selectedLatitude != null &&
                                  _selectedLongitude != null)
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(
                                          _selectedLatitude!,
                                          _selectedLongitude!,
                                        ),
                                        zoom: 15,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: MarkerId('selected_place'),
                                          position: LatLng(
                                            _selectedLatitude!,
                                            _selectedLongitude!,
                                          ),
                                        ),
                                      },
                                      zoomControlsEnabled: false,
                                      mapToolbarEnabled: false,
                                      myLocationButtonEnabled: false,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Date and Time Card
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date & Time',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 16),
                              InkWell(
                                onTap: _selectDateTime,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Select Date & Time',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _selectedDateTime != null
                                        ? _formatDateTime(_selectedDateTime!)
                                        : 'Not selected',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Interests Card
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Interests',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _availableInterests.map((interest) {
                                      final isSelected = _selectedInterests
                                          .contains(interest);
                                      return FilterChip(
                                        label: Text(interest),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedInterests.add(interest);
                                            } else {
                                              _selectedInterests.remove(
                                                interest,
                                              );
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () async {
                                  await _createDateOffer();
                                },
                        child:
                            _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text('Create Date Offer'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildPlaceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field with autocomplete
        TextFormField(
          controller: _placeController,
          decoration: InputDecoration(
            labelText: 'Place',
            hintText: 'Where will this date take place?',
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: _searchPlace,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a place';
            }
            return null;
          },
          onTap: () {
            // Show search screen when field is tapped
            _searchPlace();
          },
        ),
        SizedBox(height: 8),
        Row(
          children: [
            // Keep existing map selection button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectLocationOnMap,
                icon: Icon(Icons.map),
                label: Text('Select on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(width: 8),
            // Add search places button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _searchPlace,
                icon: Icon(Icons.search),
                label: Text('Search Places'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        if (_selectedLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Selected: $_selectedPlaceName',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createDateOffer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a date and time')));
      return;
    }

    if (_selectedPlace == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a place')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUserProfile();
      final canCreate = await _dateOfferService.canCreateOffer(user.uid);

      if (!canCreate) {
        showDialog(
          context: context,
          builder:
              (context) =>
                  PremiumPopup(feature: 'Create unlimited date offers'),
        );
        setState(() => _isLoading = false);
        return;
      }

      await _dateOfferService.createDateOffer(
        DateOffer(
          id: '',
          creatorId: user.uid,
          creatorName: user.name,
          creatorImageUrl: user.profileImageUrl,
          creatorAge: user.age ?? 0,
          title: _titleController.text,
          description: _descriptionController.text,
          place: _selectedPlace!.name,
          dateTime: _selectedDateTime!,
          estimatedCost: double.tryParse(_estimatedCostController.text),
          interests: _selectedInterests,
          createdAt: DateTime.now(),
          location: _selectedLocation,
          creatorGender: user.gender,
          city: user.city ?? 'Unknown',
        ),
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Date offer created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchPlace() async {
    final Place? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlaceSearchScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedPlace = result;
        _placeController.text = result.name;
        _selectedLatitude = result.latitude;
        _selectedLongitude = result.longitude;

        // If the place has categories, add them to interests
        if (result.categories.isNotEmpty) {
          for (final category in result.categories) {
            if (!_selectedInterests.contains(category)) {
              _selectedInterests.add(category);
            }
          }
        }
      });
    }
  }

  Future<void> _selectLocationOnMap() async {
    final LatLng? result =
        await Navigator.pushNamed(
              context,
              '/select-location',
              arguments: _selectedLocation,
            )
            as LatLng?;

    if (result != null) {
      setState(() {
        _selectedLocation = GeoPoint(result.latitude, result.longitude);
        _selectedLatitude = result.latitude;
        _selectedLongitude = result.longitude;

        // Update place name based on coordinates
        _updatePlaceNameFromCoordinates(result.latitude, result.longitude);
      });
    }
  }

  Future<void> _updatePlaceNameFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedPlaceName = '${place.name}, ${place.locality}';
          _placeController.text = _selectedPlaceName;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _onPlaceSelected(Place place) {
    setState(() {
      _selectedPlace = place;
      _selectedLocation = GeoPoint(place.latitude, place.longitude);
      _placeController.text = place.name;
    });
  }
}
