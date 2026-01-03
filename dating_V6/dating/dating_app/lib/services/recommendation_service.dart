import '../models/date_category.dart';
import '../models/date_mood.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/date_models.dart' as models;
import '../models/user_profile.dart';
import '../services/places_service.dart';
import '../models/date_models.dart' show UserPreferences;
import '../models/relationship_stage.dart';

class RecommendationService {
  final PlacesService _placesService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RecommendationService(this._placesService);

  Future<List<models.DateIdea>> getRecommendations({
    required RelationshipStage relationshipStage,
    required List<DateMood> moods,
    required List<DateCategory> categories,
    required bool dietaryRestrictions,
    required int activityLevel,
    required LatLng userLocation,
  }) async {
    try {
      // Make sure we have at least one category
      final category =
          categories.isNotEmpty ? categories.first : DateCategory.restaurant;

      // Get places from the Places service
      final places = await _placesService.getPlacesByCategory(
        category,
        userLocation,
        100.0, // Default budget
      );

      // Convert places to date ideas
      return places
          .map(
            (place) => models.DateIdea(
              id: place.id,
              name: place.name,
              description: 'Visit ${place.name} located at ${place.address}',
              category: category,
              mood: moods.isNotEmpty ? moods.first : DateMood.romantic,
              suitableStages: [relationshipStage],
              averageCost: place.priceRange,
              imageUrl:
                  place.websiteUrl.isNotEmpty
                      ? place.websiteUrl
                      : 'https://via.placeholder.com/400x300?text=No+Image',
              conversationTopics: _generateTopics(category),
              prepTips: _generateTips(category),
              locationDetails: [place.address],
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      // Return some mock data if there's an error
      return _getMockDateIdeas();
    }
  }

  List<models.DateIdea> _getMockDateIdeas() {
    return [
      models.DateIdea(
        id: '1',
        name: 'Romantic Dinner',
        description: 'Enjoy a candlelit dinner at a cozy restaurant',
        category: DateCategory.restaurant,
        mood: DateMood.romantic,
        suitableStages: [RelationshipStage.dating],
        averageCost: 80.0,
        imageUrl:
            'https://images.unsplash.com/photo-1414235077428-338989a2e8c0',
        conversationTopics: ['Favorite foods', 'Travel dreams'],
        prepTips: ['Make a reservation', 'Dress nicely'],
        locationDetails: ['Downtown area'],
      ),
      models.DateIdea(
        id: '2',
        name: 'Coffee Shop Chat',
        description: 'Get to know each other at a trendy coffee shop',
        category: DateCategory.cafe,
        mood: DateMood.chill,
        suitableStages: [RelationshipStage.firstDate],
        averageCost: 20.0,
        imageUrl:
            'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb',
        conversationTopics: ['Hobbies', 'Books and movies'],
        prepTips: ['Arrive on time', 'Keep it casual'],
        locationDetails: ['City center'],
      ),
      models.DateIdea(
        id: '3',
        name: 'Hiking Adventure',
        description: 'Explore nature trails and enjoy scenic views',
        category: DateCategory.outdoorActivity,
        mood: DateMood.adventurous,
        suitableStages: [RelationshipStage.dating],
        averageCost: 10.0,
        imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306',
        conversationTopics: ['Outdoor activities', 'Travel experiences'],
        prepTips: ['Wear comfortable shoes', 'Bring water'],
        locationDetails: ['Local nature reserve'],
      ),
    ];
  }

  List<String> _generateTopics(DateCategory category) {
    switch (category) {
      case DateCategory.restaurant:
        return ['Favorite cuisines', 'Cooking experiences'];
      case DateCategory.museum:
        return ['Art interests', 'Historical events'];
      default:
        return ['Hobbies', 'Travel experiences'];
    }
  }

  List<String> _generateTips(DateCategory category) {
    switch (category) {
      case DateCategory.restaurant:
        return ['Make a reservation', 'Check the dress code'];
      case DateCategory.park:
        return ['Check weather forecast', 'Bring water'];
      default:
        return ['Arrive 10 minutes early', 'Check reviews'];
    }
  }
}
