enum DateCategory {
  restaurant,
  cafe,
  bar,
  outdoorActivity,
  movie,
  concert,
  museum,
  park,
  beach,
  sportsEvent,
  cookingClass,
}

extension DateCategoryExtension on DateCategory {
  String get displayName {
    switch (this) {
      case DateCategory.restaurant:
        return 'Restaurant';
      case DateCategory.cafe:
        return 'Cafe';
      case DateCategory.bar:
        return 'Bar';
      case DateCategory.outdoorActivity:
        return 'Outdoor Activity';
      case DateCategory.movie:
        return 'Movie';
      case DateCategory.concert:
        return 'Concert';
      case DateCategory.museum:
        return 'Museum';
      case DateCategory.park:
        return 'Park';
      case DateCategory.beach:
        return 'Beach';
      case DateCategory.sportsEvent:
        return 'Sports Event';
      case DateCategory.cookingClass:
        return 'Cooking Class';
    }
  }
}
