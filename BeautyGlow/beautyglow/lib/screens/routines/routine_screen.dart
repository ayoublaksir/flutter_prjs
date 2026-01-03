import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';
import '../../widgets/buttons/custom_button.dart';

import '../../models/routine.dart';
import '../../services/ads_service.dart';
import '../../services/rewarded_ad_service.dart';
import '../../services/routine_service.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/ads/smart_native_ad_widget.dart';
import 'add_routine_screen.dart';
import 'execute_routine_screen.dart';

/// Screen for managing beauty routines
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({Key? key}) : super(key: key);

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  List<Routine> _routines = [];
  Set<String> _unlockedRoutines = {};
  int _freeRoutinesCreated = 0;
  static const int _maxFreeRoutines = 3;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRoutines();
    _loadUnlockedRoutines();
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
      debugPrint('🎯 RoutineScreen: Showing interstitial ad (cooldown passed)');
      await adService.showInterstitialAd();
    } else {
      debugPrint(
          '📱 RoutineScreen: Interstitial ad not ready or in cooldown, attempting to load');
      adService.loadInterstitialAd();
    }
  }

  void _loadRoutines() {
    if (mounted) {
      final routineService =
          Provider.of<RoutineService>(context, listen: false);
      setState(() {
        _routines = routineService.routines;
      });
      debugPrint(
          '🔄 RoutineScreen: Loaded ${_routines.length} routines from RoutineService');
    }
  }

  void _loadUnlockedRoutines() {
    // In a real app, this would be loaded from persistent storage
    // For now, we'll simulate some unlocked routines
    if (mounted) {
      setState(() {
        _unlockedRoutines = {
          'morning_skincare',
          'evening_skincare',
          // Add more unlocked routines as needed
        };
        _freeRoutinesCreated = _routines.length;
      });
    }
  }

  void _unlockRoutine(String routineId) {
    if (mounted) {
      setState(() {
        _unlockedRoutines.add(routineId);
      });
    }
    // In a real app, save to persistent storage
  }

  bool _isRoutineUnlocked(String routineId) {
    return _unlockedRoutines.contains(routineId);
  }

  bool _shouldShowRewardedAdForRoutine(String routineId) {
    // Show rewarded ad if routine is not unlocked and user has created max free routines
    return !_isRoutineUnlocked(routineId) &&
        _freeRoutinesCreated >= _maxFreeRoutines;
  }

  void _incrementFreeRoutines() {
    if (mounted) {
      setState(() {
        _freeRoutinesCreated += 3; // Unlock 3 more routines
      });
      debugPrint(
          '✅ RoutineScreen: Unlocked 3 more routines. Total: $_freeRoutinesCreated');
    }
    // In a real app, save to persistent storage
  }

  void _deleteRoutine(Routine routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text('Are you sure you want to delete "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                final routineService =
                    Provider.of<RoutineService>(context, listen: false);
                await routineService.deleteRoutine(routine.id);
                // No need to manually call _loadRoutines() - Consumer<RoutineService> will handle reactive updates
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting routine: $e'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
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

  void _completeRoutine(Routine routine) async {
    // All routines can be completed without ads
    _performCompleteRoutine(routine);
  }

  void _performCompleteRoutine(Routine routine) async {
    try {
      // Use RoutineService for completion - reactive UI will handle updates automatically
      final routineService =
          Provider.of<RoutineService>(context, listen: false);
      await routineService.completeRoutine(routine.id);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${routine.name} completed!'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        // Show interstitial ad after routine completion (for free users)
        final adService = Provider.of<AdsService>(context, listen: false);
        if (adService.isInterstitialAdReady) {
          // Small delay to ensure snackbar is visible
          await Future.delayed(const Duration(milliseconds: 1500));
          await adService.showInterstitialAd();
        }
      }
    } catch (e) {
      debugPrint('Error completing routine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing routine: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _navigateToAddRoutine() async {
    final rewardedAdService =
        Provider.of<RewardedAdService>(context, listen: false);

    // Check if user can create more routines
    if (!rewardedAdService.canCreateRoutine) {
      // Show rewarded ad dialog for creating more routines
      _showRewardedAdDialog(context, rewardedAdService);
    } else {
      // User can create routine for free
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddRoutineScreen(),
        ),
      );
      if (result == true && mounted) {
        // Routine creation is already tracked by RoutineService - Consumer will update automatically
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
          title: const Text('🎁 Unlock More Routines'),
          content: Text(adsService.getFeatureMessage('unlock_routines')),
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
                  featureType: 'unlock_routines',
                  onRewardEarned: () async {
                    // Show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('🎉 3 additional routine slots unlocked!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    // Small delay to ensure UI updates
                    await Future.delayed(const Duration(milliseconds: 100));

                    // Navigate to add routine screen
                    if (context.mounted) {
                      try {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddRoutineScreen(),
                          ),
                        );
                        if (result == true && context.mounted) {
                          // Consumer<RoutineService> will handle the refresh automatically
                        }
                      } catch (e) {
                        debugPrint(
                            '❌ Error navigating to AddRoutineScreen: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Error opening add routine screen: $e'),
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
                      debugPrint(
                          '🔄 Consumer will auto-refresh after rewarded ad closed');
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

  void _navigateToEditRoutine(Routine routine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoutineScreen(routine: routine),
      ),
    );
    if (result == true && mounted) {
      // Consumer<RoutineService> will handle the refresh automatically
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineService>(
      builder: (context, routineService, child) {
        // Update local routines list when RoutineService changes
        _routines = routineService.routines;
        debugPrint(
            '🔄 RoutineScreen: Consumer updated - ${_routines.length} routines');

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Routines'),
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
                          Icons.spa_rounded,
                          color: AppColors.primaryPink,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create and manage your beauty routines',
                          style: TextStyle(
                            fontSize:
                                ResponsiveUtil.instance.scaledFontSize(13),
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
              // Banner Ad
              BannerAdWidget(
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtil.instance.proportionateWidth(16),
                  vertical: ResponsiveUtil.instance.proportionateHeight(8),
                ),
              ),

              // Routines List
              Expanded(
                child: _routines.isEmpty
                    ? _buildEmptyState()
                    : _buildRoutinesList(),
              ),

              // Native Ad at bottom
              SmartNativeAdWidget(
                screenName: 'routines',
                contentType: 'routine_list',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _navigateToAddRoutine,
            backgroundColor: AppColors.primaryPink,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.spa,
            size: ResponsiveUtil.instance.proportionateWidth(80),
            color: Colors.grey[400],
          ),
          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
          Text(
            'No routines yet',
            style: TextStyle(
              fontSize: ResponsiveUtil.instance.scaledFontSize(20),
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),
          Text(
            'Create your first beauty routine',
            style: TextStyle(
              fontSize: ResponsiveUtil.instance.scaledFontSize(16),
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),
          CustomButton(
            text: 'Create Routine',
            onPressed: _navigateToAddRoutine,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutinesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(ResponsiveUtil.instance.proportionateWidth(16)),
      itemCount: _routines.length,
      itemBuilder: (context, index) {
        final routine = _routines[index];
        return _buildRoutineCard(routine);
      },
    );
  }

  Widget _buildRoutineCard(Routine routine) {
    // Check if routine is completed today for visual feedback
    final isCompletedToday = routine.isCompletedForToday;

    return Container(
      margin: EdgeInsets.only(
          bottom: ResponsiveUtil.instance.proportionateHeight(16)),
      decoration: BoxDecoration(
        color: isCompletedToday ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCompletedToday
            ? Border.all(color: Colors.green.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isCompletedToday
                ? Colors.green.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToEditRoutine(routine),
          child: Padding(
            padding:
                EdgeInsets.all(ResponsiveUtil.instance.proportionateWidth(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  routine.name,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtil.instance
                                        .scaledFontSize(18),
                                    fontWeight: FontWeight.bold,
                                    color: isCompletedToday
                                        ? Colors.grey[500]
                                        : Colors.black87,
                                    decoration: isCompletedToday
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              if (isCompletedToday)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Completed',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtil.instance
                                              .scaledFontSize(12),
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(
                              height: ResponsiveUtil.instance
                                  .proportionateHeight(4)),
                          Text(
                            '${routine.steps.length} steps',
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtil.instance.scaledFontSize(14),
                              color: isCompletedToday
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _navigateToEditRoutine(routine);
                            break;
                          case 'delete':
                            _deleteRoutine(routine);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                    height: ResponsiveUtil.instance.proportionateHeight(12)),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Complete',
                        onPressed: () => _completeRoutine(routine),
                        color: AppColors.successGreen,
                      ),
                    ),
                    SizedBox(
                        width: ResponsiveUtil.instance.proportionateWidth(12)),
                    Expanded(
                      child: CustomButton(
                        text: 'Execute',
                        onPressed: () => _executeRoutine(routine),
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ],
                ),
                if (routine.completedCount > 0) ...[
                  SizedBox(
                      height: ResponsiveUtil.instance.proportionateHeight(8)),
                  Text(
                    'Completed ${routine.completedCount} times',
                    style: TextStyle(
                      fontSize: ResponsiveUtil.instance.scaledFontSize(12),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  void _executeRoutine(Routine routine) {
    // All routines can be executed without ads
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExecuteRoutineScreen(routine: routine),
      ),
    );
  }
}
