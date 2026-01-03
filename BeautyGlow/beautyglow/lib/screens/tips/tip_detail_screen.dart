import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';
import '../../models/beauty_tip.dart';
import '../../services/ads_service.dart';
import '../../services/tip_article_counter_service.dart';
import '../../core/config/ads_config.dart';
import '../../widgets/ads/banner_ad_widget.dart';

class TipDetailScreen extends StatefulWidget {
  final BeautyTip tip;

  const TipDetailScreen({Key? key, required this.tip}) : super(key: key);

  @override
  State<TipDetailScreen> createState() => _TipDetailScreenState();
}

class _TipDetailScreenState extends State<TipDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedEnd = false;
  bool _isFavorite = false;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  bool _hasInitializedAd = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAds();
    _incrementTipCounter();
  }

  /// Increment tip article counter when article is opened
  Future<void> _incrementTipCounter() async {
    final counterService =
        Provider.of<TipArticleCounterService>(context, listen: false);
    await counterService.incrementTipArticleCount();
    debugPrint('🔢 ${counterService.getDebugStatus()}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedAd) {
      _loadBannerAd();
      _hasInitializedAd = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAds() {
    final adService = Provider.of<AdsService>(context, listen: false);
    adService.loadInterstitialAd();
  }

  void _loadBannerAd() {
    // Check if ads are enabled in Firebase Remote Config
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isBannerAdsEnabled) {
      debugPrint(
          '🚫 TipDetailScreen: Banner ads disabled in Firebase, skipping load');
      return;
    }

    final adService = Provider.of<AdsService>(context, listen: false);

    debugPrint('🔄 TipDetailScreen: Loading banner ad (Firebase enabled)');

    adService.loadBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (ad) {
        debugPrint('✅ TipDetailScreen: Banner ad loaded successfully');
        if (mounted) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerAdReady = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('❌ TipDetailScreen: Banner ad failed to load: $error');
        debugPrint('❌ TipDetailScreen: Error code: ${error.code}');
        debugPrint('❌ TipDetailScreen: Error domain: ${error.domain}');

        // Don't retry automatically - keep it clean
      },
    );
  }

  void _onScroll() {
    if (!_hasReachedEnd &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8) {
      setState(() => _hasReachedEnd = true);
      _showAdIfReady();
    }
  }

  Future<void> _showAdIfReady() async {
    final adService = Provider.of<AdsService>(context, listen: false);
    final counterService =
        Provider.of<TipArticleCounterService>(context, listen: false);

    // Use alternating pattern: 1st = NO ads, 2nd = WITH ads, 3rd = NO ads, etc.
    if (counterService.shouldShowAdsForCurrentArticle) {
      if (adService.isInterstitialAdReady) {
        debugPrint(
            '🎯 TipDetailScreen: Showing interstitial ad (article ${counterService.tipArticleCount} - EVEN count)');
        await adService.showInterstitialAd();
      } else {
        debugPrint(
            '📱 TipDetailScreen: Interstitial ad not ready (article ${counterService.tipArticleCount} - EVEN count), attempting to load');
        // RETRY LOADING - this was missing!
        adService.loadInterstitialAd();
      }
    } else {
      debugPrint(
          '📱 TipDetailScreen: Skipping interstitial ad (article ${counterService.tipArticleCount} - ODD count - no ads)');
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite
            ? 'Tip saved to favorites'
            : 'Tip removed from favorites'),
        backgroundColor: _getCategoryColor(widget.tip.category),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh the tip data and ads
          _loadBannerAd();
          _loadAds();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: _getCategoryColor(widget.tip.category),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Modern Hero Image Header with Enhanced Parallax Effect
            SliverAppBar(
              expandedHeight: ResponsiveUtil.instance.proportionateHeight(350),
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    // Add haptic feedback
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                  ),
                ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'tip_image_${widget.tip.title}',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Main Image with Enhanced Blur Effect
                      Image.asset(
                        widget.tip.imagePath,
                        fit: BoxFit.cover,
                      ),
                      // Enhanced Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // Floating Elements
                      Positioned(
                        top: 60,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(widget.tip.category)
                                .withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.tip.category.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ).animate().slideX(begin: 1, end: 0).fadeIn(),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  widget.tip.title,
                  style: TextStyle(
                    fontSize: ResponsiveUtil.instance.scaledFontSize(22),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modern Content Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content Padding
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtil.instance.proportionateWidth(24),
                        vertical:
                            ResponsiveUtil.instance.proportionateHeight(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Category Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtil.instance
                                  .proportionateWidth(16),
                              vertical: ResponsiveUtil.instance
                                  .proportionateHeight(8),
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(widget.tip.category)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: _getCategoryColor(widget.tip.category)
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(widget.tip.category),
                                  color: _getCategoryColor(widget.tip.category),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.tip.category.toUpperCase(),
                                  style: TextStyle(
                                    color:
                                        _getCategoryColor(widget.tip.category),
                                    fontSize: ResponsiveUtil.instance
                                        .scaledFontSize(14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.3, end: 0),

                          SizedBox(
                              height: ResponsiveUtil.instance
                                  .proportionateHeight(24)),

                          // Enhanced Short Description
                          Container(
                            padding: EdgeInsets.all(
                                ResponsiveUtil.instance.proportionateWidth(20)),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              widget.tip.shortDescription,
                              style: TextStyle(
                                fontSize:
                                    ResponsiveUtil.instance.scaledFontSize(18),
                                color: Colors.grey[800],
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: const Duration(milliseconds: 200))
                              .slideY(begin: 0.3, end: 0),

                          SizedBox(
                              height: ResponsiveUtil.instance
                                  .proportionateHeight(32)),

                          // Main Content with Enhanced Styling
                          _buildFormattedContent(widget.tip.fullContent),

                          // Bottom spacing for FAB
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Enhanced Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleFavorite,
        backgroundColor: _getCategoryColor(widget.tip.category),
        elevation: 8,
        icon: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: Colors.white,
        ),
        label: Text(
          _isFavorite ? 'Saved' : 'Save',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ).animate().scale().fadeIn(delay: const Duration(milliseconds: 500)),
    );
  }

  Widget _buildFormattedContent(String content) {
    final paragraphs = content.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        if (paragraph.trim().startsWith('•') ||
            paragraph.trim().startsWith('-')) {
          // Bullet points
          return _buildBulletPoints(paragraph);
        } else if (paragraph.contains(':')) {
          // Section headers
          return _buildSection(paragraph);
        } else {
          // Regular paragraphs
          return Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtil.instance.proportionateHeight(16),
            ),
            child: Text(
              paragraph,
              style: TextStyle(
                fontSize: ResponsiveUtil.instance.scaledFontSize(16),
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildBulletPoints(String content) {
    final points = content.split('\n');
    return Padding(
      padding: EdgeInsets.only(
        left: ResponsiveUtil.instance.proportionateWidth(16),
        bottom: ResponsiveUtil.instance.proportionateHeight(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: points.map((point) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtil.instance.proportionateHeight(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: TextStyle(
                    fontSize: ResponsiveUtil.instance.scaledFontSize(16),
                    color: _getCategoryColor(widget.tip.category),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: ResponsiveUtil.instance.proportionateWidth(8)),
                Expanded(
                  child: Text(
                    point.replaceAll(RegExp(r'^[•-]\s*'), ''),
                    style: TextStyle(
                      fontSize: ResponsiveUtil.instance.scaledFontSize(16),
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection(String content) {
    final parts = content.split(':');
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtil.instance.proportionateHeight(16),
        top: ResponsiveUtil.instance.proportionateHeight(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parts[0].trim(),
            style: TextStyle(
              fontSize: ResponsiveUtil.instance.scaledFontSize(20),
              fontWeight: FontWeight.bold,
              color: _getCategoryColor(widget.tip.category),
            ),
          ),
          SizedBox(
            height: ResponsiveUtil.instance.proportionateHeight(8),
          ),
          if (parts.length > 1)
            Text(
              parts[1].trim(),
              style: TextStyle(
                fontSize: ResponsiveUtil.instance.scaledFontSize(16),
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'skincare':
        return Color(0xFFE91E63); // Pink
      case 'makeup':
        return Color(0xFF9C27B0); // Purple
      case 'haircare':
        return Color(0xFF3F51B5); // Indigo
      case 'lifestyle':
        return Color(0xFF009688); // Teal
      default:
        return Color(0xFF9E9E9E); // Grey
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'skincare':
        return Icons.face;
      case 'makeup':
        return Icons.brush;
      case 'haircare':
        return Icons.content_cut;
      case 'wellness':
        return Icons.self_improvement;
      case 'lifestyle':
        return Icons.favorite;
      default:
        return Icons.star;
    }
  }
}
