import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../data/storage_service.dart';
import '../../models/product.dart';
import '../../services/ads_service.dart';
import '../../services/rewarded_ad_service.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/ads/smart_native_ad_widget.dart';
import 'add_product_screen.dart';

/// Screen for managing beauty products collection
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final StorageService _storageService = StorageService();
  List<Product> _products = [];
  String _selectedCategory = 'all';
  int _freeProductsCreated = 0;
  static const int _maxFreeProducts = 3;
  final ScrollController _scrollController = ScrollController();
  final List<String> _categories = [
    'all',
    'skincare',
    'makeup',
    'haircare',
    'fragrance',
    'bodycare',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFreeProductsCount();
    _scrollController.addListener(_onScroll);
    _loadAds();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Remove direct banner ad loading - will use BannerAdWidget instead
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    if (mounted) {
      setState(() {
        _products = _storageService.getAllProducts();
      });
    }
  }

  void _loadFreeProductsCount() {
    // In a real app, this would be loaded from persistent storage
    if (mounted) {
      setState(() {
        _freeProductsCreated = _products.length;
      });
    }
  }

  void _incrementFreeProducts() {
    if (mounted) {
      setState(() {
        _freeProductsCreated += 3; // Unlock 3 more products
      });
      debugPrint(
          '✅ ProductsScreen: Unlocked 3 more products. Total: $_freeProductsCreated');
    }
    // In a real app, save to persistent storage
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _storageService.deleteProduct(product.id);
              Navigator.pop(context);
              _loadProducts();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'all') {
      return _products;
    }
    return _products
        .where((product) => product.category == _selectedCategory)
        .toList();
  }

  void _navigateToAddProduct() async {
    final rewardedAdService =
        Provider.of<RewardedAdService>(context, listen: false);

    // Check if user can create more products
    if (!rewardedAdService.canCreateProduct) {
      // Show rewarded ad dialog for creating more products
      _showRewardedAdDialog(context, rewardedAdService);
    } else {
      // User can create product for free
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddProductScreen(),
        ),
      );
      if (result == true && mounted) {
        rewardedAdService.trackProductCreation();
        _loadProducts();
      }
    }
  }

  void _showRewardedAdDialog(
      BuildContext context, RewardedAdService adsService) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎁 Unlock More Products'),
          content: Text(adsService.getFeatureMessage('unlock_products')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Maybe Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();

                adsService.showRewardedAdForFeature(
                  featureType: 'unlock_products',
                  onRewardEarned: () async {
                    // Show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('🎉 3 additional product slots unlocked!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    // Small delay to ensure UI updates
                    await Future.delayed(const Duration(milliseconds: 100));

                    // Navigate to add product screen
                    if (context.mounted) {
                      try {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddProductScreen(),
                          ),
                        );
                        if (result == true && context.mounted) {
                          // Refresh the products list
                          _loadProducts();
                        }
                      } catch (e) {
                        debugPrint(
                            '❌ Error navigating to AddProductScreen: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Error opening add product screen: $e'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                        }
                      }
                    }
                  },
                  onAdFailedToShow: () {
                    if (context.mounted) {
                      final rewardedAdService = Provider.of<RewardedAdService>(
                          context,
                          listen: false);
                      final message = rewardedAdService.adAvailabilityMessage;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 4),
                          action: SnackBarAction(
                            label: 'Retry',
                            textColor: Colors.white,
                            onPressed: () {
                              // Force reload rewarded ad
                              rewardedAdService.forceReloadRewardedAd();
                            },
                          ),
                        ),
                      );
                    }
                  },
                  onAdClosed: () {
                    // Auto-refresh screen when ad is closed
                    if (context.mounted) {
                      debugPrint('🔄 Auto-refreshing after rewarded ad closed');
                      _loadProducts();
                    }
                  },
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Watch Ad'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: product),
      ),
    );
    if (result == true) {
      _loadProducts();
    }
  }

  void _loadAds() {
    final adService = Provider.of<AdsService>(context, listen: false);
    adService.loadInterstitialAd();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.4) {
      _showAdIfReady();
    }
  }

  Future<void> _showAdIfReady() async {
    final adService = Provider.of<AdsService>(context, listen: false);

    // Check cooldown and show ad if ready (includes 10-minute cooldown logic)
    if (adService.shouldShowInterstitialAd() &&
        adService.isInterstitialAdReady) {
      debugPrint(
          '🎯 ProductsScreen: Showing interstitial ad (cooldown passed)');
      await adService.showInterstitialAd();
    } else {
      debugPrint(
          '📱 ProductsScreen: Interstitial ad not ready or in cooldown, attempting to load');
      adService.loadInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtil.instance.proportionateWidth(16),
              vertical: ResponsiveUtil.instance.proportionateHeight(8),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPink.withOpacity(0.1),
                    AppColors.primaryPurple.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryPink.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtil.instance.proportionateWidth(16),
                vertical: ResponsiveUtil.instance.proportionateHeight(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primaryPink,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Manage your beauty products',
                      style: TextStyle(
                        fontSize: ResponsiveUtil.instance.scaledFontSize(13),
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 50,
            margin: EdgeInsets.symmetric(
              vertical: ResponsiveUtil.instance.proportionateHeight(8),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtil.instance
                    .proportionateWidth(AppDimensions.paddingMedium),
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: EdgeInsets.only(
                    right: ResponsiveUtil.instance.proportionateWidth(8),
                  ),
                  child: ChoiceChip(
                    label: Text(_getCategoryLabel(category)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (mounted) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: AppColors.primaryPink,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 50 * index),
                      ),
                );
              },
            ),
          ),

          // Banner Ad - Using BannerAdWidget for consistent loading
          BannerAdWidget(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtil.instance.proportionateWidth(16),
              vertical: ResponsiveUtil.instance.proportionateHeight(8),
            ),
          ),

          // Products grid or empty state
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmptyState()
                : _buildProductsGrid(),
          ),

          // Native Ad at bottom
          SmartNativeAdWidget(
            screenName: 'products',
            contentType: 'product_list',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'products_fab',
        onPressed: () {
          _navigateToAddProduct();
        },
        backgroundColor: AppColors.primaryPink,
        child: const Icon(Icons.add, color: Colors.white),
      ).animate().scale(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
          ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'all':
        return 'All';
      case 'skincare':
        return 'Skincare';
      case 'makeup':
        return 'Makeup';
      case 'haircare':
        return 'Hair Care';
      case 'fragrance':
        return 'Fragrance';
      case 'bodycare':
        return 'Body Care';
      default:
        return category;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtil.instance
              .proportionateWidth(AppDimensions.paddingLarge),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.softRose,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 50,
                color: AppColors.primaryPink,
              ),
            ).animate().scale(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),
            Text(
              _selectedCategory == 'all'
                  ? 'No Products Yet'
                  : 'No ${_getCategoryLabel(_selectedCategory)} Products',
              style: AppTypography.headingMedium,
            ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),
            Text(
              'Add your favorite beauty products to keep track of them',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(32)),
            CustomButton(
              text: 'Add First Product',
              onPressed: () {
                _navigateToAddProduct();
              },
              icon: Icons.add,
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 400))
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadProducts();
      },
      color: AppColors.primaryPink,
      child: GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(
          ResponsiveUtil.instance
              .proportionateWidth(AppDimensions.paddingMedium),
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveUtil.instance.getGridColumns(context),
          crossAxisSpacing: ResponsiveUtil.instance.proportionateWidth(12),
          mainAxisSpacing: ResponsiveUtil.instance.proportionateHeight(12),
          childAspectRatio: ResponsiveBreakpoints.isMobile(context) ? 0.8 : 0.9,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return _ProductCard(
            product: product,
            onTap: () => _navigateToEditProduct(product),
            onDelete: () => _deleteProduct(product),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 50 * (index % 10)),
                duration: const Duration(milliseconds: 300),
              )
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: const Duration(milliseconds: 300),
              );
        },
      ),
    );
  }
}

/// Individual product card widget
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Container(
          padding: EdgeInsets.all(
            ResponsiveUtil.instance
                .proportionateWidth(AppDimensions.paddingMedium),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product image placeholder
              Stack(
                children: [
                  Container(
                    height: ResponsiveUtil.instance.proportionateHeight(100),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      child: product.hasImage
                          ? Image.file(
                              File(product.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: AppColors
                                        .categoryColors[product.category] ??
                                    AppColors.softRose,
                                child: Icon(
                                  _getProductIcon(product.category),
                                  size: 40,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            )
                          : Container(
                              color:
                                  AppColors.categoryColors[product.category] ??
                                      AppColors.softRose,
                              child: Icon(
                                _getProductIcon(product.category),
                                size: 40,
                                color: AppColors.primaryPink,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onDelete,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: AppColors.errorRed,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),

              // Product name
              Text(
                product.name,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(4)),

              // Brand name
              Text(
                product.brand,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Bottom info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Rating
                  if (product.rating > 0) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.warningAmber,
                        ),
                        SizedBox(
                            width:
                                ResponsiveUtil.instance.proportionateWidth(4)),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Not rated',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  // Favorite icon
                  if (product.isFavorite)
                    Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: AppColors.primaryPink,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProductIcon(String category) {
    switch (category) {
      case 'skincare':
        return Icons.face_retouching_natural;
      case 'makeup':
        return Icons.brush;
      case 'haircare':
        return Icons.air;
      case 'fragrance':
        return Icons.local_florist;
      case 'bodycare':
        return Icons.spa;
      default:
        return Icons.shopping_bag;
    }
  }
}
