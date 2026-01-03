import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:applovin_max/applovin_max.dart';
import 'dart:async';
import '../core/config/ads_config.dart';

/// Ad Mediation Service with Fallback Logic
/// Handles loading ads from multiple networks with priority and fallback
class MediationService {
  static final MediationService _instance = MediationService._internal();
  factory MediationService() => _instance;
  MediationService._internal();

  // Ad state tracking
  bool _isInitialized = false;
  bool _isLoadingAd = false;
  String _currentNetwork = 'none';

  // Ad instances for different networks
  InterstitialAd? _admobInterstitial;
  RewardedAd? _admobRewarded;
  BannerAd? _admobBanner;

  /// Initialize mediation service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 MediationService: Initializing...');

      // Initialize Firebase Remote Config
      await AdsConfig.initializeRemoteConfig();

      // Initialize AppLovin MAX SDK with dynamic SDK key from Firebase
      await _initializeAppLovinMAX();

      _isInitialized = true;
      debugPrint('✅ MediationService: Initialized successfully');
    } catch (e) {
      debugPrint('❌ MediationService: Error initializing: $e');
    }
  }

  /// Initialize AppLovin MAX SDK with Firebase SDK key
  Future<void> _initializeAppLovinMAX() async {
    try {
      final sdkKey = AdsConfig.appLovinSdkKey;

      if (sdkKey.isEmpty) {
        debugPrint(
            '⚠️ MediationService: AppLovin SDK key not configured in Firebase - skipping AppLovin initialization');
        return;
      }

      debugPrint(
          '🔄 MediationService: Initializing AppLovin MAX with SDK key from Firebase...');

      // Initialize AppLovin MAX SDK
      await AppLovinMAX.initialize(sdkKey);

      debugPrint(
          '✅ MediationService: AppLovin MAX initialized with Firebase SDK key');
    } catch (e) {
      debugPrint('❌ MediationService: Error initializing AppLovin MAX: $e');
    }
  }

  /// Load ad with mediation and fallback
  Future<Ad?> loadAdWithMediation({
    required String adType, // 'banner', 'interstitial', 'rewarded'
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
    AdSize? adSize,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ MediationService: Not initialized');
      return null;
    }

    if (_isLoadingAd) {
      debugPrint('⚠️ MediationService: Already loading ad');
      return null;
    }

    _isLoadingAd = true;
    final priorityList = AdsConfig.getAdNetworkPriority();

    debugPrint(
        '🔄 MediationService: Loading $adType ad with priority: $priorityList');

    // Try each network in priority order
    for (String network in priorityList) {
      try {
        final ad = await _loadAdFromNetwork(
          network: network,
          adType: adType,
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
          adSize: adSize,
        );

        if (ad != null) {
          _currentNetwork = network;
          debugPrint(
              '✅ MediationService: Successfully loaded $adType ad from $network');
          _isLoadingAd = false;
          return ad;
        }
      } catch (e) {
        debugPrint('❌ MediationService: Failed to load from $network: $e');
        continue;
      }
    }

    debugPrint('❌ MediationService: All networks failed for $adType ad');
    _isLoadingAd = false;
    return null;
  }

  /// Load ad from specific network
  Future<Ad?> _loadAdFromNetwork({
    required String network,
    required String adType,
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
    AdSize? adSize,
  }) async {
    switch (network.toLowerCase()) {
      case 'admob':
        return await _loadAdMobAd(
          adType: adType,
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
          adSize: adSize,
        );

      case 'applovin':
        return await _loadAppLovinAd(
          adType: adType,
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
          adSize: adSize,
        );

      default:
        debugPrint('⚠️ MediationService: Unknown network: $network');
        return null;
    }
  }

  /// Load AdMob ad
  Future<Ad?> _loadAdMobAd({
    required String adType,
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
    AdSize? adSize,
  }) async {
    try {
      String adUnitId;

      switch (adType) {
        case 'banner':
          adUnitId = AdsConfig.bannerAdUnitId;
          final bannerAd = BannerAd(
            adUnitId: adUnitId,
            size: adSize ?? AdSize.banner,
            request: const AdRequest(),
            listener: BannerAdListener(
              onAdLoaded: onAdLoaded,
              onAdFailedToLoad: onAdFailedToLoad,
            ),
          );
          await bannerAd.load();
          return bannerAd;

        case 'interstitial':
          adUnitId = AdsConfig.interstitialAdUnitId;
          await InterstitialAd.load(
            adUnitId: adUnitId,
            request: const AdRequest(),
            adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: (ad) {
                _admobInterstitial = ad;
                onAdLoaded(ad);
              },
              onAdFailedToLoad: (error) {
                onAdFailedToLoad(_admobInterstitial!, error);
              },
            ),
          );
          return _admobInterstitial;

        case 'rewarded':
          adUnitId = AdsConfig.rewardedAdUnitId;
          await RewardedAd.load(
            adUnitId: adUnitId,
            request: const AdRequest(),
            rewardedAdLoadCallback: RewardedAdLoadCallback(
              onAdLoaded: (ad) {
                _admobRewarded = ad;
                onAdLoaded(ad);
              },
              onAdFailedToLoad: (error) {
                onAdFailedToLoad(_admobRewarded!, error);
              },
            ),
          );
          return _admobRewarded;

        default:
          debugPrint('⚠️ MediationService: Unknown ad type: $adType');
          return null;
      }
    } catch (e) {
      debugPrint('❌ MediationService: Error loading AdMob $adType ad: $e');
      return null;
    }
  }

  /// Load AppLovin ad using Firebase-configured IDs
  Future<Ad?> _loadAppLovinAd({
    required String adType,
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
    AdSize? adSize,
  }) async {
    try {
      // Check if AppLovin SDK key is configured in Firebase
      if (AdsConfig.appLovinSdkKey.isEmpty) {
        debugPrint(
            '❌ MediationService: AppLovin SDK key not configured in Firebase');
        return null;
      }

      debugPrint(
          '🔄 MediationService: AppLovin SDK key configured - loading $adType ad...');

      // Get AppLovin ad unit IDs from Firebase Remote Config
      String adUnitId;

      switch (adType) {
        case 'banner':
          adUnitId = AdsConfig.appLovinBannerAdUnitId;
          if (adUnitId.isEmpty) {
            debugPrint(
                '❌ MediationService: AppLovin banner ID not configured in Firebase');
            return null;
          }
          debugPrint(
              '🔄 MediationService: Loading AppLovin banner with ID: $adUnitId');

          // Use AppLovin MAX SDK methods here
          AppLovinMAX.loadBanner(adUnitId); // Note: void method
          // For now, return null to test fallback
          return null;

        case 'interstitial':
          adUnitId = AdsConfig.appLovinInterstitialAdUnitId;
          if (adUnitId.isEmpty) {
            debugPrint(
                '❌ MediationService: AppLovin interstitial ID not configured in Firebase');
            return null;
          }
          debugPrint(
              '🔄 MediationService: Loading AppLovin interstitial with ID: $adUnitId');

          // Use AppLovin MAX SDK methods here
          AppLovinMAX.loadInterstitial(adUnitId); // Note: void method
          // For now, return null to test fallback
          return null;

        case 'rewarded':
          adUnitId = AdsConfig.appLovinRewardedAdUnitId;
          if (adUnitId.isEmpty) {
            debugPrint(
                '❌ MediationService: AppLovin rewarded ID not configured in Firebase');
            return null;
          }
          debugPrint(
              '🔄 MediationService: Loading AppLovin rewarded with ID: $adUnitId');

          // Use AppLovin MAX SDK methods here
          AppLovinMAX.loadRewardedAd(adUnitId); // Note: void method
          // For now, return null to test fallback
          return null;

        default:
          debugPrint('⚠️ MediationService: Unknown AppLovin ad type: $adType');
          return null;
      }
    } catch (e) {
      debugPrint('❌ MediationService: Error loading AppLovin $adType ad: $e');
      return null;
    }
  }

  /// Show interstitial ad with mediation
  Future<bool> showInterstitialAd() async {
    if (_admobInterstitial == null) {
      debugPrint('⚠️ MediationService: No interstitial ad available');
      return false;
    }

    try {
      await _admobInterstitial!.show();
      debugPrint(
          '✅ MediationService: Interstitial ad shown from $_currentNetwork');
      return true;
    } catch (e) {
      debugPrint('❌ MediationService: Error showing interstitial ad: $e');
      return false;
    }
  }

  /// Show rewarded ad with mediation
  Future<bool> showRewardedAd({
    required Function() onRewardEarned,
    Function()? onAdFailedToShow,
  }) async {
    if (_admobRewarded == null) {
      debugPrint('⚠️ MediationService: No rewarded ad available');
      onAdFailedToShow?.call();
      return false;
    }

    try {
      await _admobRewarded!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint(
              '🎁 MediationService: User earned reward from $_currentNetwork');
          onRewardEarned();
        },
      );
      debugPrint('✅ MediationService: Rewarded ad shown from $_currentNetwork');
      return true;
    } catch (e) {
      debugPrint('❌ MediationService: Error showing rewarded ad: $e');
      onAdFailedToShow?.call();
      return false;
    }
  }

  /// Get current network
  String get currentNetwork => _currentNetwork;

  /// Check if mediation is enabled
  bool get isMediationEnabled => AdsConfig.isMediationEnabled;

  /// Dispose all ads
  void dispose() {
    _admobInterstitial?.dispose();
    _admobRewarded?.dispose();
    _admobBanner?.dispose();
    debugPrint('🧹 MediationService: Disposed all ads');
  }
}
