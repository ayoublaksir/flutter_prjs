import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/tips_data.dart';
import '../../core/responsive/responsive_util.dart';
import '../../core/constants/app_colors.dart';
import '../../services/ads_service.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/ads/premium_content_wrapper.dart';
import 'category_filter_bar.dart';
import 'tips_grid_view.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Screen for browsing beauty tips
class TipsScreen extends StatefulWidget {
  const TipsScreen({Key? key}) : super(key: key);

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  String? _selectedCategory;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkInterstitialAd() {
    final adService = Provider.of<AdsService>(context, listen: false);

    // Check cooldown and show ad if ready (includes 10-minute cooldown logic)
    if (adService.shouldShowInterstitialAd() &&
        adService.isInterstitialAdReady) {
      debugPrint('🎯 TipsScreen: Showing interstitial ad (cooldown passed)');
      adService.showInterstitialAd();
    } else {
      debugPrint(
          '📱 TipsScreen: Interstitial ad not ready or in cooldown, attempting to load');
      adService.loadInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header with Modern UI
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPink.withOpacity(0.1),
                    AppColors.primaryPurple.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.all(
                ResponsiveUtil.instance.proportionateWidth(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: AppColors.primaryPink,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Beauty Tips',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveUtil.instance.scaledFontSize(28),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Discover expert beauty advice and tutorials',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveUtil.instance.scaledFontSize(14),
                                color: Colors.grey[600],
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryPink.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tips_and_updates_rounded,
                          color: AppColors.primaryPink,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'expert tips',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryPink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter
            CategoryFilterBar(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),

            // Tips Grid with Interstitial Ad at 40% scroll
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent * 0.4) {
                    _checkInterstitialAd();
                  }
                  return false;
                },
                child: TipsGridView(
                  tips: beautyTips,
                  selectedCategory: _selectedCategory,
                ),
              ),
            ),

            // Smart Banner Ad
            BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}
