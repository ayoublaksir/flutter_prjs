import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../services/ads_service.dart';
import '../../core/responsive/responsive_util.dart';
import '../../core/constants/app_colors.dart';

/// Native Ad Widget for BeautyGlow App
/// Provides a more integrated ad experience that matches the app's design
class NativeAdWidget extends StatefulWidget {
  final String? placement;
  final EdgeInsets? margin;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailed;

  const NativeAdWidget({
    Key? key,
    this.placement,
    this.margin,
    this.onAdLoaded,
    this.onAdFailed,
  }) : super(key: key);

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadNativeAd() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final adService = Provider.of<AdsService>(context, listen: false);

    adService.loadNativeAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _nativeAd = ad as NativeAd;
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
    if (_isAdFailed) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Container(
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.image,
                color: Colors.grey,
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
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

    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

/// Beauty-themed Native Ad Widget
/// Custom styled native ad that matches the beauty app theme
class BeautyNativeAdWidget extends StatefulWidget {
  final String? placement;
  final EdgeInsets? margin;

  const BeautyNativeAdWidget({
    Key? key,
    this.placement,
    this.margin,
  }) : super(key: key);

  @override
  State<BeautyNativeAdWidget> createState() => _BeautyNativeAdWidgetState();
}

class _BeautyNativeAdWidgetState extends State<BeautyNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadNativeAd() {
    final adService = Provider.of<AdsService>(context, listen: false);

    adService.loadNativeAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _nativeAd = ad as NativeAd;
            _isAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isAdFailed = true;
          });
        }
        ad.dispose();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdFailed || !_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 12),
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
          // Ad Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Sponsored',
              style: TextStyle(
                fontSize: ResponsiveUtil.instance.scaledFontSize(10),
                color: AppColors.primaryPink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Native Ad Content
          AdWidget(ad: _nativeAd!),
        ],
      ),
    );
  }
}
