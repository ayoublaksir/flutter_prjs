import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import '../core/config/ads_config.dart';

class RewardedAdService extends ChangeNotifier {
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  // Ad instance
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  int _retryCount = 0;
  static const int maxRetries = 3;

  // Fallback ad unit tracking
  int _currentAdUnitIndex = 0;
  bool _hasTriedAllAdUnits = false;

  // Daily usage tracking for BeautyGlow
  int _todayProducts = 0;
  int _todayRoutines = 0;
  int _todayTips = 0;

  // Rewarded ad unlock tracking
  int _unlockedProducts = 0;
  int _unlockedRoutines = 0;
  int _unlockedTips = 0;

  DateTime? _lastResetDate;

  // Getters
  bool get isRewardedAdReady => _isRewardedAdReady;

  // Firebase-controlled limits plus unlocked items
  int get totalProductLimit => AdsConfig.dailyProductLimit + _unlockedProducts;
  int get totalRoutineLimit => AdsConfig.dailyRoutineLimit + _unlockedRoutines;
  int get totalTipLimit => AdsConfig.dailyTipLimit + _unlockedTips;

  int get remainingProducts => totalProductLimit - _todayProducts;
  int get remainingRoutines => totalRoutineLimit - _todayRoutines;
  int get remainingTips => totalTipLimit - _todayTips;

  /// Get debug information about the service state
  Map<String, dynamic> get debugInfo {
    return {
      'isRewardedAdReady': _isRewardedAdReady,
      'hasRewardedAd': _rewardedAd != null,
      'adUnitId': AdsConfig.rewardedAdUnitId,
      'useTestAds': AdsConfig.getBoolValue('enable_test_ads'),
      'dailyProductLimit': AdsConfig.dailyProductLimit,
      'dailyRoutineLimit': AdsConfig.dailyRoutineLimit,
      'dailyTipLimit': AdsConfig.dailyTipLimit,
      'totalProductLimit': totalProductLimit,
      'totalRoutineLimit': totalRoutineLimit,
      'totalTipLimit': totalTipLimit,
      'todayProducts': _todayProducts,
      'todayRoutines': _todayRoutines,
      'todayTips': _todayTips,
      'unlockedProducts': _unlockedProducts,
      'unlockedRoutines': _unlockedRoutines,
      'unlockedTips': _unlockedTips,
    };
  }

  bool get canCreateProduct => _todayProducts < totalProductLimit;
  bool get canCreateRoutine => _todayRoutines < totalRoutineLimit;
  bool get canViewTip => _todayTips < totalTipLimit;

  /// Initialize service
  void init() {
    debugPrint('📱 RewardedAdService: Initialized for BeautyGlow');
    debugPrint(
        '📱 RewardedAdService: Using test ads: ${AdsConfig.getBoolValue('enable_test_ads')}');
    debugPrint(
        '📱 RewardedAdService: Rewarded ad unit ID: ${AdsConfig.rewardedAdUnitId}');
    _checkAndResetDailyLimits();

    // Add a longer delay to ensure MobileAds is fully initialized
    Future.delayed(const Duration(milliseconds: 3000), () {
      loadRewardedAd();
    });
  }

  /// Check if daily limits need to be reset
  void _checkAndResetDailyLimits() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      _todayProducts = 0;
      _todayRoutines = 0;
      _todayTips = 0;

      // Reset unlocked counts daily
      _unlockedProducts = 0;
      _unlockedRoutines = 0;
      _unlockedTips = 0;

      _lastResetDate = today;
      debugPrint(
          '📱 RewardedAdService: Daily limits and unlocked counts reset');
      notifyListeners();
    }
  }

  // ==========================================================================
  // REWARDED AD UNLOCK METHODS
  // ==========================================================================

  /// Unlock additional routines by watching rewarded ad
  void unlockRoutines() {
    final unlockCount = AdsConfig.rewardedUnlockCount;
    _unlockedRoutines += unlockCount;
    debugPrint(
        '🎁 RewardedAdService: Unlocked $unlockCount additional routines (total unlocked: $_unlockedRoutines)');
    notifyListeners();
  }

  /// Unlock additional products by watching rewarded ad
  void unlockProducts() {
    final unlockCount = AdsConfig.rewardedUnlockCount;
    _unlockedProducts += unlockCount;
    debugPrint(
        '🎁 RewardedAdService: Unlocked $unlockCount additional products (total unlocked: $_unlockedProducts)');
    notifyListeners();
  }

  /// Unlock additional tips by watching rewarded ad
  void unlockTips() {
    final unlockCount = AdsConfig.rewardedUnlockCount;
    _unlockedTips += unlockCount;
    debugPrint(
        '🎁 RewardedAdService: Unlocked $unlockCount additional tips (total unlocked: $_unlockedTips)');
    notifyListeners();
  }

  // ==========================================================================
  // USAGE TRACKING METHODS
  // ==========================================================================

  /// Track routine creation (call when user creates a routine)
  void trackRoutineCreation() {
    _todayRoutines++;
    debugPrint(
        '📊 RewardedAdService: Routine created. Used: $_todayRoutines/$totalRoutineLimit');
    notifyListeners();
  }

  /// Track product creation (call when user creates a product)
  void trackProductCreation() {
    _todayProducts++;
    debugPrint(
        '📊 RewardedAdService: Product created. Used: $_todayProducts/$totalProductLimit');
    notifyListeners();
  }

  /// Track tip viewing (call when user views a tip)
  void trackTipViewing() {
    _todayTips++;
    debugPrint(
        '📊 RewardedAdService: Tip viewed. Used: $_todayTips/$totalTipLimit');
    notifyListeners();
  }

  /// Enhanced rewarded ad loading with fallback ad units and server-side error handling
  Future<void> loadRewardedAd() async {
    if (_isRewardedAdReady) return;

    debugPrint(
        '🔵 RewardedAdService: Loading rewarded ad (attempt ${_retryCount + 1}/$maxRetries)');

    try {
      // Get current ad unit ID (with fallback)
      final adUnitId = _getCurrentAdUnitId();
      debugPrint(
          '🎯 RewardedAdService: Loading rewarded ad with unit ID: $adUnitId');
      debugPrint(
          '🎯 RewardedAdService: Using test ads: ${AdsConfig.getBoolValue('enable_test_ads')}');
      debugPrint('🎯 RewardedAdService: Ad unit index: $_currentAdUnitIndex');

      // Ensure MobileAds is initialized
      await MobileAds.instance.initialize();

      // Configure test device properly
      if (AdsConfig.getBoolValue('enable_test_ads')) {
        debugPrint(
            '🎯 RewardedAdService: Current test device IDs: ${AdsConfig.testDeviceIds}');

        // Use the configured test device IDs
        if (AdsConfig.testDeviceIds.isNotEmpty) {
          debugPrint('🎯 RewardedAdService: Using configured test device IDs');

          // Update request configuration with test device IDs
          await MobileAds.instance.updateRequestConfiguration(
            RequestConfiguration(
              testDeviceIds: AdsConfig.testDeviceIds,
              tagForChildDirectedTreatment:
                  TagForChildDirectedTreatment.unspecified,
              tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
              maxAdContentRating: MaxAdContentRating.g,
            ),
          );
          debugPrint(
              '✅ RewardedAdService: Test devices configured: ${AdsConfig.testDeviceIds}');
        } else {
          debugPrint(
              '⚠️ RewardedAdService: No test device IDs configured, using default test ads');
        }
      }

      // Add timeout for ad loading
      final adLoadFuture = RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            _retryCount = 0; // Reset retry count on success
            _hasTriedAllAdUnits = false; // Reset fallback tracking
            debugPrint('✅ RewardedAdService: Rewarded ad loaded successfully');

            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint(
                    '📱 RewardedAdService: Rewarded ad showed full screen');
              },
              onAdDismissedFullScreenContent: (ad) {
                _isRewardedAdReady = false;
                ad.dispose();
                _scheduleReload(); // Use smart reload scheduling
                debugPrint('📱 RewardedAdService: Rewarded ad dismissed');
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _isRewardedAdReady = false;
                ad.dispose();
                debugPrint(
                    '❌ RewardedAdService: Rewarded ad failed to show: $error');
                _handleShowError(error);
              },
            );
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            _isRewardedAdReady = false;
            _retryCount++;

            debugPrint(
                '❌ RewardedAdService: Rewarded ad failed to load: $error');
            debugPrint('❌ RewardedAdService: Error code: ${error.code}');
            debugPrint('❌ RewardedAdService: Error message: ${error.message}');
            debugPrint('❌ RewardedAdService: Error domain: ${error.domain}');

            // Enhanced error handling for server-side errors
            if (AdsConfig.getBoolValue('enable_test_ads') && error.code == 0) {
              debugPrint(
                  '🔧 RewardedAdService: Test ad internal error detected');
              debugPrint(
                  '🔧 RewardedAdService: This is a server-side AdMob error');

              // Try fallback ad units for server-side errors
              _tryFallbackAdUnit();
            }

            _handleLoadError(error);
          },
        ),
      );

      // Add timeout
      await adLoadFuture.timeout(
        const Duration(seconds: 30), // Use default timeout
        onTimeout: () {
          debugPrint('⏰ RewardedAdService: Ad load timeout');
          throw TimeoutException(
              'Ad load timeout', const Duration(seconds: 30));
        },
      );
    } catch (e) {
      _isRewardedAdReady = false;
      _retryCount++;
      debugPrint('❌ RewardedAdService: Error loading rewarded ad: $e');

      // Try fallback ad unit on timeout
      if (e is TimeoutException) {
        _tryFallbackAdUnit();
      }

      _handleLoadError(null);
    }
  }

  /// Get current ad unit ID with fallback support
  String _getCurrentAdUnitId() {
    // Use Firebase-configured rewarded ad unit ID
    // For our new Firebase approach, we use one main ad unit ID
    return AdsConfig.rewardedAdUnitId;
  }

  /// Try next fallback ad unit
  void _tryFallbackAdUnit() {
    if (!AdsConfig.getBoolValue('enable_test_ads') || _hasTriedAllAdUnits) {
      debugPrint('⚠️ RewardedAdService: No more fallback ad units available');
      return;
    }

    _currentAdUnitIndex++;
    if (_currentAdUnitIndex >= 3) {
      // Limit retry attempts
      _hasTriedAllAdUnits = true;
      debugPrint('⚠️ RewardedAdService: Tried all fallback ad units');
    } else {
      debugPrint(
          '🔄 RewardedAdService: Trying fallback ad unit ${_currentAdUnitIndex + 1}');

      // Retry with new ad unit after short delay
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isRewardedAdReady) {
          loadRewardedAd();
        }
      });
    }
  }

  /// Fix test device configuration
  Future<void> _fixTestDeviceConfiguration() async {
    try {
      debugPrint('🔧 RewardedAdService: Fixing test device configuration...');

      // Use the configured test device IDs from AdsConfig
      if (AdsConfig.testDeviceIds.isNotEmpty) {
        debugPrint(
            '🔧 RewardedAdService: Reconfiguring with test device IDs: ${AdsConfig.testDeviceIds}');

        // Update configuration with test device IDs
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: AdsConfig.testDeviceIds,
            tagForChildDirectedTreatment:
                TagForChildDirectedTreatment.unspecified,
            tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
            maxAdContentRating: MaxAdContentRating.g,
          ),
        );

        debugPrint('✅ RewardedAdService: Test device configuration updated');
      } else {
        debugPrint('⚠️ RewardedAdService: No test device IDs configured');
      }
    } catch (e) {
      debugPrint(
          '❌ RewardedAdService: Failed to fix test device configuration: $e');
    }
  }

  /// Show rewarded ad with callback for reward
  Future<void> showRewardedAd({
    required Function() onRewardEarned,
    Function()? onAdFailedToShow,
    Function()? onAdClosed,
  }) async {
    debugPrint('🎯 RewardedAdService: Attempting to show rewarded ad');
    debugPrint('🎯 RewardedAdService: Ad ready: $_isRewardedAdReady');
    debugPrint('🎯 RewardedAdService: Ad instance: ${_rewardedAd != null}');

    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint(
          '⚠️ RewardedAdService: Rewarded ad not ready, attempting to reload');
      // Try to reload the ad first
      await loadRewardedAd();

      // Wait a bit and check again
      await Future.delayed(const Duration(seconds: 3));

      if (!_isRewardedAdReady || _rewardedAd == null) {
        debugPrint(
            '❌ RewardedAdService: Rewarded ad still not ready after reload');
        onAdFailedToShow?.call();
        return;
      }
    }

    try {
      debugPrint('🎯 RewardedAdService: Showing rewarded ad');
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint(
              '🎁 RewardedAdService: User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned.call();
        },
      );
    } catch (e) {
      debugPrint('❌ RewardedAdService: Error showing rewarded ad: $e');
      _isRewardedAdReady = false;
      loadRewardedAd(); // Reload for next time
      onAdFailedToShow?.call();
    }
  }

  /// Show rewarded ad to unlock specific features
  Future<void> showRewardedAdForFeature({
    required String featureType,
    required Function() onRewardEarned,
    Function()? onAdFailedToShow,
    Function()? onAdClosed,
  }) async {
    debugPrint(
        '🎯 RewardedAdService: showRewardedAdForFeature called for: $featureType');
    printDebugInfo();

    await showRewardedAd(
      onRewardEarned: () {
        debugPrint(
            '🎁 RewardedAdService: Reward earned for feature: $featureType');
        // Grant the specific reward based on feature type
        switch (featureType) {
          case 'unlock_products':
            unlockProducts(); // Grant additional products from Firebase config
            break;
          case 'unlock_routines':
            unlockRoutines(); // Grant additional routines from Firebase config
            break;
          case 'unlock_tips':
            unlockTips(); // Grant additional tips from Firebase config
            break;
        }
        onRewardEarned.call();
      },
      onAdFailedToShow: () {
        debugPrint(
            '❌ RewardedAdService: Ad failed to show for feature: $featureType');
        onAdFailedToShow?.call();
      },
      onAdClosed: onAdClosed,
    );
  }

  /// Force reload rewarded ad (useful when ads fail to load)
  Future<void> forceReloadRewardedAd() async {
    debugPrint('🔄 RewardedAdService: Force reloading rewarded ad');
    _retryCount = 0; // Reset retry count
    _isRewardedAdReady = false;
    _currentAdUnitIndex = 0; // Reset fallback tracking
    _hasTriedAllAdUnits = false; // Reset fallback tracking
    _rewardedAd?.dispose();
    _rewardedAd = null;
    notifyListeners();

    // Wait a bit before reloading
    await Future.delayed(const Duration(seconds: 2));

    // Re-initialize MobileAds if needed
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('⚠️ RewardedAdService: MobileAds already initialized');
    }

    await loadRewardedAd();
  }

  /// Print debug information about the service state
  void printDebugInfo() {
    debugPrint('🔍 RewardedAdService Debug Info:');
    debugPrint('  - isRewardedAdReady: $_isRewardedAdReady');
    debugPrint('  - hasRewardedAd: ${_rewardedAd != null}');
    debugPrint('  - retryCount: $_retryCount');
    debugPrint('  - maxRetries: $maxRetries');
    debugPrint('  - currentAdUnitIndex: $_currentAdUnitIndex');
    debugPrint('  - hasTriedAllAdUnits: $_hasTriedAllAdUnits');
    debugPrint('  - currentAdUnitId: ${_getCurrentAdUnitId()}');
    debugPrint('  - useTestAds: ${AdsConfig.getBoolValue('enable_test_ads')}');
    debugPrint('  - dailyProductLimit: ${AdsConfig.dailyProductLimit}');
    debugPrint('  - dailyRoutineLimit: ${AdsConfig.dailyRoutineLimit}');
    debugPrint('  - dailyTipLimit: ${AdsConfig.dailyTipLimit}');
    debugPrint('  - todayProducts: $_todayProducts');
    debugPrint('  - todayRoutines: $_todayRoutines');
    debugPrint('  - todayTips: $_todayTips');
  }

  /// Get current status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isReady': _isRewardedAdReady,
      'retryCount': _retryCount,
      'maxRetries': maxRetries,
      'hasAd': _rewardedAd != null,
      'useTestAds': AdsConfig.getBoolValue('enable_test_ads'),
    };
  }

  /// Check if the service is properly initialized
  bool get isInitialized {
    return _lastResetDate != null;
  }

  /// Get a user-friendly message about ad availability
  String get adAvailabilityMessage {
    if (AdsConfig.getBoolValue('enable_test_ads')) {
      return 'Test ads are enabled. Please ensure you have a stable internet connection for test ads to load.';
    }
    return 'Production ads are enabled. Please ensure you have a stable internet connection.';
  }

  /// Check if test ads are properly configured
  Future<bool> isTestAdsConfigured() async {
    if (!AdsConfig.getBoolValue('enable_test_ads')) return true;

    try {
      final requestConfig = await MobileAds.instance.getRequestConfiguration();
      return requestConfig.testDeviceIds != null &&
          requestConfig.testDeviceIds!.isNotEmpty;
    } catch (e) {
      debugPrint(
          '❌ RewardedAdService: Error checking test ads configuration: $e');
      return false;
    }
  }

  /// Smart rewarded ad placement logic
  bool shouldShowRewardedAd(String context) {
    if (!_isRewardedAdReady) return false;

    _checkAndResetDailyLimits();

    switch (context) {
      case 'unlock_products':
        return !canCreateProduct; // Show when product limit reached
      case 'unlock_routines':
        return !canCreateRoutine; // Show when routine limit reached
      case 'unlock_tips':
        return !canViewTip; // Show when tip limit reached
      case 'low_products_warning':
        return remainingProducts <= 1 &&
            remainingProducts > 0; // Show warning when close to limit
      case 'low_routines_warning':
        return remainingRoutines <= 1 &&
            remainingRoutines > 0; // Show warning when close to limit
      case 'low_tips_warning':
        return remainingTips <= 2 &&
            remainingTips > 0; // Show warning when close to limit
      default:
        return false;
    }
  }

  /// Get feature-specific message
  String getFeatureMessage(String featureType) {
    switch (featureType) {
      case 'unlock_products':
        return 'Watch a short ad to unlock 3 more product slots!';
      case 'unlock_routines':
        return 'Watch a short ad to unlock 3 more routine slots!';
      case 'unlock_tips':
        return 'Watch a short ad to unlock 5 more beauty tips!';
      default:
        return 'Watch a short ad to unlock more features!';
    }
  }

  /// Get reward description
  String getRewardDescription(String featureType) {
    switch (featureType) {
      case 'unlock_products':
        return 'Unlock 3 more product slots';
      case 'unlock_routines':
        return 'Unlock 3 more routine slots';
      case 'unlock_tips':
        return 'Unlock 5 more beauty tips';
      default:
        return 'Unlock additional features';
    }
  }

  /// Smart error handling for load failures
  void _handleLoadError(LoadAdError? error) {
    notifyListeners();

    if (_retryCount < maxRetries) {
      // Exponential backoff: 2, 4, 8 minutes
      final delayMinutes = 2 * _retryCount;
      debugPrint(
          '🔄 RewardedAdService: Retrying in $delayMinutes minutes (attempt ${_retryCount + 1}/$maxRetries)');

      Future.delayed(Duration(minutes: delayMinutes), () {
        if (!_isRewardedAdReady) {
          loadRewardedAd();
        }
      });
    } else {
      debugPrint(
          '⚠️ RewardedAdService: Max retries reached, stopping attempts');
      _retryCount = 0; // Reset for next manual load
    }
  }

  /// Handle show errors (like MediaCodec issues)
  void _handleShowError(AdError error) {
    debugPrint('🎬 RewardedAdService: Handling show error - ${error.message}');

    // For MediaCodec errors, try to reload with different configuration
    if (error.message.contains('MediaCodec') ||
        error.message.contains('decoder') ||
        error.message.contains('video')) {
      debugPrint(
          '🎬 RewardedAdService: Detected video codec error, will reload');
      _scheduleReload();
    }
  }

  /// Smart reload scheduling
  void _scheduleReload() {
    // Wait a bit longer for video codec errors
    final delayMinutes = _retryCount > 0 ? 5 : 2;
    debugPrint(
        '🔄 RewardedAdService: Scheduling reload in $delayMinutes minutes');

    Future.delayed(Duration(minutes: delayMinutes), () {
      if (!_isRewardedAdReady) {
        loadRewardedAd();
      }
    });
  }
}
