enum DateMood { romantic, adventurous, relaxed, intellectual, fun, chill }

extension DateMoodExtension on DateMood {
  String get displayName {
    switch (this) {
      case DateMood.romantic:
        return 'Romantic';
      case DateMood.adventurous:
        return 'Adventurous';
      case DateMood.relaxed:
        return 'Relaxed';
      case DateMood.intellectual:
        return 'Intellectual';
      case DateMood.fun:
        return 'Fun';
      case DateMood.chill:
        return 'Chill';
    }
  }
}
