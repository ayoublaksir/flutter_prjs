import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Centralizes all ad unit IDs and ad settings with Firebase Remote Config
///
/// PRODUCTION UPDATE STRATEGY:
/// - Initial fetch on app startup
/// - Smart refresh every 30 minutes (respects 12-hour minimum interval)
/// - Automatic refresh when app resumes from background
/// - Emergency force update capability
///
/// GOOGLE PLAY COMPLIANCE:
/// - AdMob App IDs remain hardcoded for compliance
/// - AppLovin SDK Key fetched from Firebase Remote Config
/// - All ad unit IDs fetched dynamically from Firebase
class AdsConfig {
  // Private constructor
  AdsConfig._();

  // Firebase Remote Config instance
  static FirebaseRemoteConfig? _remoteConfig;
  static bool _isRemoteConfigInitialized = false;

  /// Ad placement settings
  static const bool showBannerOnHome = true;
  static const bool showBannerOnRecipeDetail = true;
  static const bool showRewardedForPremiumFeatures = true;

  /// Test device IDs for development
  static const List<String> testDeviceIds = [
    'YOUR_TEST_DEVICE_ID_HERE', // Replace with your device ID
  ];

  // ==========================================================================
  // HARDCODED APP IDs (GOOGLE PLAY COMPLIANCE)
  // ==========================================================================

  /// AdMob App ID (hardcoded for Google Play compliance)
  static String get admobAppId => Platform.isAndroid
      ? getString('admob_app_id_android')
      : getString('admob_app_id_ios');

  // ==========================================================================
  // FIREBASE REMOTE CONFIG SETUP
  // ==========================================================================

  /// Initialize Firebase Remote Config
  static Future<void> initializeRemoteConfig() async {
    if (_isRemoteConfigInitialized) return;

    try {
      debugPrint('🔥 AdsConfig: Initializing Firebase Remote Config...');

      _remoteConfig = FirebaseRemoteConfig.instance;

      // PRODUCTION FETCH: Set proper intervals for production vs development
      final fetchInterval = kDebugMode
          ? Duration.zero // DEV: 0 seconds for instant testing
          : const Duration(hours: 12); // PROD: 12 hours for production

      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: fetchInterval,
      ));
      debugPrint(
          '🔥 AdsConfig: ${kDebugMode ? "DEV" : "PROD"} MODE - ${kDebugMode ? "0 second" : "12 hour"} fetch interval');

      // Set comprehensive ad defaults with TEST AD UNIT IDs
      await _remoteConfig!.setDefaults({
        // === AD UNIT IDs (FIREBASE CONTROLLED) ===
        'admob_app_id_android': '', // FIREBASE CONTROLLED
        'admob_app_id_ios': '', // FIREBASE CONTROLLED
        'admob_banner_id': '', // FIREBASE CONTROLLED
        'admob_interstitial_id': '', // FIREBASE CONTROLLED
        'admob_rewarded_id': '', // FIREBASE CONTROLLED
        'admob_app_open_id': '', // FIREBASE CONTROLLED
        'admob_native_id': '', // FIREBASE CONTROLLED
        'applovin_banner_id': '', // Test AppLovin Banner
        'applovin_interstitial_id': '', // Test AppLovin Interstitial
        'applovin_rewarded_id': '', // Test AppLovin Rewarded
        'applovin_native_id': '', // Test AppLovin Native

        // === APPLOVIN SDK CONFIGURATION ===
        'applovin_sdk_key': '', // AppLovin SDK Key from Firebase

        // === AD CONTROL & ENABLE/DISABLE ===
        'enable_ads': 'true',
        'enable_banner_ads': 'true',
        'enable_interstitial_ads': 'true',
        'enable_rewarded_ads': 'true',
        'enable_app_open_ads': 'true',
        'enable_native_ads': 'true',

        // === MEDIATION SETTINGS ===
        'enable_mediation': 'true',
        'ad_network_priority': 'admob,applovin',
        'mediation_fallback_delay': '2000',
        'max_mediation_attempts': '3',

        // === AD FREQUENCY & TIMING (NO HARDCODED - PURE FIREBASE CONTROL) ===
        'interstitial_frequency':
            '', // FIREBASE CONTROLLED: Show after X swipes
        'rewarded_frequency':
            '', // FIREBASE CONTROLLED: Show rewarded after X swipes
        'rewarded_saves_frequency':
            '', // FIREBASE CONTROLLED: Show rewarded after X saves
        'min_time_between_interstitials':
            kDebugMode ? '0' : '30000', // DEV: no cooldown, PROD: 30 seconds
        'banner_refresh_interval': '300000', // 5 minutes
        'app_open_cooldown': '240000', // 4 minutes
        'rewarded_ad_cooldown':
            kDebugMode ? '0' : '300000', // DEV: no cooldown, PROD: 5 minutes

        // === DAILY LIMITS (FIREBASE CONTROLLED) ===
        'daily_swipe_limit': '15', // FIREBASE CONTROLLED: Daily swipe limit
        'daily_save_limit': '5', // FIREBASE CONTROLLED: Daily save limit
        'daily_planning_limit':
            '3', // FIREBASE CONTROLLED: Daily planning limit

        // === AD PLACEMENT CONTROLS ===
        'show_banner_on_home': 'true',
        'show_banner_on_spots': 'true',
        'show_banner_on_details': 'true',
        'show_interstitial_on_swipe': 'true',
        'show_interstitial_on_navigation': 'false',
        'show_app_open_on_resume': 'true',

        // === DEBUG & ANALYTICS ===
        'enable_ad_debug_logs': 'true', // Enable for debugging
        'report_ad_errors': 'true',
      });

      // Fetch and activate config
      await _remoteConfig!.fetchAndActivate();

      if (kDebugMode) {
        // DEBUG MODE: Aggressive fetching for immediate testing
        await _forceRefreshConfig();

        // Set up periodic refresh every 5 seconds in debug mode for immediate updates
        Timer.periodic(const Duration(seconds: 5), (timer) async {
          try {
            await _forceRefreshConfig();
          } catch (e) {
            debugPrint('🔄 AdsConfig: Periodic refresh failed: $e');
          }
        });
      } else {
        // PRODUCTION MODE: Optimized strategy for real users
        await _setupProductionUpdateStrategy();
      }

      _isRemoteConfigInitialized = true;
      debugPrint(
          '✅ AdsConfig: Firebase Remote Config initialized successfully');

      // Show current config values in debug mode
      if (kDebugMode) {
        debugPrintAllConfigValues();
      }
    } catch (e) {
      debugPrint('❌ AdsConfig: Error initializing Firebase Remote Config: $e');
    }
  }

  /// Production update strategy - optimized for real users
  static Future<void> _setupProductionUpdateStrategy() async {
    try {
      debugPrint('🚀 AdsConfig: Setting up production update strategy...');

      // 1. Initial fetch on app start
      await _forceRefreshConfig();

      // 2. Set up smart periodic refresh (DEV: every 30 seconds, PROD: every 2 hours)
      final refreshInterval = kDebugMode
          ? const Duration(seconds: 30) // DEV: 30 seconds for instant testing
          : const Duration(hours: 2); // PROD: 2 hours for battery efficiency

      debugPrint(
          '🔄 AdsConfig: Setting up periodic refresh every ${refreshInterval.inSeconds} seconds');

      Timer.periodic(refreshInterval, (timer) async {
        try {
          await _smartRefreshConfig();
        } catch (e) {
          debugPrint('🔄 AdsConfig: Smart refresh failed: $e');
        }
      });

      debugPrint('✅ AdsConfig: Production update strategy activated');
    } catch (e) {
      debugPrint('❌ AdsConfig: Error setting up production strategy: $e');
    }
  }

  /// Smart refresh that respects minimum fetch interval
  static Future<void> _smartRefreshConfig() async {
    if (_remoteConfig == null) return;

    try {
      final lastFetchTime = _remoteConfig!.lastFetchTime;
      final now = DateTime.now();
      final timeSinceLastFetch = now.difference(lastFetchTime);

      final minRefreshHours =
          kDebugMode ? 0 : 12; // DEV: always refresh, PROD: 12 hours

      if (timeSinceLastFetch.inHours >= minRefreshHours || kDebugMode) {
        debugPrint(
            '🔄 AdsConfig: Smart refresh triggered (${timeSinceLastFetch.inSeconds}s since last fetch, ${kDebugMode ? "DEV MODE" : "PROD MODE"})');
        await _remoteConfig!.fetchAndActivate();
        debugPrint('✅ AdsConfig: Smart refresh completed - new values active');

        // Show updated config values in debug mode
        if (kDebugMode) {
          debugPrintAllConfigValues();
        }
      } else {
        debugPrint(
            '⏳ AdsConfig: Skipping refresh (only ${timeSinceLastFetch.inHours} hours since last fetch, need $minRefreshHours+)');
      }
    } catch (e) {
      debugPrint('❌ AdsConfig: Smart refresh error: $e');
    }
  }

  /// Handle app lifecycle changes (call from app resume)
  static Future<void> onAppResumed() async {
    try {
      debugPrint('📱 AdsConfig: App resumed, checking for config updates...');
      await _smartRefreshConfig();
    } catch (e) {
      debugPrint('❌ AdsConfig: Error on app resume refresh: $e');
    }
  }

  /// Force refresh Firebase Remote Config (for immediate updates in debug)
  static Future<void> _forceRefreshConfig() async {
    if (_remoteConfig == null) return;

    try {
      debugPrint('🔄 AdsConfig: Force refreshing Firebase Remote Config...');
      await _remoteConfig!.fetchAndActivate();
      debugPrint('✅ AdsConfig: Firebase Remote Config refreshed successfully');

      // DEBUG MODE: Print all config values for verification
      if (kDebugMode) {
        debugPrintAllConfigValues();
      }
    } catch (e) {
      debugPrint('❌ AdsConfig: Error force refreshing config: $e');
    }
  }

  /// Emergency force update (bypasses all intervals)
  static Future<void> forceImmediateUpdate() async {
    if (_remoteConfig == null) return;

    try {
      debugPrint('🚨 AdsConfig: Emergency force update initiated...');

      // Set fetch interval based on build mode
      final emergencyInterval = kDebugMode
          ? Duration.zero // DEV: Allow immediate fetch for testing
          : const Duration(
              minutes: 5); // PROD: Minimum 5 minutes between emergency updates

      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: emergencyInterval,
      ));

      // Force fetch and activate
      await _remoteConfig!.fetchAndActivate();

      debugPrint('✅ AdsConfig: Force immediate update completed');

      // Log updated values for verification
      if (kDebugMode) {
        debugPrint('🔍 Updated Firebase values:');
        debugPrint(
            '  - interstitial_frequency: ${getIntValue('interstitial_frequency')}');
        debugPrint(
            '  - rewarded_frequency: ${getIntValue('rewarded_frequency')}');
        debugPrint('  - enable_ads: ${getBoolValue('enable_ads')}');
      }
    } catch (e) {
      debugPrint('❌ AdsConfig: Force immediate update failed: $e');
    }
  }

  /// Development refresh method - instant updates for testing
  static Future<void> devRefreshNow() async {
    if (!kDebugMode) {
      debugPrint('⚠️ AdsConfig: devRefreshNow only works in debug mode');
      return;
    }

    await forceImmediateUpdate();
  }

  /// Public method to manually refresh Remote Config
  static Future<void> refreshConfig() async {
    await _forceRefreshConfig();
  }

  /// Debug method to print all current config values
  static void debugPrintAllConfigValues() {
    if (!kDebugMode) return;

    debugPrint('🔥 === FIREBASE REMOTE CONFIG VALUES ===');
    debugPrint(
        '📊 interstitial_frequency: ${getString('interstitial_frequency')} (parsed: ${interstitialFrequencyFromFirebase})');
    debugPrint(
        '🎁 rewarded_frequency: ${getString('rewarded_frequency')} (parsed: ${rewardedFrequencyFromFirebase})');
    debugPrint(
        '💾 rewarded_saves_frequency: ${getString('rewarded_saves_frequency')} (parsed: ${getIntValue('rewarded_saves_frequency')})');
    debugPrint(
        '📊 daily_swipe_limit: ${getString('daily_swipe_limit')} (parsed: ${getIntValue('daily_swipe_limit')})');
    debugPrint(
        '💾 daily_save_limit: ${getString('daily_save_limit')} (parsed: ${getIntValue('daily_save_limit')})');
    debugPrint(
        '📅 daily_planning_limit: ${getString('daily_planning_limit')} (parsed: ${getIntValue('daily_planning_limit')})');
    debugPrint('🎛️ enable_ads: ${getString('enable_ads')}');
    debugPrint(
        '🎬 enable_interstitial_ads: ${getString('enable_interstitial_ads')}');
    debugPrint('🎁 enable_rewarded_ads: ${getString('enable_rewarded_ads')}');
    debugPrint('📱 admob_banner_id: ${getString('admob_banner_id')}');
    debugPrint(
        '🎬 admob_interstitial_id: ${getString('admob_interstitial_id')}');
    debugPrint('🎁 admob_rewarded_id: ${getString('admob_rewarded_id')}');
    debugPrint('🔑 applovin_sdk_key: ${getString('applovin_sdk_key')}');
    debugPrint('🔥 ==========================================');
  }

  // ==========================================================================
  // FIREBASE PARAMETER GETTERS
  // ==========================================================================

  /// Get Firebase Remote Config value as string
  static String getString(String key) {
    if (_remoteConfig != null && _isRemoteConfigInitialized) {
      return _remoteConfig!.getString(key);
    }
    return '';
  }

  /// Get Firebase Remote Config value as bool
  static bool getBoolValue(String key) {
    final value = getString(key).toLowerCase();
    return value == 'true' || value == '1';
  }

  /// Get Firebase Remote Config value as int
  static int getIntValue(String key) {
    final value = getString(key);
    return int.tryParse(value) ?? 0;
  }

  /// Get Firebase Remote Config value as double
  static double getDoubleValue(String key) {
    final value = getString(key);
    return double.tryParse(value) ?? 0.0;
  }

  /// Get ad unit ID from Firebase Remote Config (returns empty if not configured)
  static String getAdUnitId(String key) {
    final value = getString(key);
    if (value.isEmpty || !_isRemoteConfigInitialized) {
      debugPrint('⚠️ AdsConfig: $key not configured in Firebase Remote Config');
      return '';
    }
    return value;
  }

  // ==========================================================================
  // DYNAMIC AD UNIT ID GETTERS
  // ==========================================================================

  /// AdMob ad unit IDs from Firebase
  static String get bannerAdUnitId => getAdUnitId('admob_banner_id');
  static String get interstitialAdUnitId =>
      getAdUnitId('admob_interstitial_id');
  static String get rewardedAdUnitId => getAdUnitId('admob_rewarded_id');
  static String get appOpenAdUnitId => getAdUnitId('admob_app_open_id');
  static String get nativeAdUnitId => getAdUnitId('admob_native_id');

  /// AppLovin ad unit IDs from Firebase
  static String get appLovinBannerAdUnitId => getAdUnitId('applovin_banner_id');
  static String get appLovinInterstitialAdUnitId =>
      getAdUnitId('applovin_interstitial_id');
  static String get appLovinRewardedAdUnitId =>
      getAdUnitId('applovin_rewarded_id');
  static String get appLovinNativeAdUnitId => getAdUnitId('applovin_native_id');

  /// AppLovin SDK Key from Firebase
  static String get appLovinSdkKey => getString('applovin_sdk_key');

  // ==========================================================================
  // AD CONTROL GETTERS
  // ==========================================================================

  /// Master ad enable/disable
  static bool get isAdsEnabled => getBoolValue('enable_ads');
  static bool get isBannerAdsEnabled => getBoolValue('enable_banner_ads');
  static bool get isInterstitialAdsEnabled =>
      getBoolValue('enable_interstitial_ads');
  static bool get isRewardedAdsEnabled => getBoolValue('enable_rewarded_ads');
  static bool get isAppOpenAdsEnabled => getBoolValue('enable_app_open_ads');
  static bool get isNativeAdsEnabled => getBoolValue('enable_native_ads');

  // ==========================================================================
  // MEDIATION GETTERS
  // ==========================================================================

  /// Mediation configuration
  static bool get isMediationEnabled => getBoolValue('enable_mediation');
  static int get mediationFallbackDelay =>
      getIntValue('mediation_fallback_delay');
  static int get maxMediationAttempts => getIntValue('max_mediation_attempts');

  /// Get ad network priority list
  static List<String> getAdNetworkPriority() {
    final priority = getString('ad_network_priority');
    if (priority.isNotEmpty) {
      return priority.split(',').map((e) => e.trim().toLowerCase()).toList();
    }
    return ['admob', 'applovin']; // Default priority
  }

  // ==========================================================================
  // AD FREQUENCY & TIMING GETTERS
  // ==========================================================================

  /// Get interstitial ad frequency from Firebase
  static int get interstitialFrequencyFromFirebase {
    final frequency = getIntValue('interstitial_frequency');
    // Ensure minimum of 1 to prevent division by zero
    final validFrequency =
        frequency > 0 ? frequency : 5; // Default to 5 if invalid
    debugPrint(
        '🔥 AdsConfig: Interstitial frequency from Firebase: $frequency → $validFrequency');
    return validFrequency;
  }

  static int get rewardedFrequencyFromFirebase =>
      getIntValue('rewarded_frequency');
  static int get minTimeBetweenInterstitials =>
      getIntValue('min_time_between_interstitials');
  static int get bannerRefreshInterval =>
      getIntValue('banner_refresh_interval');
  static int get appOpenCooldown => getIntValue('app_open_cooldown');
  static int get rewardedAdCooldown => getIntValue('rewarded_ad_cooldown');

  // ==========================================================================
  // AD PLACEMENT GETTERS
  // ==========================================================================

  /// Ad placement controls from Firebase
  static bool get showBannerOnSpots => getBoolValue('show_banner_on_spots');
  static bool get showBannerOnDetails => getBoolValue('show_banner_on_details');
  static bool get showInterstitialOnSwipe =>
      getBoolValue('show_interstitial_on_swipe');
  static bool get showInterstitialOnNavigation =>
      getBoolValue('show_interstitial_on_navigation');
  static bool get showAppOpenOnResume =>
      getBoolValue('show_app_open_on_resume');

  // ==========================================================================
  // AD DEBUGGING (ENABLED FOR DEBUG)
  // ==========================================================================

  /// Enable ad debugging (ENABLED FOR DEBUG)
  static const bool enableAdDebugging = true; // kDebugMode;

  /// Log ad events
  static void logAdEvent(String event, {Map<String, dynamic>? parameters}) {
    if (enableAdDebugging) {
      debugPrint('🔵 AdsConfig: $event ${parameters ?? ''}');
    }
  }
}

/// Ad performance tracking
class AdPerformanceTracker {
  static int _bannerImpressions = 0;
  static int _interstitialShown = 0;
  static int _rewardedViewed = 0;
  static int _adClicks = 0;

  // Getters
  static int get bannerImpressions => _bannerImpressions;
  static int get interstitialShown => _interstitialShown;
  static int get rewardedViewed => _rewardedViewed;
  static int get adClicks => _adClicks;

  // Track events
  static void trackBannerImpression() {
    _bannerImpressions++;
    AdsConfig.logAdEvent('Banner Impression',
        parameters: {'total': _bannerImpressions});
  }

  static void trackInterstitialShown() {
    _interstitialShown++;
    AdsConfig.logAdEvent('Interstitial Shown',
        parameters: {'total': _interstitialShown});
  }

  static void trackRewardedViewed() {
    _rewardedViewed++;
    AdsConfig.logAdEvent('Rewarded Viewed',
        parameters: {'total': _rewardedViewed});
  }

  static void trackAdClick() {
    _adClicks++;
    AdsConfig.logAdEvent('Ad Click', parameters: {'total': _adClicks});
  }

  /// Reset all counters
  static void resetCounters() {
    _bannerImpressions = 0;
    _interstitialShown = 0;
    _rewardedViewed = 0;
    _adClicks = 0;
    AdsConfig.logAdEvent('Performance Counters Reset');
  }
}
