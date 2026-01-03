import 'package:flutter/material.dart';
import '../models/date_models.dart' as date_models;
import '../models/date_mood.dart';
import '../models/date_category.dart';
import '../models/relationship_stage.dart';
import '../services/recommendation_service.dart';
import '../services/places_service.dart';
import '../widgets/modern_app_bar.dart';
import 'recommendation_details_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/user_preferences.dart';

class DateRecommendationScreen extends StatefulWidget {
  final UserPreferences? userPreferences;

  const DateRecommendationScreen({Key? key, this.userPreferences})
    : super(key: key);

  @override
  _DateRecommendationScreenState createState() =>
      _DateRecommendationScreenState();
}

class _DateRecommendationScreenState extends State<DateRecommendationScreen> {
  final RecommendationService _recommendationService = RecommendationService(
    PlacesService(),
  );
  bool _isLoading = true;
  List<date_models.DateIdea>? _dateIdeas;
  String? _error;

  // User preferences
  late RelationshipStage _selectedRelationshipStage;
  late List<DateMood> _selectedMoods;
  late List<DateCategory> _selectedCategories;
  late bool _dietaryRestrictions;
  late int _activityLevel;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    _getRecommendations();
  }

  void _initializePreferences() {
    // Initialize with provided preferences or defaults
    _selectedRelationshipStage =
        widget.userPreferences?.relationshipStage ??
        RelationshipStage.firstDate;

    // Fix nullable expressions used as conditions
    _selectedMoods =
        widget.userPreferences?.preferredMoods == null ||
                widget.userPreferences!.preferredMoods.isEmpty
            ? [DateMood.romantic]
            : widget.userPreferences!.preferredMoods;

    _selectedCategories =
        widget.userPreferences?.preferredCategories == null ||
                widget.userPreferences!.preferredCategories.isEmpty
            ? [DateCategory.restaurant]
            : widget.userPreferences!.preferredCategories;

    _dietaryRestrictions = widget.userPreferences?.dietaryRestrictions ?? false;
    _activityLevel = widget.userPreferences?.activityLevel ?? 5;
  }

  Future<void> _getRecommendations() async {
    setState(() => _isLoading = true);

    try {
      final recommendations = await _recommendationService.getRecommendations(
        relationshipStage: _selectedRelationshipStage,
        moods: _selectedMoods,
        categories: _selectedCategories,
        dietaryRestrictions: _dietaryRestrictions,
        activityLevel: _activityLevel,
        userLocation: LatLng(
          37.7749,
          -122.4194,
        ), // Default location - San Francisco
      );

      setState(() {
        _dateIdeas = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Date Ideas',
        textColor: Theme.of(context).colorScheme.onSurface,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _dateIdeas == null
              ? _buildErrorView()
              : _dateIdeas!.isEmpty
              ? _buildEmptyState()
              : _buildRecommendationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        child: Icon(Icons.filter_list),
        tooltip: 'Filter',
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Failed to load date ideas',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _getRecommendations,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No date ideas found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your preferences',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('Adjust Preferences'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: _dateIdeas!.length,
      itemBuilder: (context, index) {
        final dateIdea = _dateIdeas![index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        RecommendationDetailsScreen(dateIdea: dateIdea),
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateIdea.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      dateIdea.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateIdea.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        dateIdea.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${dateIdea.averageCost.toStringAsFixed(0)}',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Date Ideas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Activity Level',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _activityLevel.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _activityLevel.toString(),
                    onChanged: (value) {
                      setState(() => _activityLevel = value.round());
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Dietary Restrictions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Switch(
                        value: _dietaryRestrictions,
                        onChanged: (value) {
                          setState(() => _dietaryRestrictions = value);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _getRecommendations();
                      },
                      child: Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
