enum RelationshipStage { firstDate, dating, exclusive, serious, longTerm }

extension RelationshipStageExtension on RelationshipStage {
  String get displayName {
    switch (this) {
      case RelationshipStage.firstDate:
        return 'First Date';
      case RelationshipStage.dating:
        return 'Dating';
      case RelationshipStage.exclusive:
        return 'Exclusive';
      case RelationshipStage.serious:
        return 'Serious';
      case RelationshipStage.longTerm:
        return 'Long Term';
    }
  }
}
