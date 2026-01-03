
import 'package:dating_app/models/date_models.dart';

class DateMockData {
  static final List<DateIdea> dateIdeas = [
    // Romantic Date Ideas
    DateIdea(
      id: 'romantic-park-picnic',
      name: 'Sunset Park Picnic',
      description: 'A cozy picnic in a scenic park with beautiful sunset views.',
      category: DateCategory.park,
      mood: DateMood.romantic,
      suitableStages: [RelationshipStage.casual, RelationshipStage.longTerm],
      averageCost: 50.0,
      imageUrl: 'https://example.com/picnic.jpg',
      conversationTopics: [
        'Your dreams and aspirations',
        'Favorite travel memories',
        'What makes you feel loved'
      ],
      prepTips: [
        'Pack a comfortable blanket',
        'Bring some light snacks',
        'Check weather forecast'
      ],
      locationDetails: [
        'Bring portable speaker for background music',
        'Consider bringing cheese and wine',
        'Sunset timing varies by season'
      ],
    ),
    DateIdea(
      id: 'romantic-dinner',
      name: 'Candlelight Dinner',
      description: 'An intimate dinner at a cozy, romantic restaurant.',
      category: DateCategory.restaurant,
      mood: DateMood.romantic,
      suitableStages: [RelationshipStage.firstDate, RelationshipStage.longTerm],
      averageCost: 100.0,
      imageUrl: 'https://example.com/candlelight-dinner.jpg',
      conversationTopics: [
        'Your childhood memories',
        'Future life goals',
        'What romance means to you'
      ],
      prepTips: [
        'Make a reservation in advance',
        'Dress appropriately',
        'Consider dietary preferences'
      ],
      locationDetails: [
        'Choose restaurants with dim lighting',
        'Consider restaurants with private seating',
        'Check for live music options'
      ],
    ),
    // More date ideas...
  ];

  // Conversation Starters
  static final Map<RelationshipStage, List<String>> conversationStarters = {
    RelationshipStage.firstDate: [
      'What\'s the most interesting thing that happened to you this week?',
      'If you could travel anywhere right now, where would you go?',
      'What\'s something you\'re passionate about?'
    ],
    RelationshipStage.casual: [
      'What\'s your idea of a perfect weekend?',
      'Tell me about a skill you\'d love to learn',
      'What\'s the most memorable adventure you\'ve had?'
    ],
    RelationshipStage.longTerm: [
      'What are your long-term life goals?',
      'How do you envision our future together?',
      'What\'s something you appreciate about our relationship?'
    ]
  };
}