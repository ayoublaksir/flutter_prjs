import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place.dart';
import '../models/date_category.dart';
import '../services/places_service.dart';
import '../widgets/modern_app_bar.dart';
import 'package:geolocator/geolocator.dart';

class FilteredPlacesScreen extends StatefulWidget {
  @override
  _FilteredPlacesScreenState createState() => _FilteredPlacesScreenState();
}

class _FilteredPlacesScreenState extends State<FilteredPlacesScreen> {
  final PlacesService _placesService = PlacesService();
  List<Place> _places = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedCity = '';
  List<DateCategory> _selectedCategories = [];
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _fetchPlaces(LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() {
        _error =
            'Could not get current location. Please enter your city manually.';
      });
    }
  }

  Future<void> _fetchPlaces(LatLng location) async {
    if (_selectedCity.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final places = await _placesService.getPlacesByFilters(
        city: _selectedCity,
        categories:
            _selectedCategories.isEmpty
                ? [DateCategory.restaurant]
                : _selectedCategories,
        location: location,
      );

      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading places: $e';
        _isLoading = false;
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Filter Places'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          hintText: 'Enter your city',
                        ),
                        onChanged: (value) {
                          _selectedCity = value;
                        },
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Wrap(
                        spacing: 8,
                        children:
                            DateCategory.values.map((category) {
                              final isSelected = _selectedCategories.contains(
                                category,
                              );
                              return FilterChip(
                                label: Text(category.displayName),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategories.add(category);
                                    } else {
                                      _selectedCategories.remove(category);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _initializeLocation();
                    },
                    child: Text('Apply'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Date Places',
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(_error, textAlign: TextAlign.center),
        ),
      );
    }

    if (_places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No places found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Try changing your filters or location',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showFilterDialog,
              child: Text('Change Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text(
              place.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text(place.address),
                SizedBox(height: 4),
                Text(
                  'Rating: ${place.rating.toStringAsFixed(1)} ⭐',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('Price Range: ${_getPriceRange(place.priceRange)}'),
                if (place.categories.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children:
                        place.categories.map((category) {
                          return Chip(
                            label: Text(
                              category,
                              style: TextStyle(fontSize: 12),
                            ),
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
            onTap: () {
              Navigator.pushNamed(context, '/place-details', arguments: place);
            },
          ),
        );
      },
    );
  }

  String _getPriceRange(double price) {
    if (price <= 25) return '\$';
    if (price <= 50) return '\$\$';
    if (price <= 75) return '\$\$\$';
    return '\$\$\$\$';
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}
