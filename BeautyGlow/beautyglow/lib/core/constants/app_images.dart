/// Asset path constants for images and icons
class AppImages {
  // Private constructor to prevent instantiation
  AppImages._();

  // Base paths
  static const String _basePath = 'assets/images';
  static const String _appPath = '$_basePath/app';
  static const String _categoriesPath = '$_basePath/categories';
  static const String _productsPath = '$_basePath/products';
  static const String _tipsPath = '$_basePath/tips';
  static const String _achievementsPath = '$_basePath/achievements';
  static const String _routinesPath = '$_basePath/routines';
  static const String _iconsPath = 'assets/icons';

  // App branding
  static const String logo = '$_appPath/logo.png';
  static const String splashBackground = '$_appPath/splash_bg.png';
  static const String welcomeIllustration =
      '$_appPath/welcome_illustration.png';

  // Category icons
  static const String skincareIcon = '$_categoriesPath/skincare_icon.png';
  static const String makeupIcon = '$_categoriesPath/makeup_icon.png';
  static const String haircareIcon = '$_categoriesPath/haircare_icon.png';
  static const String fragranceIcon = '$_categoriesPath/fragrance_icon.png';
  static const String bodycareIcon = '$_categoriesPath/bodycare_icon.png';

  // Product images
  static const String placeholderProduct =
      '$_productsPath/placeholder_product.png';
  static const String cleanserSample = '$_productsPath/cleanser_sample.jpg';
  static const String moisturizerSample =
      '$_productsPath/moisturizer_sample.jpg';
  static const String mascaraSample = '$_productsPath/mascara_sample.jpg';
  static const String lipstickSample = '$_productsPath/lipstick_sample.jpg';
  static const String serumSample = '$_productsPath/serum_sample.jpg';

  // Beauty tips
  static const String skincareTip1 = '$_tipsPath/skincare_tip1.jpg';
  static const String skincareTip2 = '$_tipsPath/skincare_tip2.jpg';
  static const String makeupTip1 = '$_tipsPath/makeup_tip1.jpg';
  static const String makeupTip2 = '$_tipsPath/makeup_tip2.jpg';
  static const String haircareTip1 = '$_tipsPath/haircare_tip1.jpg';
  static const String lifestyleTip1 = '$_tipsPath/lifestyle_tip1.jpg';

  // Achievement badges
  static const String badgeFirstRoutine =
      '$_achievementsPath/badge_first_routine.png';
  static const String badgeWeekStreak =
      '$_achievementsPath/badge_week_streak.png';
  static const String badgeMonthMaster =
      '$_achievementsPath/badge_month_master.png';
  static const String badgeProductCollector =
      '$_achievementsPath/badge_product_collector.png';
  static const String badgeBeautyGuru =
      '$_achievementsPath/badge_beauty_guru.png';

  // Routine backgrounds
  static const String morningRoutineBg =
      '$_routinesPath/morning_routine_bg.jpg';
  static const String eveningRoutineBg =
      '$_routinesPath/evening_routine_bg.jpg';
  static const String stepCleansing = '$_routinesPath/step_cleansing.png';
  static const String stepMoisturizing = '$_routinesPath/step_moisturizing.png';
  static const String stepSunscreen = '$_routinesPath/step_sunscreen.png';
  static const String stepMakeupRemoval =
      '$_routinesPath/step_makeup_removal.png';

  // App icons
  static const String appIcon = '$_iconsPath/app_icon.png';
  static const String adaptiveIconForeground =
      '$_iconsPath/adaptive_icon_foreground.png';

  // Helper method to get category icon by name
  static String getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'skincare':
        return skincareIcon;
      case 'makeup':
        return makeupIcon;
      case 'haircare':
        return haircareIcon;
      case 'fragrance':
        return fragranceIcon;
      case 'bodycare':
        return bodycareIcon;
      default:
        return placeholderProduct;
    }
  }

  // Helper method to get achievement badge by id
  static String getAchievementBadge(String achievementId) {
    switch (achievementId) {
      case 'first_routine':
        return badgeFirstRoutine;
      case 'week_streak':
        return badgeWeekStreak;
      case 'month_master':
        return badgeMonthMaster;
      case 'product_collector':
        return badgeProductCollector;
      case 'beauty_guru':
        return badgeBeautyGuru;
      default:
        return badgeFirstRoutine;
    }
  }
}
