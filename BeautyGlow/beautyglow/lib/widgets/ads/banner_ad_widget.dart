import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/ads_service.dart';
import '../../core/responsive/responsive_util.dart';
import '../../core/config/ads_config.dart';

/// Reusable banner ad widget with smart placement and optimization features
class BannerAdWidget extends StatefulWidget {
  final String? customAdUnitId;
  final EdgeInsets? margin;
  final bool useSmartPlacement;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailed;
  final bool enableAutoRefresh; // New feature for automatic refresh

  const BannerAdWidget({
    Key? key,
    this.customAdUnitId,
    this.margin,
    this.useSmartPlacement = false,
    this.onAdLoaded,
    this.onAdFailed,
    this.enableAutoRefresh = true, // Enable auto refresh by default
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;
  bool _isLoading = false;
  Timer? _autoRefreshTimer;
  DateTime? _adLoadTime;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  // Firebase-controlled refresh configuration
  Duration get _autoRefreshInterval => Duration(
      minutes: AdsConfig.getIntValue('banner_refresh_minutes') > 0
          ? AdsConfig.getIntValue('banner_refresh_minutes')
          : 2);
  Duration get _adExpirationTime => Duration(
      minutes: AdsConfig.getIntValue('banner_cache_minutes') > 0
          ? AdsConfig.getIntValue('banner_cache_minutes')
          : 5);

  @override
  void initState() {
    super.initState();
    if (widget.enableAutoRefresh) {
      _startAutoRefreshTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load ads if they are enabled in Firebase Remote Config
    if (AdsConfig.isAdsEnabled && AdsConfig.isBannerAdsEnabled) {
      // Handle navigation return - try to restore ad quickly
      if (_bannerAd == null && !_isLoading && !_isAdFailed) {
        debugPrint(
            '🔄 BannerAdWidget: Returning from navigation, quick-loading ad');
        _loadAdWithPriority();
      } else if (!_isAdLoaded && !_isAdFailed && !_isLoading) {
        _loadAd();
      }
    }
  }

  @override
  void didUpdateWidget(BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force reload if widget parameters changed (like after navigation)
    if (oldWidget.customAdUnitId != widget.customAdUnitId ||
        oldWidget.useSmartPlacement != widget.useSmartPlacement) {
      debugPrint('🔄 BannerAdWidget: Widget parameters changed, reloading ad');
      forceReload();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();

    // Delayed disposal to handle navigation better
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_bannerAd != null) {
        debugPrint(
            '🗑️ BannerAdWidget: Delayed disposal of banner ad instance');
        _bannerAd!.dispose();
        _bannerAd = null;
      }
    });

    super.dispose();
  }

  /// Start automatic refresh timer for better monetization
  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      if (mounted &&
          _isAdLoaded &&
          AdsConfig.isAdsEnabled &&
          AdsConfig.isBannerAdsEnabled) {
        debugPrint(
            '🔄 BannerAdWidget: Auto-refreshing banner ad for better monetization');
        _refreshAd();
      }
    });
  }

  /// Refresh the ad manually or automatically with improved error handling
  void _refreshAd() {
    if (_isAdLoaded) {
      debugPrint('🔄 BannerAdWidget: Refreshing banner ad');
      setState(() {
        _isAdLoaded = false;
        _isAdFailed = false;
        _retryCount = 0; // Reset retry count for refresh
        _isLoading = true; // Show loading state during refresh
      });
      _bannerAd?.dispose();
      _bannerAd = null;

      // Add delay before loading new ad to prevent conflicts
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _loadAd();
        }
      });
    }
  }

  /// Check if ad is expired
  bool _isAdExpired() {
    if (_adLoadTime == null) return false;
    final timeSinceLoad = DateTime.now().difference(_adLoadTime!);
    return timeSinceLoad >= _adExpirationTime;
  }

  /// Priority loading for navigation returns - faster, shorter timeouts
  void _loadAdWithPriority() {
    // Double-check Firebase config before loading
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isBannerAdsEnabled) {
      debugPrint(
          '🚫 BannerAdWidget: Ads disabled in Firebase, skipping priority load');
      return;
    }

    debugPrint('⚡ BannerAdWidget: Priority loading ad for navigation return');
    setState(() {
      _isLoading = true;
    });

    // Immediate loading without delay for navigation returns
    _loadAdWithTimeout(shortTimeout: true);
  }

  void _loadAd() {
    _loadAdWithTimeout(shortTimeout: false);
  }

  /// Load ad with configurable timeout for different scenarios
  void _loadAdWithTimeout({required bool shortTimeout}) {
    // Double-check Firebase config before loading
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isBannerAdsEnabled) {
      debugPrint('🚫 BannerAdWidget: Ads disabled in Firebase, skipping load');
      return;
    }

    final timeoutType = shortTimeout ? 'priority' : 'normal';
    debugPrint(
        '🔄 BannerAdWidget: Starting $timeoutType ad load (attempt ${_retryCount + 1})');
    setState(() {
      _isLoading = true;
    });

    final adService = Provider.of<AdsService>(context, listen: false);

    // Check if current ad is expired
    if (_isAdExpired()) {
      debugPrint('⏰ BannerAdWidget: Current ad expired, loading fresh ad');
    }

    // Shorter delay for priority loading (navigation returns)
    final delay = shortTimeout
        ? Duration(milliseconds: 100)
        : Duration(milliseconds: 500);

    Future.delayed(delay, () {
      if (!mounted) return;

      debugPrint('📱 BannerAdWidget: Creating unique banner ad instance');

      // Configurable timeout based on loading type
      final timeoutDuration =
          shortTimeout ? Duration(seconds: 15) : Duration(seconds: 30);
      Timer? loadTimeout;
      bool hasTimedOut = false;

      loadTimeout = Timer(timeoutDuration, () {
        if (!hasTimedOut && mounted) {
          hasTimedOut = true;
          debugPrint(
              '⏰ BannerAdWidget: $timeoutType ad load timeout, will retry');
          _handleAdLoadFailure('$timeoutType timeout - will retry');
        }
      });

      // Create unique banner ad instance for this widget
      adService.loadBannerAd(
        adSize: AdSize.banner,
        onAdLoaded: (ad) {
          if (hasTimedOut) return; // Ignore if already timed out
          loadTimeout?.cancel();

          debugPrint(
              '✅ BannerAdWidget: $timeoutType banner ad loaded successfully');
          if (mounted) {
            setState(() {
              _bannerAd = ad as BannerAd;
              _isAdLoaded = true;
              _isAdFailed = false;
              _isLoading = false;
              _adLoadTime = DateTime.now();
              _retryCount = 0; // Reset retry count on success
            });
          }
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          if (hasTimedOut) return; // Ignore if already timed out
          loadTimeout?.cancel();

          debugPrint(
              '❌ BannerAdWidget: $timeoutType banner ad failed to load: ${error.message}');
          debugPrint('❌ BannerAdWidget: Error code: ${error.code}');
          debugPrint('❌ BannerAdWidget: Error domain: ${error.domain}');

          _handleAdLoadFailure(error.message);
        },
      );
    });
  }

  /// Handle ad load failure with retry logic
  void _handleAdLoadFailure(String errorMessage) {
    if (!mounted) return;

    debugPrint('🔄 BannerAdWidget: Handling ad load failure: $errorMessage');

    setState(() {
      _isLoading = false;
      _isAdFailed = true;
      _isAdLoaded = false;
    });

    // Implement exponential backoff retry with longer delays
    if (_retryCount < _maxRetries) {
      _retryCount++;
      final delay =
          Duration(seconds: _retryCount * 5); // 5s, 10s, 15s - longer delays

      debugPrint(
          '🔄 BannerAdWidget: Retrying in ${delay.inSeconds} seconds (attempt ${_retryCount + 1})');

      Timer(delay, () {
        if (mounted) {
          _loadAd();
        }
      });
    } else {
      debugPrint('❌ BannerAdWidget: Max retries reached, showing fallback UI');
      widget.onAdFailed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if ads are disabled in Firebase Remote Config
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isBannerAdsEnabled) {
      return const SizedBox.shrink(); // Invisible widget
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: _buildAdContent(),
    );
  }

  Widget _buildAdContent() {
    // Don't show loading state - keep it clean
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Show loaded ad
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // When ad fails or initializing, just show empty space (no grayed boxes)
    return const SizedBox.shrink();
  }

  /// Manual retry for failed ads
  void _retryAd() {
    if (_retryCount >= _maxRetries) return;

    debugPrint('BannerAdWidget: Manual retry triggered');
    setState(() {
      _isAdFailed = false;
      _isLoading = true;
      _retryCount = 0; // Reset retry count for manual retry
    });

    // Clear any existing ad
    _bannerAd?.dispose();
    _bannerAd = null;

    // Add a small delay before retrying
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _loadAd();
      }
    });
  }

  /// Force reload banner ad (useful for navigation or refresh)
  void forceReload() {
    debugPrint('🔄 BannerAdWidget: Force reload triggered');
    setState(() {
      _isAdLoaded = false;
      _isAdFailed = false;
      _isLoading = false;
      _retryCount = 0;
    });
    _bannerAd?.dispose();
    _bannerAd = null;

    // Only reload if ads are enabled in Firebase
    if (AdsConfig.isAdsEnabled && AdsConfig.isBannerAdsEnabled) {
      // Use priority loading for force reload (usually triggered by navigation)
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _loadAdWithTimeout(shortTimeout: true);
        }
      });
    }
  }

  /// Get time until next auto-refresh
  String _getTimeUntilNextRefresh() {
    if (_adLoadTime == null) return 'unknown';
    final nextRefresh = _adLoadTime!.add(_autoRefreshInterval);
    final timeUntilRefresh = nextRefresh.difference(DateTime.now());
    if (timeUntilRefresh.isNegative) return 'soon';
    return '${timeUntilRefresh.inMinutes}m ${timeUntilRefresh.inSeconds % 60}s';
  }
}
