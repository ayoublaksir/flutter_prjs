# 🎁 Rewarded Ad Logic Extraction - SwipeChef

## 📋 **Complete Rewarded Ad Implementation for Other Apps**

### **1. Core Rewarded Ad Service**

```dart
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  // Ad instance
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  // Daily limits tracking
  int _dailySwipeLimit = 25;
  int _dailySaveLimit = 5;
  int _dailyPlanningLimit = 3;

  int _todaySwipes = 0;
  int _todaySaves = 0;
  int _todayPlannings = 0;

  DateTime? _lastResetDate;

  // Getters
  bool get isRewardedAdReady => _isRewardedAdReady;
  int get remainingSwipes => _dailySwipeLimit - _todaySwipes;
  int get remainingSaves => _dailySaveLimit - _todaySaves;
  int get remainingPlannings => _dailyPlanningLimit - _todayPlannings;

  bool get canSwipe => _todaySwipes < _dailySwipeLimit;
  bool get canSave => _todaySaves < _dailySaveLimit;
  bool get canPlan => _todayPlannings < _dailyPlanningLimit;

  /// Initialize service
  void init() {
    debugPrint('📱 RewardedAdService: Initialized');
    _checkAndResetDailyLimits();
    loadRewardedAd();
  }

  /// Check if daily limits need to be reset
  void _checkAndResetDailyLimits() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      _todaySwipes = 0;
      _todaySaves = 0;
      _todayPlannings = 0;
      _lastResetDate = today;
      debugPrint('📱 RewardedAdService: Daily limits reset');
    }
  }

  /// Load rewarded ad
  Future<void> loadRewardedAd() async {
    if (_isRewardedAdReady) return;

    try {
      await RewardedAd.load(
        adUnitId: 'YOUR_REWARDED_AD_UNIT_ID', // Replace with your ad unit ID
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            debugPrint('✅ Rewarded ad loaded successfully');

            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('📱 Rewarded ad showed full screen');
              },
              onAdDismissedFullScreenContent: (ad) {
                _isRewardedAdReady = false;
                ad.dispose();
                loadRewardedAd(); // Preload next ad
                debugPrint('📱 Rewarded ad dismissed');
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _isRewardedAdReady = false;
                ad.dispose();
                loadRewardedAd(); // Retry loading
                debugPrint('❌ Rewarded ad failed to show: $error');
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ Rewarded ad failed to load: $error');
            _isRewardedAdReady = false;
            // Retry after delay
            Future.delayed(const Duration(minutes: 2), loadRewardedAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error loading rewarded ad: $e');
      _isRewardedAdReady = false;
    }
  }

  /// Show rewarded ad with callback for reward
  Future<void> showRewardedAd({
    required Function() onRewardEarned,
    Function()? onAdFailedToShow,
    Function()? onAdClosed,
  }) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('⚠️ Rewarded ad not ready');
      onAdFailedToShow?.call();
      return;
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('🎁 User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned.call();
        },
      );
    } catch (e) {
      debugPrint('❌ Error showing rewarded ad: $e');
      _isRewardedAdReady = false;
      loadRewardedAd(); // Reload for next time
      onAdFailedToShow?.call();
    }
  }

  /// Show rewarded ad to unlock specific features
  Future<void> showRewardedAdForFeature({
    required String featureType,
    required Function() onRewardEarned,
    Function()? onAdFailedToShow,
    Function()? onAdClosed,
  }) async {
    await showRewardedAd(
      onRewardEarned: () {
        // Grant the specific reward based on feature type
        switch (featureType) {
          case 'unlock_swipes':
            unlockSwipes(25); // Grant 25 additional swipes
            break;
          case 'unlock_saves':
            unlockSaves(5); // Grant 5 additional saves
            break;
          case 'unlock_planning':
            unlockPlannings(2); // Grant 2 additional plannings
            break;
        }
        onRewardEarned.call();
      },
      onAdFailedToShow: onAdFailedToShow,
      onAdClosed: onAdClosed,
    );
  }

  /// Unlock additional swipes through rewarded ad
  void unlockSwipes(int additionalSwipes) {
    _dailySwipeLimit += additionalSwipes;
    debugPrint('🎁 RewardedAdService: Unlocked $additionalSwipes additional swipes (new limit: $_dailySwipeLimit)');
  }

  /// Unlock additional saves through rewarded ad
  void unlockSaves(int additionalSaves) {
    _dailySaveLimit += additionalSaves;
    debugPrint('🎁 RewardedAdService: Unlocked $additionalSaves additional saves (new limit: $_dailySaveLimit)');
  }

  /// Unlock additional plannings through rewarded ad
  void unlockPlannings(int additionalPlannings) {
    _dailyPlanningLimit += additionalPlannings;
    debugPrint('🎁 RewardedAdService: Unlocked $additionalPlannings additional plannings (new limit: $_dailyPlanningLimit)');
  }

  /// Track actions with limits
  bool trackSwipe() {
    _checkAndResetDailyLimits();
    if (!canSwipe) {
      debugPrint('⚠️ RewardedAdService: Daily swipe limit reached (${_todaySwipes}/$_dailySwipeLimit)');
      return false;
    }
    _todaySwipes++;
    debugPrint('📱 RewardedAdService: Swipe tracked (${_todaySwipes}/$_dailySwipeLimit remaining: $remainingSwipes)');
    return true;
  }

  bool trackSave() {
    _checkAndResetDailyLimits();
    if (!canSave) {
      debugPrint('⚠️ RewardedAdService: Daily save limit reached (${_todaySaves}/$_dailySaveLimit)');
      return false;
    }
    _todaySaves++;
    debugPrint('📱 RewardedAdService: Save tracked (${_todaySaves}/$_dailySaveLimit remaining: $remainingSaves)');
    return true;
  }

  bool trackPlanning() {
    _checkAndResetDailyLimits();
    if (!canPlan) {
      debugPrint('⚠️ RewardedAdService: Daily planning limit reached (${_todayPlannings}/$_dailyPlanningLimit)');
      return false;
    }
    _todayPlannings++;
    debugPrint('📱 RewardedAdService: Planning tracked (${_todayPlannings}/$_dailyPlanningLimit remaining: $remainingPlannings)');
    return true;
  }

  /// Smart rewarded ad placement logic
  bool shouldShowRewardedAd(String context) {
    if (!_isRewardedAdReady) return false;

    _checkAndResetDailyLimits();

    switch (context) {
      case 'unlock_swipes':
        return !canSwipe; // Show when swipe limit reached
      case 'unlock_saves':
        return !canSave; // Show when save limit reached
      case 'unlock_planning':
        return !canPlan; // Show when planning limit reached
      case 'low_swipes_warning':
        return remainingSwipes <= 5 && remainingSwipes > 0; // Show warning when close to limit
      case 'low_saves_warning':
        return remainingSaves <= 2 && remainingSaves > 0; // Show warning when close to limit
      case 'low_planning_warning':
        return remainingPlannings <= 1 && remainingPlannings > 0; // Show warning when close to limit
      default:
        return false;
    }
  }
}
```

### **2. UI Implementation Examples**

#### **A. Dialog with Rewarded Ad Option**

```dart
void _showRewardedAdDialog(BuildContext context, RewardedAdService adsService) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('🎁 Unlock More Features'),
        content: const Text(
          'Watch a short video to unlock additional features and continue using the app!',
        ),
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
                featureType: 'unlock_swipes',
                onRewardEarned: () {
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 25 additional swipes unlocked!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                onAdFailedToShow: () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ad not available right now. Try again later.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                onAdClosed: () {
                  // Auto-refresh screen when ad is closed
                  if (context.mounted) {
                    debugPrint('🔄 Auto-refreshing after rewarded ad closed');
                    setState(() {
                      // Force refresh of the UI
                    });
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
```

#### **B. SnackBar with Rewarded Ad Action**

```dart
void _showLowSwipesWarning(BuildContext context, RewardedAdService adsService) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('⚠️ Only ${adsService.remainingSwipes} swipes remaining today'),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'Unlock More',
        textColor: Colors.white,
        onPressed: () {
          adsService.showRewardedAdForFeature(
            featureType: 'unlock_swipes',
            onRewardEarned: () {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 25 additional swipes unlocked!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            onAdFailedToShow: () {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ad not available right now.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            onAdClosed: () {
              // Auto-refresh screen when ad is closed
              if (context.mounted) {
                debugPrint('🔄 Auto-refreshing after rewarded ad closed');
                setState(() {
                  // Force refresh of the UI
                });
              }
            },
          );
        },
      ),
    ),
  );
}
```

#### **C. Button with Rewarded Ad**

```dart
Widget _buildRewardedAdButton(BuildContext context, RewardedAdService adsService) {
  return Consumer<RewardedAdService>(
    builder: (context, adsService, child) {
      if (adsService.shouldShowRewardedAd('unlock_swipes')) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              adsService.showRewardedAd(
                onRewardEarned: () {
                  debugPrint('🎁 Rewarded ad completed - bonus features unlocked');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Bonus features unlocked!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onAdFailedToShow: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ad not available right now.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Watch Ad for More Features'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    },
  );
}
```

### **3. Navigation Flow After Rewarded Ad**

#### **A. Auto-Refresh Pattern**
```dart
onAdClosed: () {
  // Auto-refresh screen when ad is closed
  if (context.mounted) {
    debugPrint('🔄 Auto-refreshing after rewarded ad closed');
    setState(() {
      // Force refresh of the UI
    });
  }
},
```

#### **B. Continue User Flow**
```dart
onRewardEarned: () {
  // Grant the reward
  adsService.unlockSwipes(25);
  
  // Show success message
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 25 additional swipes unlocked!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  // Continue with user's intended action
  _continueUserAction();
},
```

#### **C. Error Handling**
```dart
onAdFailedToShow: () {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ad not available right now. Try again later.'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  // Provide alternative action or fallback
  _provideAlternativeAction();
},
```

### **4. Integration with Provider**

#### **A. Provider Setup**
```dart
// In your main.dart or app initialization
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RewardedAdService()),
        // Other providers...
      ],
      child: MyApp(),
    ),
  );
}
```

#### **B. Usage in Widgets**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final adsService = Provider.of<RewardedAdService>(context);
    
    return Column(
      children: [
        // Your content
        if (adsService.shouldShowRewardedAd('unlock_swipes'))
          ElevatedButton(
            onPressed: () {
              adsService.showRewardedAdForFeature(
                featureType: 'unlock_swipes',
                onRewardEarned: () {
                  // Handle reward
                },
              );
            },
            child: Text('Unlock More (${adsService.remainingSwipes} left)'),
          ),
      ],
    );
  }
}
```

### **5. Key Features of This Implementation**

1. **Daily Limits**: Tracks daily usage and resets automatically
2. **Smart Placement**: Shows ads at optimal moments
3. **Auto-Refresh**: Refreshes UI after ad completion
4. **Error Handling**: Graceful fallbacks when ads fail
5. **User Feedback**: Clear success/error messages
6. **Flexible Rewards**: Different reward types (swipes, saves, planning)
7. **Context-Aware**: Shows ads based on user behavior

### **6. Customization for Your App**

1. **Replace Ad Unit ID**: Update `'YOUR_REWARDED_AD_UNIT_ID'` with your actual ID
2. **Adjust Limits**: Modify `_dailySwipeLimit`, `_dailySaveLimit`, etc.
3. **Custom Rewards**: Add new reward types in the switch statement
4. **UI Styling**: Update colors, text, and layout to match your app
5. **Analytics**: Add tracking for ad performance and user behavior

### **7. Best Practices**

1. **Don't be too aggressive**: Balance revenue with user experience
2. **Provide alternatives**: Always have fallback options when ads fail
3. **Clear messaging**: Users should know what they're getting
4. **Smooth transitions**: Auto-refresh UI after ad completion
5. **Test thoroughly**: Test on real devices with production ads
6. **Monitor performance**: Track ad fill rates and user engagement

This implementation provides a complete, production-ready rewarded ad system that you can adapt for any app! 