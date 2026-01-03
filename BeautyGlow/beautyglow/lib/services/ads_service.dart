import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/config/ads_config.dart';
import 'mediation_service.dart';

class AdsService extends ChangeNotifier {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  // Mediation service
  final MediationService _mediationService = MediationService();

  // Ad instances
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  NativeAd? _nativeAd;
  AppOpenAd? _appOpenAd;
  RewardedAd? _rewardedAd;

  // Ad state tracking
  bool _isInterstitialAdReady = false;
  bool _isBannerAdReady = false;
  bool _isNativeAdReady = false;
  bool _isAppOpenAdReady = false;
  bool _isRewardedAdReady = false;

  // Smart ad placement tracking
  // Separate counters for different ad types
  int _interstitialSwipeCount = 0; // For interstitial ads
  int _rewardedSwipeCount = 0; // For rewarded ads
  bool _isShowingInterstitial = false;
  DateTime? _lastInterstitialShowTime; // Cooldown tracking

  // Daily limits are now dynamically fetched from Firebase via getters

  int _todaySwipes = 0;
  int _todaySaves = 0;
  int _todayPlannings = 0;

  DateTime? _lastResetDate;

  // Getters for ad readiness
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  bool get isBannerAdReady => _isBannerAdReady;
  bool get isNativeAdReady => _isNativeAdReady;
  bool get isAppOpenAdReady => _isAppOpenAdReady;
  bool get isRewardedAdReady => _isRewardedAdReady;
  int get interstitialSwipeCount => _interstitialSwipeCount;
  int get rewardedSwipeCount => _rewardedSwipeCount;

  // Backward compatibility getter - uses interstitial counter for general swipe tracking
  int get swipeCount => _interstitialSwipeCount;

  // Getters for daily limits (reactive to Firebase changes)
  int get remainingSwipes => dailySwipeLimit - _todaySwipes;
  int get remainingSaves => dailySaveLimit - _todaySaves;
  int get remainingPlannings => dailyPlanningLimit - _todayPlannings;

  // Dynamic getters that always fetch current Firebase values
  int get dailySwipeLimit {
    final firebaseLimit = AdsConfig.getIntValue('daily_swipe_limit');
    return firebaseLimit > 0 ? firebaseLimit : 15;
  }

  int get dailySaveLimit {
    final firebaseLimit = AdsConfig.getIntValue('daily_save_limit');
    return firebaseLimit > 0 ? firebaseLimit : 5;
  }

  int get dailyPlanningLimit {
    final firebaseLimit = AdsConfig.getIntValue('daily_planning_limit');
    return firebaseLimit > 0 ? firebaseLimit : 3;
  }

  // Swipe lock state for rewarded ads
  bool _isSwipeLocked = false;

  bool get canSwipe => _todaySwipes < dailySwipeLimit && !_isSwipeLocked;
  bool get canSave => _todaySaves < dailySaveLimit;
  bool get canPlan => _todayPlannings < dailyPlanningLimit;
  bool get isSwipeLocked => _isSwipeLocked;

  /// Initialize AdService with mediation
  Future<void> init() async {
    debugPrint(
        '📱 AdsService: Initializing with mediation and smart placement');

    // Initialize daily limits from Firebase Remote Config
    _initializeDailyLimitsFromFirebase();

    // Initialize mediation service
    await _mediationService.init();

    _checkAndResetDailyLimits();

    // Load all ad types with retry
    _loadAllAdsWithRetry();

    debugPrint('📱 AdsService: All ads loading started');
  }

  /// Initialize daily limits from Firebase Remote Config
  void _initializeDailyLimitsFromFirebase() {
    // Daily limits are now fetched dynamically via getters
    debugPrint('📊 AdsService: ===== DAILY LIMITS FROM FIREBASE =====');
    debugPrint(
        '📊 AdsService: Swipes: $dailySwipeLimit (from Firebase: daily_swipe_limit)');
    debugPrint(
        '📊 AdsService: Saves: $dailySaveLimit (from Firebase: daily_save_limit)');
    debugPrint(
        '📊 AdsService: Planning: $dailyPlanningLimit (from Firebase: daily_planning_limit)');
    debugPrint('📊 AdsService: ===== END DAILY LIMITS =====');
  }

  /// Development method to refresh Firebase Remote Config and reinitialize limits
  Future<void> devRefreshFirebaseConfig() async {
    if (!kDebugMode) {
      debugPrint(
          '⚠️ AdsService: devRefreshFirebaseConfig only works in debug mode');
      return;
    }

    debugPrint(
        '🔄 AdsService: Refreshing Firebase Remote Config for development...');

    // Force refresh Firebase Remote Config
    await AdsConfig.devRefreshNow();

    // Show updated daily limits (now dynamic)
    _initializeDailyLimitsFromFirebase();

    // Notify listeners to update UI with new Firebase values
    notifyListeners();

    debugPrint('✅ AdsService: Firebase config refreshed and limits updated');
  }

  /// Load all ads with retry mechanism
  void _loadAllAdsWithRetry() {
    debugPrint('📱 AdsService: Starting to load all ad types...');

    // Load interstitial with retry
    loadInterstitialAd().catchError((error) {
      debugPrint('❌ AdsService: Failed to load interstitial: $error');
      Future.delayed(const Duration(seconds: 5), () {
        debugPrint('🔄 AdsService: Retrying interstitial load...');
        loadInterstitialAd();
      });
    });

    // Load rewarded with retry
    loadRewardedAd().catchError((error) {
      debugPrint('❌ AdsService: Failed to load rewarded: $error');
      Future.delayed(const Duration(seconds: 10), () {
        debugPrint('🔄 AdsService: Retrying rewarded load...');
        loadRewardedAd();
      });
    });

    // Load app open with retry
    loadAppOpenAd().catchError((error) {
      debugPrint('❌ AdsService: Failed to load app open: $error');
      Future.delayed(const Duration(seconds: 15), () {
        debugPrint('🔄 AdsService: Retrying app open load...');
        loadAppOpenAd();
      });
    });

    debugPrint('📱 AdsService: All ad load requests sent');
  }

  /// Check and reset daily limits
  void _checkAndResetDailyLimits() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      _todaySwipes = 0;
      _todaySaves = 0;
      _todayPlannings = 0;
      _lastResetDate = today;

      // Reset separate ad counters for new day
      _interstitialSwipeCount = 0;
      _rewardedSwipeCount = 0;
      _isSwipeLocked = false;
      debugPrint(
          '📊 AdsService: Daily limits reset for ${today.toIso8601String()}');
    }
  }

  /// Track engagement actions (DEPRECATED - use trackSwipe instead)
  void trackEngagementAction(String action) {
    debugPrint(
        '📊 AdsService: Engagement tracked - $action (DEPRECATED - using trackSwipe)');
    // Do not increment _swipeCount here - trackSwipe() handles all swipe counting
  }

  /// Track swipe for interstitial ads only (independent counter)
  void trackSwipe() {
    _interstitialSwipeCount++;
    debugPrint(
        '📊 AdsService: Interstitial swipe tracked (count: $_interstitialSwipeCount)');

    // Show interstitial every X swipes from Firebase Remote Config
    final requiredSwipes = AdsConfig.interstitialFrequencyFromFirebase;

    if (_interstitialSwipeCount % requiredSwipes == 0) {
      debugPrint(
          '🎯 AdsService: Interstitial trigger point reached at swipe $_interstitialSwipeCount [Firebase: every $requiredSwipes swipes]');
      showInterstitialAd();
    } else {
      final remaining =
          requiredSwipes - (_interstitialSwipeCount % requiredSwipes);
      debugPrint(
          '📊 AdsService: Interstitial swipe $_interstitialSwipeCount - $remaining more to next interstitial [Firebase: every $requiredSwipes]');
    }
  }

  /// Track swipe for rewarded ads - locks swiping when limit reached
  bool trackSwipeForRewarded() {
    _checkAndResetDailyLimits();

    if (_todaySwipes >= dailySwipeLimit) {
      debugPrint('🚫 AdsService: Daily swipe limit reached');
      return false;
    }

    if (_isSwipeLocked) {
      debugPrint(
          '🔒 AdsService: Swiping is LOCKED - watch rewarded ad to unlock');
      return false;
    }

    // Increment rewarded swipe count (independent counter)
    _rewardedSwipeCount++;
    debugPrint(
        '🎁 AdsService: Rewarded swipe tracked (count: $_rewardedSwipeCount)');

    // Check if we need to lock swiping for rewarded ad
    final requiredSwipes = AdsConfig.rewardedFrequencyFromFirebase;
    debugPrint('🎁 AdsService: Required swipes for reward: $requiredSwipes');

    if (requiredSwipes > 0 && _rewardedSwipeCount % requiredSwipes == 0) {
      _isSwipeLocked = true;
      debugPrint(
          '🔒 AdsService: ⚠️ SWIPING LOCKED ⚠️ at rewarded swipe $_rewardedSwipeCount - watch ad to unlock');
      debugPrint(
          '🎁 AdsService: Need to watch rewarded ad to get ${requiredSwipes} more swipes');
    } else {
      final remaining = requiredSwipes > 0
          ? requiredSwipes - (_rewardedSwipeCount % requiredSwipes)
          : 0;
      debugPrint(
          '🎁 AdsService: Rewarded swipe $_rewardedSwipeCount - $remaining more until lock');
    }

    notifyListeners();
    return true;
  }

  /// Reset interstitial swipe counter (called after showing interstitial)
  void resetSwipeCounter() {
    debugPrint(
        '🔄 AdsService: Resetting interstitial counter from $_interstitialSwipeCount to 0');
    _interstitialSwipeCount = 0;
    debugPrint(
        '🎁 AdsService: Rewarded counter unchanged: $_rewardedSwipeCount');
  }

  /// Track save action (legacy method for compatibility)
  bool trackSave() {
    debugPrint('💾 AdsService: ==> SAVE TRACKING DEBUG <==');
    debugPrint('💾 AdsService: Current saves today: $_todaySaves');
    debugPrint('💾 AdsService: Daily save limit: $dailySaveLimit');
    debugPrint('💾 AdsService: Can save: $canSave');

    _checkAndResetDailyLimits();

    if (!canSave) {
      debugPrint(
          '🚫 AdsService: SAVE BLOCKED - Daily save limit reached (${_todaySaves}/$dailySaveLimit)');
      return false;
    }

    _todaySaves++;
    debugPrint(
        '✅ AdsService: Save tracked successfully (${_todaySaves}/$dailySaveLimit remaining: $remainingSaves)');
    notifyListeners();
    return true;
  }

  /// Legacy method for recipe swipe (for compatibility)
  Future<void> onRecipeSwipe() async {
    trackSwipe();
  }

  /// Check if should show rewarded ad (legacy method for compatibility)
  bool shouldShowRewardedAd(String reason) {
    // Show rewarded ad when user has low swipes remaining
    if (reason == 'low_swipes_warning' && remainingSwipes <= 3) {
      return true;
    }
    return false;
  }

  // ==========================================================================
  // ADS RESTRICTIONS & CONDITIONS
  // ==========================================================================

  /// Check if user can access premium features
  bool get canAccessPremiumFeatures => _todaySwipes < dailySwipeLimit;

  /// Check if user can plan meals (premium feature)
  bool get canPlanMeals => _todayPlannings < dailyPlanningLimit;

  /// Check if user can save recipes (premium feature)
  bool get canSaveRecipes => _todaySaves < dailySaveLimit;

  /// Check if user can view recipe details (premium feature)
  bool get canViewRecipeDetails => _todaySwipes < dailySwipeLimit;

  /// Check if user can access advanced features
  bool get canAccessAdvancedFeatures => _todaySwipes < dailySwipeLimit;

  /// Check if user is approaching limits (for warnings)
  bool get isApproachingLimits {
    return remainingSwipes <= 3 ||
        remainingSaves <= 1 ||
        remainingPlannings <= 1;
  }

  /// Check if user is at critical limits (for urgent warnings)
  bool get isAtCriticalLimits {
    return remainingSwipes <= 1 ||
        remainingSaves <= 0 ||
        remainingPlannings <= 0;
  }

  /// Check if user has unlimited swipes (rewarded ad benefit)
  bool get hasUnlimitedSwipes => _todaySwipes == 0 && dailySwipeLimit > 15;

  /// Check if user can access meal planning (premium feature)
  bool canAccessMealPlanning() {
    if (!canPlanMeals) {
      debugPrint('🚫 AdsService: Meal planning blocked - daily limit reached');
      return false;
    }
    return true;
  }

  /// Check if user can save recipe (premium feature)
  bool canSaveRecipe() {
    if (!canSaveRecipes) {
      debugPrint('🚫 AdsService: Save recipe blocked - daily limit reached');
      return false;
    }
    return true;
  }

  /// Check if user can view recipe details (premium feature)
  bool canViewRecipeDetailsAction() {
    if (!canViewRecipeDetails) {
      debugPrint('🚫 AdsService: Recipe details blocked - daily limit reached');
      return false;
    }
    return true;
  }

  /// Check if user can access advanced features (premium feature)
  bool canAccessAdvancedFeaturesAction() {
    if (!canAccessAdvancedFeatures) {
      debugPrint(
          '🚫 AdsService: Advanced features blocked - daily limit reached');
      return false;
    }
    return true;
  }

  /// Track meal planning action
  bool trackMealPlanning() {
    debugPrint('📅 AdsService: ==> MEAL PLANNING TRACKING DEBUG <==');
    debugPrint('📅 AdsService: Current plannings today: $_todayPlannings');
    debugPrint('📅 AdsService: Daily planning limit: $dailyPlanningLimit');
    debugPrint('📅 AdsService: Can plan meals: $canPlanMeals');

    _checkAndResetDailyLimits();

    if (!canPlanMeals) {
      debugPrint(
          '🚫 AdsService: PLANNING BLOCKED - Daily meal planning limit reached (${_todayPlannings}/$dailyPlanningLimit)');
      return false;
    }

    _todayPlannings++;
    debugPrint(
        '✅ AdsService: Meal planning tracked successfully (${_todayPlannings}/$dailyPlanningLimit remaining: $remainingPlannings)');
    notifyListeners();
    return true;
  }

  /// Track recipe save action with rewarded ad logic
  bool trackRecipeSave() {
    debugPrint('💾 AdsService: ==> RECIPE SAVE TRACKING DEBUG <==');
    debugPrint('💾 AdsService: Current saves today: $_todaySaves');
    debugPrint('💾 AdsService: Daily save limit: $dailySaveLimit');
    debugPrint('💾 AdsService: Can save recipes: $canSaveRecipes');

    _checkAndResetDailyLimits();

    if (!canSaveRecipes) {
      debugPrint(
          '🚫 AdsService: RECIPE SAVE BLOCKED - Daily save limit reached (${_todaySaves}/$dailySaveLimit)');
      return false;
    }

    _todaySaves++;
    _trackSaveForAds(); // Track for rewarded ads

    debugPrint(
        '✅ AdsService: Recipe save tracked successfully (${_todaySaves}/$dailySaveLimit remaining: $remainingSaves)');
    notifyListeners();
    return true;
  }

  /// Track saves for rewarded ads (like swipe tracking but for saves)
  void _trackSaveForAds() {
    final requiredSaves = AdsConfig.getIntValue('rewarded_saves_frequency');
    debugPrint(
        '💾 AdsService: Save tracking for ads - Total saves: $_todaySaves');

    if (requiredSaves > 0 && _todaySaves % requiredSaves == 0) {
      debugPrint(
          '🎁 AdsService: Rewarded ad trigger point reached at save $_todaySaves [Firebase: every $requiredSaves saves]');
      // Don't auto-show here, let the UI decide when to offer the reward
    } else {
      final remaining =
          requiredSaves > 0 ? requiredSaves - (_todaySaves % requiredSaves) : 0;
      debugPrint(
          '💾 AdsService: Save $_todaySaves - $remaining more to next rewarded ad [Firebase: every $requiredSaves]');
    }
  }

  /// Check if should show rewarded ad for saves
  bool shouldShowRewardedAdForSaves() {
    final requiredSaves = AdsConfig.getIntValue('rewarded_saves_frequency');
    final shouldShow = requiredSaves > 0 &&
        _todaySaves % requiredSaves == 0 &&
        _todaySaves > 0;

    debugPrint(
        '🎁 AdsService: Should show rewarded ad for saves: $shouldShow (saves: $_todaySaves, required: $requiredSaves)');
    return shouldShow;
  }

  /// Check if should show rewarded ad for swipes (when locked)
  bool shouldShowRewardedAdForSwipes() {
    final shouldShow = _isSwipeLocked;

    debugPrint('🎁 AdsService: ===== REWARDED AD CHECK FOR SWIPES =====');
    debugPrint('🎁 AdsService: Is swipe locked: $_isSwipeLocked');
    debugPrint('🎁 AdsService: Should show rewarded ad: $shouldShow');
    debugPrint('🎁 AdsService: =========================================');
    return shouldShow;
  }

  /// Track recipe detail view action
  bool trackRecipeDetailView() {
    _checkAndResetDailyLimits();

    if (!canViewRecipeDetails) {
      debugPrint(
          '⚠️ AdsService: Daily view limit reached (${_todaySwipes}/$dailySwipeLimit)');
      return false;
    }

    _todaySwipes++;
    debugPrint(
        '📱 AdsService: Recipe detail view tracked (${_todaySwipes}/$dailySwipeLimit remaining: $remainingSwipes)');
    return true;
  }

  /// Grant unlimited swipes (rewarded ad benefit)
  void grantUnlimitedSwipes() {
    _todaySwipes = 0; // Reset daily usage
    final unlockAmount = AdsConfig.rewardedFrequencyFromFirebase;
    debugPrint(
        '🎁 AdsService: Swipes reset after rewarded ad (unlock amount: $unlockAmount, daily limit from Firebase: $dailySwipeLimit)');
    notifyListeners();
  }

  /// Unlock swipes after watching rewarded ad (Firebase-controlled amount)
  void unlockSwipes() {
    final unlockAmount = AdsConfig.rewardedFrequencyFromFirebase;

    // Unlock swiping
    _isSwipeLocked = false;

    // Reset ONLY rewarded swipe counter (keep interstitial counter independent)
    _rewardedSwipeCount = 0;

    debugPrint(
        '🔓 AdsService: SWIPES UNLOCKED! Reset rewarded counter and can swipe ${unlockAmount} more times');
    debugPrint(
        '🎁 AdsService: Rewarded counter reset: 0 -> next lock at ${unlockAmount} swipes');
    debugPrint(
        '📊 AdsService: Interstitial counter UNCHANGED: $_interstitialSwipeCount (continues independently)');
    notifyListeners();
  }

  /// Grant additional swipes (Firebase-controlled amount) - DEPRECATED
  void grantAdditionalSwipes(int additionalSwipes) {
    // Use unlockSwipes instead for rewarded ads
    unlockSwipes();
  }

  /// Grant additional saves (rewarded ad benefit)
  void grantAdditionalSaves(int additionalSaves) {
    _todaySaves = 0; // Reset daily usage
    debugPrint(
        '🎁 AdsService: Saves reset after rewarded ad (limit from Firebase: $dailySaveLimit)');
    notifyListeners();
  }

  /// Grant additional meal planning (rewarded ad benefit)
  void grantAdditionalMealPlanning(int additionalPlans) {
    _todayPlannings = 0; // Reset daily usage
    debugPrint(
        '🎁 AdsService: Meal planning slots reset after rewarded ad (limit from Firebase: $dailyPlanningLimit)');
    notifyListeners();
  }

  /// Show rewarded ad for premium features
  Future<bool> showRewardedAdForPremiumFeature({
    required String featureType,
    required Function() onRewardEarned,
    Function()? onAdFailedToShow,
  }) async {
    debugPrint(
        '🎁 AdsService: Showing rewarded ad for premium feature: $featureType');

    return await showRewardedAd(
      featureType: featureType,
      onRewardEarned: () {
        // Reset specific limits based on feature type using Firebase values
        switch (featureType) {
          case 'unlock_swipes':
          case 'bonus_swipes':
            unlockSwipes();
            debugPrint(
                '🔓 AdsService: Unlocked swipes after watching rewarded ad');
            break;
          case 'unlock_saves':
          case 'premium_features':
            grantAdditionalSaves(5);
            break;
          case 'unlock_meal_planning':
            grantAdditionalMealPlanning(3);
            break;
          case 'unlock_advanced_features':
            final rewardedSwipes = AdsConfig.rewardedFrequencyFromFirebase;
            grantAdditionalSwipes(rewardedSwipes);
            grantAdditionalSaves(5);
            grantAdditionalMealPlanning(3);
            break;
        }
        onRewardEarned();
      },
      onAdFailedToShow: onAdFailedToShow,
    );
  }

  /// Check if should show interstitial for specific action
  bool shouldShowInterstitialForAction(String action) {
    debugPrint('🎯 AdsService: Checking interstitial for action: $action');

    // Show ads at high-engagement moments
    switch (action) {
      case 'recipe_detail_view':
        return _interstitialSwipeCount >= 2; // Show after viewing 2 recipes
      case 'recipe_save':
        return _interstitialSwipeCount >= 1; // Show after saving first recipe
      case 'category_change':
        return _interstitialSwipeCount >= 3; // Show after changing categories
      case 'week_plan_open':
        return true; // Always show when planning week (high engagement)
      case 'profile_edit':
        return true; // Show when editing profile (session depth indicator)
      case 'advanced_feature_access':
        return true; // Show when accessing premium features

      // NEW: Routine and Product Creation Actions
      case 'routine_creation':
        return true; // Always show when creating routine (high value action)
      case 'routine_save':
        return _interstitialSwipeCount >= 1; // Show after saving routine
      case 'routine_completion':
        return true; // Always show when completing routine (high engagement)
      case 'product_creation':
        return true; // Always show when brand creates product (high value action)
      case 'ai_routine_generation':
        return true; // Always show after AI generates routine (premium feature)

      default:
        return shouldShowInterstitialAd();
    }
  }

  /// Check if should show rewarded ad for specific context
  bool shouldShowRewardedAdForContext(String context) {
    if (!_isRewardedAdReady) return false;

    _checkAndResetDailyLimits();

    switch (context) {
      case 'unlock_swipes':
        return !canSwipe; // Show when swipe limit reached
      case 'unlock_saves':
        return !canSave; // Show when save limit reached
      case 'unlock_meal_planning':
        return !canPlanMeals; // Show when meal planning limit reached
      case 'recipe_save':
        return _interstitialSwipeCount >= 3; // Show after saving 3rd recipe
      case 'category_complete':
        return true; // Always offer when category is complete
      case 'premium_feature':
        return true; // Always offer for premium features
      case 'recipe_detail_view':
        return _interstitialSwipeCount >= 10; // Show after viewing 10 recipes
      case 'low_swipes_warning':
        return remainingSwipes <= 5 &&
            remainingSwipes > 0; // Show warning when close to limit
      case 'low_saves_warning':
        return remainingSaves <= 2 &&
            remainingSaves > 0; // Show warning when close to limit
      case 'low_planning_warning':
        return remainingPlannings <= 1 &&
            remainingPlannings > 0; // Show warning when close to limit
      case 'advanced_feature_access':
        return !canAccessAdvancedFeatures; // Show when accessing premium features
      default:
        return false;
    }
  }

  // Legacy method removed - now using separate trackSwipe() and trackSwipeForRewarded()

  /// Check if interstitial ad should be shown based on smart logic
  bool shouldShowInterstitialAd() {
    // Check Firebase Remote Config first
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isInterstitialAdsEnabled) {
      debugPrint(
          '🚫 AdsService: Interstitial ads disabled via Firebase Remote Config');
      return false;
    }
    debugPrint('🎯 AdsService: Checking smart interstitial conditions');

    // Don't show if already showing
    if (_isShowingInterstitial) {
      debugPrint('⚠️ AdsService: Already showing interstitial');
      return false;
    }

    // Check frequency - show every X swipes from Firebase Remote Config
    final requiredSwipes = AdsConfig.interstitialFrequencyFromFirebase;
    if (_interstitialSwipeCount < requiredSwipes) {
      debugPrint(
          '📊 AdsService: Not enough swipes ($_interstitialSwipeCount/$requiredSwipes) [Firebase: $requiredSwipes]');
      return false;
    }

    // Check Firebase-controlled cooldown
    if (_lastInterstitialShowTime != null) {
      final timeSinceLastShow =
          DateTime.now().difference(_lastInterstitialShowTime!);
      final cooldownDuration = AdsConfig.interstitialCooldownDuration;

      if (timeSinceLastShow < cooldownDuration) {
        final remainingCooldown = cooldownDuration - timeSinceLastShow;
        debugPrint(
            '⏰ AdsService: Interstitial cooldown active. ${remainingCooldown.inMinutes}m ${remainingCooldown.inSeconds % 60}s remaining');
        return false;
      }
    }

    debugPrint('✅ AdsService: Conditions met for interstitial ad');
    return true;
  }

  /// Load interstitial ad with mediation
  Future<void> loadInterstitialAd() async {
    // Check Firebase Remote Config first
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isInterstitialAdsEnabled) {
      debugPrint(
          '🚫 AdsService: Interstitial ads disabled via Firebase Remote Config - not loading');
      return;
    }

    if (_isInterstitialAdReady) {
      debugPrint('📱 AdsService: Interstitial ad already ready');
      return;
    }

    try {
      debugPrint('📱 AdsService: Loading interstitial ad with mediation...');

      await _mediationService.loadAdWithMediation(
        adType: 'interstitial',
        onAdLoaded: (ad) {
          _interstitialAd = ad as InterstitialAd;
          _isInterstitialAdReady = true;
          debugPrint(
              '✅ AdsService: Interstitial ad loaded from ${_mediationService.currentNetwork}');

          // Set callbacks
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingInterstitial = true;
              debugPrint('📱 AdsService: Interstitial ad showed full screen');
            },
            onAdDismissedFullScreenContent: (ad) {
              _isShowingInterstitial = false;
              _isInterstitialAdReady = false;
              ad.dispose();
              loadInterstitialAd(); // Preload next ad
              debugPrint('📱 AdsService: Interstitial ad dismissed');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isShowingInterstitial = false;
              _isInterstitialAdReady = false;
              ad.dispose();
              loadInterstitialAd(); // Retry loading immediately
              debugPrint(
                  '❌ AdsService: Interstitial ad failed to show: $error');
            },
          );
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ AdsService: Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
          // Aggressive retry for interstitial ads
          Future.delayed(const Duration(seconds: 5), loadInterstitialAd);
        },
      );
    } catch (e) {
      debugPrint('❌ AdsService: Error loading interstitial ad: $e');
      _isInterstitialAdReady = false;
      // Retry on exception
      Future.delayed(const Duration(seconds: 10), loadInterstitialAd);
    }
  }

  /// Show interstitial ad with improved error handling
  Future<void> showInterstitialAd() async {
    debugPrint('🎯 AdsService: Attempting to show interstitial ad');

    // Check Firebase Remote Config first
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isInterstitialAdsEnabled) {
      debugPrint(
          '🚫 AdsService: Interstitial ads disabled via Firebase Remote Config - not showing');
      return;
    }

    if (!_isInterstitialAdReady ||
        _interstitialAd == null ||
        _isShowingInterstitial) {
      debugPrint('⚠️ Interstitial ad not ready or already showing');
      debugPrint('   - Ready: $_isInterstitialAdReady');
      debugPrint('   - Ad exists: ${_interstitialAd != null}');
      debugPrint('   - Showing: $_isShowingInterstitial');

      // Try to load a new ad if not ready
      if (!_isInterstitialAdReady) {
        debugPrint('🔄 Loading new interstitial ad...');
        loadInterstitialAd();
      }
      return;
    }

    try {
      debugPrint('📱 Showing interstitial ad...');
      _isShowingInterstitial = true;
      await _interstitialAd!.show();
      AdPerformanceTracker.trackInterstitialShown();

      // Track timestamp for cooldown
      _lastInterstitialShowTime = DateTime.now();
      final cooldownMinutes = AdsConfig.interstitialCooldownDuration.inMinutes;
      debugPrint(
          '⏰ AdsService: Interstitial cooldown started ($cooldownMinutes minutes) [Firebase controlled]');

      // Reset swipe counter after showing ad
      resetSwipeCounter();

      debugPrint('✅ Interstitial ad shown successfully');
    } catch (e) {
      debugPrint('❌ Error showing interstitial ad: $e');
      _isInterstitialAdReady = false;
      loadInterstitialAd(); // Reload for next time
    } finally {
      _isShowingInterstitial = false;
    }
  }

  /// Load banner ad with mediation
  Future<void> loadBannerAd({
    required AdSize adSize,
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) async {
    // Check Firebase Remote Config first
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isBannerAdsEnabled) {
      debugPrint(
          '🚫 AdsService: Banner ads disabled via Firebase Remote Config - not loading');
      return;
    }

    try {
      debugPrint('📱 AdsService: Loading banner ad with mediation...');

      final ad = await _mediationService.loadAdWithMediation(
        adType: 'banner',
        adSize: adSize,
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      );

      if (ad != null) {
        _bannerAd = ad as BannerAd;
        _isBannerAdReady = true;
        debugPrint(
            '✅ AdsService: Banner ad loaded from ${_mediationService.currentNetwork}');
      }
    } catch (e) {
      debugPrint('❌ AdsService: Error loading banner ad: $e');
      onAdFailedToLoad(_bannerAd!,
          LoadAdError(3, 'ads_service', 'Error loading banner ad', null));
    }
  }

  /// Load rewarded ad
  Future<void> loadRewardedAd() async {
    if (_isRewardedAdReady) return;

    try {
      await RewardedAd.load(
        adUnitId: AdsConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            debugPrint('✅ Rewarded ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isRewardedAdReady = false;
            debugPrint('❌ Rewarded ad failed to load: $error');
            // Retry after delay
            Future.delayed(const Duration(seconds: 30), loadRewardedAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error loading rewarded ad: $e');
      _isRewardedAdReady = false;
    }
  }

  /// Load app open ad
  Future<void> loadAppOpenAd() async {
    if (_isAppOpenAdReady) return;

    try {
      await AppOpenAd.load(
        adUnitId: AdsConfig.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isAppOpenAdReady = true;
            debugPrint('✅ App open ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isAppOpenAdReady = false;
            debugPrint('❌ App open ad failed to load: $error');
            // Retry after delay
            Future.delayed(const Duration(seconds: 45), loadAppOpenAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error loading app open ad: $e');
      _isAppOpenAdReady = false;
    }
  }

  /// Show rewarded ad for premium features
  Future<bool> showRewardedAd({
    required String featureType,
    required Function() onRewardEarned,
    Function()? onAdFailedToShow,
  }) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('⚠️ Rewarded ad not ready');
      onAdFailedToShow?.call();
      return false;
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('🎁 User earned reward for $featureType');
          onRewardEarned();
          AdPerformanceTracker.trackRewardedViewed();
        },
      );

      _isRewardedAdReady = false;
      loadRewardedAd(); // Preload next ad

      debugPrint('✅ Rewarded ad shown successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error showing rewarded ad: $e');
      onAdFailedToShow?.call();
      return false;
    }
  }

  // ==========================================================================
  // ROUTINE-SPECIFIC ADS INTEGRATION
  // ==========================================================================

  /// Show interstitial ad for routine creation
  Future<void> showInterstitialForRoutineCreation() async {
    if (shouldShowInterstitialForAction('routine_creation')) {
      debugPrint('🎯 AdsService: Showing interstitial for routine creation');
      await showInterstitialAd();
    } else {
      debugPrint('🎯 AdsService: Skipping interstitial for routine creation');
    }
  }

  /// Show interstitial ad for routine completion
  Future<void> showInterstitialForRoutineCompletion() async {
    if (shouldShowInterstitialForAction('routine_completion')) {
      debugPrint('🎯 AdsService: Showing interstitial for routine completion');
      await showInterstitialAd();
    } else {
      debugPrint('🎯 AdsService: Skipping interstitial for routine completion');
    }
  }

  /// Show interstitial ad for routine save
  Future<void> showInterstitialForRoutineSave() async {
    if (shouldShowInterstitialForAction('routine_save')) {
      debugPrint('🎯 AdsService: Showing interstitial for routine save');
      await showInterstitialAd();
    } else {
      debugPrint('🎯 AdsService: Skipping interstitial for routine save');
    }
  }

  /// Show interstitial ad for product creation
  Future<void> showInterstitialForProductCreation() async {
    if (shouldShowInterstitialForAction('product_creation')) {
      debugPrint('🎯 AdsService: Showing interstitial for product creation');
      await showInterstitialAd();
    } else {
      debugPrint('🎯 AdsService: Skipping interstitial for product creation');
    }
  }

  /// Track routine creation activity (for analytics and ad frequency)
  void trackRoutineCreation() {
    debugPrint('📊 AdsService: Routine creation tracked');
    // This helps with ad frequency calculations
    trackSwipe(); // Contributes to overall engagement
  }

  /// Track routine completion activity (for analytics and ad frequency)
  void trackRoutineCompletion() {
    debugPrint('📊 AdsService: Routine completion tracked');
    // This helps with ad frequency calculations
    trackSwipe(); // Contributes to overall engagement
  }

  /// Track product creation activity (for analytics and ad frequency)
  void trackProductCreation() {
    debugPrint('📊 AdsService: Product creation tracked');
    // This helps with ad frequency calculations
    trackSwipe(); // Contributes to overall engagement
  }

  /// Check if should show rewarded ad for routine features
  bool shouldShowRewardedAdForRoutine(String context) {
    switch (context) {
      case 'unlock_premium_routines':
        return !canAccessAdvancedFeatures;
      case 'ai_routine_generation':
        return true; // Always offer rewarded ad for AI features
      case 'routine_customization':
        return _interstitialSwipeCount >= 3;
      case 'routine_sharing':
        return true; // Offer rewarded ad for sharing features
      default:
        return shouldShowRewardedAdForContext(context);
    }
  }

  /// Show rewarded ad for routine premium features
  Future<bool> showRewardedAdForRoutineFeature({
    required String featureType,
    required Function() onRewardEarned,
    Function()? onAdFailedToShow,
  }) async {
    debugPrint(
        '🎁 AdsService: Showing rewarded ad for routine feature: $featureType');

    return await showRewardedAdForPremiumFeature(
      featureType: featureType,
      onRewardEarned: onRewardEarned,
      onAdFailedToShow: onAdFailedToShow,
    );
  }

  /// Dispose all ads
  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    _appOpenAd?.dispose();
    _rewardedAd?.dispose();
    _mediationService.dispose();
    super.dispose();
  }
}
