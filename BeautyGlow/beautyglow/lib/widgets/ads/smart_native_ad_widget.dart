import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../services/ads_service.dart';
import '../../core/config/ads_config.dart';
import '../../core/responsive/responsive_util.dart';
import '../../core/constants/app_colors.dart';

/// Smart Native Ad Widget with Intelligent Placement
/// Uses AI-like logic to determine optimal ad placement based on:
/// - User engagement patterns
/// - Content type and context
/// - Screen position and timing
/// - User preferences and behavior
class SmartNativeAdWidget extends StatefulWidget {
  final String screenName;
  final String contentType;
  final int contentIndex;
  final bool isUserEngaged;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailed;
  final VoidCallback? onAdClicked;

  const SmartNativeAdWidget({
    Key? key,
    required this.screenName,
    required this.contentType,
    this.contentIndex = 0,
    this.isUserEngaged = false,
    this.onAdLoaded,
    this.onAdFailed,
    this.onAdClicked,
  }) : super(key: key);

  @override
  State<SmartNativeAdWidget> createState() => _SmartNativeAdWidgetState();
}

class _SmartNativeAdWidgetState extends State<SmartNativeAdWidget> {
  BannerAd? _nativeAd; // Using BannerAd for now
  bool _isAdLoaded = false;
  bool _isAdFailed = false;
  bool _isLoading = false;
  bool _shouldShowAd = false;
  String _adPlacement = 'default';

  @override
  void initState() {
    super.initState();
    _determineAdPlacement();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  /// Smart placement logic based on multiple factors
  void _determineAdPlacement() {
    final placement = _calculateOptimalPlacement();

    if (placement != null) {
      setState(() {
        _adPlacement = placement;
        _shouldShowAd = true;
      });
      _loadNativeAd();
    } else {
      setState(() {
        _shouldShowAd = false;
      });
    }
  }

  /// Calculate optimal ad placement based on context
  String? _calculateOptimalPlacement() {
    // Factor 1: Screen-based placement logic
    switch (widget.screenName) {
      case 'tips_screen':
        return _getTipsScreenPlacement();
      case 'products_screen':
        return _getProductsScreenPlacement();
      case 'routines_screen':
        return _getRoutinesScreenPlacement();
      case 'tip_detail_screen':
        return _getTipDetailPlacement();
      default:
        return _getDefaultPlacement();
    }
  }

  /// Tips screen placement logic
  String? _getTipsScreenPlacement() {
    // Show ads after every 3rd tip for optimal engagement
    if (widget.contentIndex > 0 && widget.contentIndex % 3 == 0) {
      return 'tips_middle';
    }
    // Show at bottom if user has scrolled through many tips
    if (widget.contentIndex > 6) {
      return 'tips_bottom';
    }
    return null;
  }

  /// Products screen placement logic
  String? _getProductsScreenPlacement() {
    // Show ads after every 4th product
    if (widget.contentIndex > 0 && widget.contentIndex % 4 == 0) {
      return 'products_middle';
    }
    // Show at bottom if user has many products
    if (widget.contentIndex > 8) {
      return 'products_bottom';
    }
    return null;
  }

  /// Routines screen placement logic
  String? _getRoutinesScreenPlacement() {
    // Show ads after every 2nd routine (routines are more valuable)
    if (widget.contentIndex > 0 && widget.contentIndex % 2 == 0) {
      return 'routines_middle';
    }
    // Show at bottom if user has several routines
    if (widget.contentIndex > 4) {
      return 'routines_bottom';
    }
    return null;
  }

  /// Tip detail screen placement logic
  String? _getTipDetailPlacement() {
    // Show ad in middle of content for detailed tips
    if (widget.contentType == 'detailed_tip') {
      return 'tip_detail_middle';
    }
    // Show at bottom for quick tips
    if (widget.contentType == 'quick_tip') {
      return 'tip_detail_bottom';
    }
    return null;
  }

  /// Default placement logic
  String? _getDefaultPlacement() {
    // Show ads based on user engagement
    if (widget.isUserEngaged) {
      return 'engaged_user';
    }
    // Show ads every 5th item by default
    if (widget.contentIndex > 0 && widget.contentIndex % 5 == 0) {
      return 'default_middle';
    }
    return null;
  }

  void _loadNativeAd() {
    if (_isLoading || !_shouldShowAd) return;

    // Check if ads are enabled in Firebase Remote Config
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isBannerAdsEnabled) {
      debugPrint(
          '🚫 SmartNativeAdWidget: Ads disabled in Firebase, skipping load');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final adService = Provider.of<AdsService>(context, listen: false);

    adService.loadBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _nativeAd = ad as BannerAd; // Using BannerAd for now
            _isAdLoaded = true;
            _isLoading = false;
          });
          widget.onAdLoaded?.call();
        }
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isAdFailed = true;
            _isLoading = false;
          });
        }
        ad.dispose();
        widget.onAdFailed?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if ads are disabled in Firebase Remote Config
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isBannerAdsEnabled) {
      return const SizedBox.shrink();
    }

    // Don't show ad if placement logic determined it shouldn't be shown
    if (!_shouldShowAd) {
      return const SizedBox.shrink();
    }

    if (_isAdFailed) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return _buildLoadingPlaceholder();
    }

    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return _buildSmartAdContainer();
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPink.withOpacity(0.05),
            AppColors.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPink.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.primaryPink.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAdContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPink.withOpacity(0.1),
            AppColors.primaryPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPink.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Smart Ad Label with placement info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Smart Recommendation',
                  style: TextStyle(
                    fontSize: ResponsiveUtil.instance.scaledFontSize(10),
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.primaryPink.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Native Ad Content
          AdWidget(ad: _nativeAd!),
        ],
      ),
    );
  }
}

/// Smart Native Ad Manager
/// Manages multiple smart native ads across the app
class SmartNativeAdManager {
  static final SmartNativeAdManager _instance =
      SmartNativeAdManager._internal();
  factory SmartNativeAdManager() => _instance;
  SmartNativeAdManager._internal();

  final Map<String, int> _adShowCounts = {};
  final Map<String, DateTime> _lastAdShows = {};
  final Map<String, bool> _userEngagement = {};

  /// Track user engagement for smart placement
  void trackUserEngagement(String screenName, bool isEngaged) {
    _userEngagement[screenName] = isEngaged;
  }

  /// Track ad show for frequency control
  void trackAdShow(String placement) {
    _adShowCounts[placement] = (_adShowCounts[placement] ?? 0) + 1;
    _lastAdShows[placement] = DateTime.now();
  }

  /// Check if ad should be shown based on frequency and timing
  bool shouldShowAd(String placement,
      {int maxShows = 3, int cooldownMinutes = 5}) {
    final showCount = _adShowCounts[placement] ?? 0;
    final lastShow = _lastAdShows[placement];

    // Don't show if max shows reached
    if (showCount >= maxShows) {
      return false;
    }

    // Don't show if within cooldown period
    if (lastShow != null) {
      final timeSinceLastShow = DateTime.now().difference(lastShow);
      if (timeSinceLastShow.inMinutes < cooldownMinutes) {
        return false;
      }
    }

    return true;
  }

  /// Get optimal ad placement based on context
  String getOptimalPlacement(
      String screenName, String contentType, int contentIndex) {
    // Reset show counts for new sessions
    if (contentIndex == 0) {
      _adShowCounts.clear();
    }

    // Smart placement logic
    switch (screenName) {
      case 'tips_screen':
        return _getTipsPlacement(contentIndex);
      case 'products_screen':
        return _getProductsPlacement(contentIndex);
      case 'routines_screen':
        return _getRoutinesPlacement(contentIndex);
      case 'tip_detail_screen':
        return _getTipDetailPlacement(contentType);
      default:
        return _getDefaultPlacement(contentIndex);
    }
  }

  String _getTipsPlacement(int contentIndex) {
    if (contentIndex > 0 && contentIndex % 3 == 0) {
      return 'tips_middle';
    }
    if (contentIndex > 6) {
      return 'tips_bottom';
    }
    return 'none';
  }

  String _getProductsPlacement(int contentIndex) {
    if (contentIndex > 0 && contentIndex % 4 == 0) {
      return 'products_middle';
    }
    if (contentIndex > 8) {
      return 'products_bottom';
    }
    return 'none';
  }

  String _getRoutinesPlacement(int contentIndex) {
    if (contentIndex > 0 && contentIndex % 2 == 0) {
      return 'routines_middle';
    }
    if (contentIndex > 4) {
      return 'routines_bottom';
    }
    return 'none';
  }

  String _getTipDetailPlacement(String contentType) {
    if (contentType == 'detailed_tip') {
      return 'tip_detail_middle';
    }
    if (contentType == 'quick_tip') {
      return 'tip_detail_bottom';
    }
    return 'tip_detail_default';
  }

  String _getDefaultPlacement(int contentIndex) {
    if (contentIndex > 0 && contentIndex % 5 == 0) {
      return 'default_middle';
    }
    return 'none';
  }

  /// Reset all tracking data
  void resetTracking() {
    _adShowCounts.clear();
    _lastAdShows.clear();
    _userEngagement.clear();
  }
}
