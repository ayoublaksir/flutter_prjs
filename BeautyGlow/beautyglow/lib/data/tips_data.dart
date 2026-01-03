import '../models/beauty_tip.dart';

// Import all batch files
import 'batches/batch_01_basic_skincare.dart';
import 'batches/batch_02_advanced_skincare.dart';
import 'batches/batch_03_makeup_basics.dart';
import 'batches/batch_04_advanced_makeup.dart';
import 'batches/batch_05_haircare_basics.dart';
import 'batches/batch_06_advanced_haircare.dart';
import 'batches/batch_07_lifestyle_wellness.dart';
import 'batches/batch_08_nutrition_beauty.dart';
import 'batches/batch_09_beauty_tools.dart';
import 'batches/batch_10_special_occasions.dart';
import 'batches/batch_11_seasonal_beauty.dart';
import 'batches/batch_12_anti_aging.dart';
import 'batches/batch_13_teen_beauty.dart';
import 'batches/batch_14_mens_grooming.dart';
import 'batches/batch_15_mature_beauty.dart';
import 'batches/batch_16_natural_organic.dart';
import 'batches/batch_17_fitness_beauty.dart';
import 'batches/batch_18_cultural_beauty.dart';

// ========================================
// BEAUTYGLOW TIPS DATABASE
// ========================================
// Comprehensive beauty tips organized in thematic batches
// Total: 12 batches covering all beauty categories

// Helper function to get all tips
List<BeautyTip> getAllTips() {
  return [
    // SKINCARE FUNDAMENTALS
    ...batch1_BasicSkincareFundamentals, // 7 articles
    ...batch2_AdvancedSkincareTrials, // 6 articles

    // MAKEUP MASTERY
    ...batch3_MakeupBasics, // 6 articles
    ...batch4_AdvancedMakeupTechniques, // 5 articles

    // HAIRCARE EXPERTISE
    ...batch5_HaircareFundamentals, // 6 articles
    ...batch6_AdvancedHaircare, // 6 articles

    // LIFESTYLE & WELLNESS
    ...batch7_LifestyleWellness, // 5 articles
    ...batch8_NutritionBeauty, // 5 articles

    // TOOLS & TECHNIQUES
    ...batch9_BeautyTools, // 5 articles

    // SPECIAL OCCASIONS
    ...batch10_SpecialOccasions, // 5 articles

    // SEASONAL & ADVANCED CARE
    ...batch11_SeasonalBeauty, // 5 articles
    ...batch12_AntiAging, // 5 articles

    // TEEN & YOUNG SKIN
    ...batch13_TeenBeauty, // 5 articles

    // MEN'S GROOMING
    ...batch14_MensGrooming, // 5 articles

    // MATURE BEAUTY
    ...batch15_MatureBeauty, // 5 articles

    // NATURAL & ORGANIC
    ...batch16_NaturalOrganic, // 5 articles

    // FITNESS & ACTIVE LIFESTYLE
    ...batch17_FitnessBeauty, // 5 articles

    // CULTURAL BEAUTY
    ...batch18_CulturalBeauty, // 5 articles
  ];
}

// Helper function to get tips by category
List<BeautyTip> getTipsByCategory(String category) {
  return getAllTips().where((tip) => tip.category == category).toList();
}

// Helper function to get tips by batch
Map<String, List<BeautyTip>> getTipsByBatch() {
  return {
    'Basic Skincare Fundamentals': batch1_BasicSkincareFundamentals,
    'Advanced Skincare Treatments': batch2_AdvancedSkincareTrials,
    'Makeup Basics': batch3_MakeupBasics,
    'Advanced Makeup Techniques': batch4_AdvancedMakeupTechniques,
    'Hair Care Basics': batch5_HaircareFundamentals,
    'Advanced Hair Care': batch6_AdvancedHaircare,
    'Lifestyle & Wellness': batch7_LifestyleWellness,
    'Nutrition & Beauty': batch8_NutritionBeauty,
    'Beauty Tools & Techniques': batch9_BeautyTools,
    'Special Occasions & Events': batch10_SpecialOccasions,
    'Seasonal Beauty Care': batch11_SeasonalBeauty,
    'Anti-Aging & Mature Beauty': batch12_AntiAging,
    'Teen Beauty & Young Skin': batch13_TeenBeauty,
    'Men\'s Grooming': batch14_MensGrooming,
    'Mature Beauty': batch15_MatureBeauty,
    'Natural & Organic Beauty': batch16_NaturalOrganic,
    'Fitness & Active Beauty': batch17_FitnessBeauty,
    'Cultural Beauty Traditions': batch18_CulturalBeauty,
  };
}

// Export the main tips list (for backward compatibility)
final List<BeautyTip> beautyTips = getAllTips();

// Statistics
int get totalTips => getAllTips().length;
int get totalBatches => 18;
Map<String, int> get tipsByCategory {
  final tips = getAllTips();
  return {
    'skincare': tips.where((t) => t.category == 'skincare').length,
    'makeup': tips.where((t) => t.category == 'makeup').length,
    'haircare': tips.where((t) => t.category == 'haircare').length,
    'lifestyle': tips.where((t) => t.category == 'lifestyle').length,
  };
}
