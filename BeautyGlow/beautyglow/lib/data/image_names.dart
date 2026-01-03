// List of all image names used in beauty tips articles
// These images are stored in assets/images/tips/

const List<String> beautyTipImageNames = [
  // BATCH 1: BASIC SKINCARE FUNDAMENTALS
  'double_cleansing.png',
  'skin_types.png',
  'gentle_exfoliation.png',
  'hydration_essentials.png',
  'ph_balance.png',
  'perfect_cleansing.png',
  'sunscreen_protection.png',
  'barrier_repair.png',

  // BATCH 2: ADVANCED SKINCARE TRIALS
  'night_skincare.png',
  'anti_aging.png',
  'acne_care.png',
  'sensitive_skin.png',
  'chemical_peels.png',
  'rosacea_management.png',

  // BATCH 3: MAKEUP BASICS
  'foundation_application.png',
  'eye_shapes.png',
  'lip_application.png',
  'brush_guide.png',
  'color_theory.png',
  'natural_makeup.png',
  'color_correcting.png',
  'makeup_brushes.png',

  // BATCH 4: ADVANCED MAKEUP TECHNIQUES
  'advanced_contouring.png',
  'contouring_basics.png',
  'color_theory_makeup.png',
  'evening_glam.png',
  'professional_artistry.png',
  'editorial_makeup.png',

  // BATCH 5: HAIRCARE FUNDAMENTALS
  'scalp_care.png',
  'hair_types.png',
  'hair_oils.png',
  'hair_growth.png',
  'heat_protection.png',
  'hair_washing.png',
  'hair_porosity.png',
  'natural_hair_care.png',

  // BATCH 6: ADVANCED HAIRCARE
  'advanced_haircare.png',
  'diy_hair_masks.png',
  'hair_oil_treatments.png',
  'hair_ph_balance.png',
  'professional_cutting.png',
  'color_protection.png',

  // BATCH 7: LIFESTYLE & WELLNESS
  'beauty_sleep.png',
  'stress_management.png',
  'digital_detox.png',
  'mindful_beauty.png',
  'wellness_rituals.png',
  'exercise_beauty.png',

  // BATCH 8: NUTRITION & BEAUTY
  'beauty_foods.png',
  'nutrition.png',
  'beauty_nutrition.png',
  'hydration_beauty.png',
  'anti_inflammatory_foods.png',
  'gut_skin_connection.png',
  'beauty_superfoods.png',

  // BATCH 9: BEAUTY TOOLS & TECHNIQUES
  'beauty_tools.png',
  'facial_massage.png',
  'beauty_devices.png',
  'professional_vs_diy.png',
  'makeup_tools.png',
  'hair_styling_safety.png',

  // BATCH 10: SPECIAL OCCASIONS
  'special_occasions.png',
  'wedding_beauty.png',
  'date_night_glamour.png',
  'professional_presentation.png',
  'party_makeup.png',
  'travel_beauty.png',

  // BATCH 11: SEASONAL BEAUTY
  'seasonal_beauty.png',
  'spring_beauty.png',

  // BATCH 12: ANTI-AGING
  'anti_aging_care.png',

  // BATCH 13: TEEN BEAUTY
  'teen_skincare.png',
  'acne_prevention.png',
  'natural_glow.png',
  'first_makeup_kit.png',
  'teen_acne_management.png',
  'teen_body_confidence.png',
  'budget_beauty_students.png',

  // BATCH 14: MEN'S GROOMING
  'mens_skincare.png',
  'beard_care.png',
  'grooming_essentials.png',
  'perfect_shaving.png',
  'mens_hair_styling.png',
  'mens_body_care.png',

  // BATCH 15: MATURE BEAUTY
  'mature_skincare.png',
  'age_gracefully.png',
  'radiant_aging.png',
  'mature_makeup.png',
  'mature_hair_care.png',
  'embracing_natural_aging.png',
  'wellness_after_50.png',

  // BATCH 16: NATURAL & ORGANIC
  'organic_beauty.png',
  'natural_ingredients.png',
  'eco_friendly_beauty.png',
  'natural_beauty_guide.png',
  'diy_beauty_recipes.png',
  'sustainable_beauty.png',
  'organic_ingredients.png', // Note: duplicate in batch file
  'clean_beauty_movement.png',
  'natural_masks.png', // Exists in assets directory

  // BATCH 17: FITNESS & ACTIVE BEAUTY
  'workout_beauty.png',
  'sweat_proof_makeup.png',
  'post_exercise_care.png',
  'workout_proof_makeup.png',
  'post_workout_skincare.png',
  'active_lifestyle_hair.png',
  'athletic_performance_beauty.png',
  'recovery_self_care.png',

  // BATCH 18: CULTURAL BEAUTY
  'global_beauty.png',
  'traditional_remedies.png',
  'cultural_practices.png',
  'global_beauty_traditions.png',
  'ayurvedic_beauty.png',
  'traditional_hair_rituals.png',
  'inclusive_beauty_standards.png',
  'beauty_rituals_mindfulness.png',
];

// Helper function to get image path
String getImagePath(String imageName) {
  return 'assets/images/tips/$imageName';
}

// Helper function to validate if an image exists in the list
bool isValidImageName(String imageName) {
  return beautyTipImageNames.contains(imageName);
}

// Helper function to get all images for a specific batch
List<String> getImagesForBatch(int batchNumber) {
  if (batchNumber < 1 || batchNumber > 18) {
    throw ArgumentError('Batch number must be between 1 and 18');
  }

  // Find all images that belong to the specified batch
  final startComment = '// BATCH $batchNumber:';
  final nextBatchNumber = batchNumber + 1;
  final endComment = batchNumber < 18 ? '// BATCH $nextBatchNumber:' : null;

  int startIndex = -1;
  int endIndex = -1;

  for (int i = 0; i < beautyTipImageNames.length; i++) {
    if (beautyTipImageNames[i].startsWith(startComment)) {
      startIndex = i + 1;
    } else if (endComment != null &&
        beautyTipImageNames[i].startsWith(endComment)) {
      endIndex = i;
      break;
    }
  }

  if (startIndex == -1) {
    return [];
  }

  if (endIndex == -1) {
    endIndex = beautyTipImageNames.length;
  }

  return beautyTipImageNames.sublist(startIndex, endIndex);
}
