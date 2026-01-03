import 'package:flutter_test/flutter_test.dart';
import 'package:beautyglow/core/config/ads_config.dart';
import 'package:beautyglow/services/ad_service.dart';

void main() {
  group('Ads Configuration Tests', () {
    test('should return correct app ID', () {
      expect(AdsConfig.appId, isA<String>());
      expect(AdsConfig.appId.isNotEmpty, isTrue);
    });

    test('should return banner ad unit ID', () {
      expect(AdsConfig.bannerAdUnitId, isA<String>());
      expect(AdsConfig.bannerAdUnitId.isNotEmpty, isTrue);
    });

    test('should return rewarded ad unit ID', () {
      expect(AdsConfig.rewardedAdUnitId, isA<String>());
      expect(AdsConfig.rewardedAdUnitId.isNotEmpty, isTrue);
    });

    test('should return interstitial ad unit ID', () {
      expect(AdsConfig.interstitialAdUnitId, isA<String>());
      expect(AdsConfig.interstitialAdUnitId.isNotEmpty, isTrue);
    });

    test('should return smart banner ad unit ID', () {
      expect(AdsConfig.smartBannerAdUnitId, isA<String>());
      expect(AdsConfig.smartBannerAdUnitId.isNotEmpty, isTrue);
    });

    test('should use test ads in debug mode', () {
      // This test assumes we're running in debug mode
      expect(AdsConfig.useTestAds, isTrue);
    });
  });

  group('AdService Tests', () {
    test('should create singleton instance', () {
      final adService1 = AdService();
      final adService2 = AdService();
      expect(identical(adService1, adService2), isTrue);
    });

    test('should initialize ad service', () {
      final adService = AdService();
      expect(() => adService.init(), returnsNormally);
    });

    test('should have correct initial states', () {
      final adService = AdService();
      expect(adService.isInterstitialAdReady, isFalse);
      expect(adService.isBannerAdReady, isFalse);
      expect(adService.isNativeAdReady, isFalse);
      expect(adService.isRewardedAdReady, isFalse);
    });

    test('should dispose ads correctly', () {
      final adService = AdService();
      expect(() => adService.dispose(), returnsNormally);
    });
  });
}
