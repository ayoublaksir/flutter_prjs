import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/place_search_service.dart';
import 'package:debounce_throttle/debounce_throttle.dart';

class PlaceSearchScreen extends StatefulWidget {
  @override
  _PlaceSearchScreenState createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final PlaceSearchService _placeSearchService = PlaceSearchService();
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer<String>(
    Duration(milliseconds: 500),
    initialValue: '',
  );

  List<Place> _searchResults = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _debouncer.values.listen((query) {
      if (query.isNotEmpty) {
        _searchPlaces(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await _placeSearchService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error searching places: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Places'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                _debouncer.value = value;
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_error.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(_error, style: TextStyle(color: Colors.red)),
            ),

          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                    ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Search for a place'
                            : 'No places found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          title: Text(place.name),
                          subtitle: Text(place.address),
                          trailing: Text(
                            place.rating > 0 ? '${place.rating}★' : 'No rating',
                            style: TextStyle(
                              color:
                                  place.rating > 0 ? Colors.amber : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context, place);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
