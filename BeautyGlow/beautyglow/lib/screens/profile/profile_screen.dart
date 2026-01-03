import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';
import '../../data/storage_service.dart';
import '../../models/beauty_data.dart';
import '../../models/notification_settings.dart';
import '../../utils/date_util.dart';
import '../../services/notification_service.dart';
import '../../services/ads_service.dart';
import '../../core/config/ads_config.dart';
import '../../screens/profile/edit_profile_screen.dart';

import '../settings/privacy_policy_screen.dart';
import '../settings/terms_of_service_screen.dart';

/// User profile screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService.instance;
  BeautyData? _userData;
  bool _notificationsEnabled = true;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  bool _hasInitializedAd = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationState();
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
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    // Check if ads are enabled in Firebase Remote Config
    if (!AdsConfig.isAdsEnabled || !AdsConfig.isBannerAdsEnabled) {
      debugPrint(
          '🚫 ProfileScreen: Banner ads disabled in Firebase, skipping load');
      return;
    }

    final adService = Provider.of<AdsService>(context, listen: false);
    adService.loadBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (ad) {
        setState(() {
          _bannerAd = ad as BannerAd;
          _isBannerAdReady = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('Banner ad failed to load: $error');
      },
    );
  }

  Future<void> _loadNotificationState() async {
    final settings = await _notificationService.getSettings();
    setState(() {
      _notificationsEnabled = settings.enabled;
    });
  }

  void _loadUserData() {
    setState(() {
      _userData = _storageService.getCurrentUserData(refresh: true);
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _userData = _storageService.getCurrentUserData(refresh: true);
    });
    await _loadNotificationState();
    // Show refresh indicator for at least 500ms for better UX
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      // Request notification permission first if enabling
      if (value) {
        final hasPermission = await _notificationService.requestPermission();
        if (!hasPermission) {
          throw Exception('Notification permission denied');
        }
      }

      // Try to toggle notification
      await _notificationService.toggleRoutineReminder(value);

      setState(() {
        _notificationsEnabled = value;
        if (_userData != null) {
          _userData!.settings.updateSettings(routineReminders: value);
          _storageService.saveUserData(_userData!);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Routine reminders enabled'
                : 'Routine reminders disabled'),
            backgroundColor:
                value ? AppColors.successGreen : AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      // If there's an error, revert the switch state
      setState(() {
        _notificationsEnabled = !value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to ${value ? 'enable' : 'disable'} notifications. ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primaryPink,
        child: CustomScrollView(
          slivers: [
            // Profile header
            SliverToBoxAdapter(
              child: _buildProfileHeader(),
            ),

            // Content
            SliverPadding(
              padding: EdgeInsets.all(
                ResponsiveUtil.instance
                    .proportionateWidth(AppDimensions.paddingMedium),
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsSection(),
                  SizedBox(
                      height: ResponsiveUtil.instance.proportionateHeight(24)),
                  _buildAchievementsSection(),
                  SizedBox(
                      height: ResponsiveUtil.instance.proportionateHeight(24)),
                  _buildSettingsSection(),
                  SizedBox(
                      height: ResponsiveUtil.instance.proportionateHeight(16)),
                  // Banner Ad - only show if enabled in Firebase and ready
                  if (AdsConfig.isAdsEnabled &&
                      AdsConfig.isBannerAdsEnabled &&
                      _isBannerAdReady &&
                      _bannerAd != null)
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtil.instance.proportionateWidth(16),
                        vertical:
                            ResponsiveUtil.instance.proportionateHeight(8),
                      ),
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _userData!.userProfile;

    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtil.instance.proportionateWidth(AppDimensions.paddingLarge),
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Profile picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                profile.initials,
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.primaryPink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ).animate().scale(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
              ),

          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

          // Name
          Text(
            profile.displayName,
            style: AppTypography.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(4)),

          // Member since
          Text(
            'Member for ${profile.memberDuration}',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

          // Edit profile button
          TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    userData: _userData!,
                  ),
                ),
              );
              if (result == true) {
                _loadUserData();
              }
            },
            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
            label: Text(
              'Edit Profile',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtil.instance.proportionateWidth(16),
                vertical: ResponsiveUtil.instance.proportionateHeight(8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 400))
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = [
      {
        'label': 'Current Streak',
        'value': '${_userData!.streakDays}',
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.orange,
      },
      {
        'label': 'Total Routines',
        'value': '${_userData!.totalCompletions}',
        'icon': Icons.check_circle_rounded,
        'color': AppColors.successGreen,
      },
      {
        'label': 'Products',
        'value': '${_userData!.favoriteProducts.length}',
        'icon': Icons.shopping_bag_rounded,
        'color': AppColors.primaryPurple,
      },
      {
        'label': 'Achievements',
        'value': '${_userData!.unlockedAchievements.length}',
        'icon': Icons.emoji_events_rounded,
        'color': AppColors.accentGold,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Statistics',
          style: AppTypography.headingSmall,
        ),
        SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: ResponsiveUtil.instance.proportionateWidth(12),
          mainAxisSpacing: ResponsiveUtil.instance.proportionateHeight(12),
          childAspectRatio: 1.3,
          children: stats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtil.instance.proportionateWidth(12),
                vertical: ResponsiveUtil.instance.proportionateHeight(8),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColorLight,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 28,
                  ),
                  SizedBox(
                      height: ResponsiveUtil.instance.proportionateHeight(4)),
                  Text(
                    stat['value'] as String,
                    style: AppTypography.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat['label'] as String,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 * index))
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: const Duration(milliseconds: 300),
                );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    final unlockedAchievements =
        _userData!.unlockedAchievements.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Achievements',
              style: AppTypography.headingSmall,
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all achievements
              },
              child: Text(
                'View All',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryPink,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
        if (unlockedAchievements.isEmpty) ...[
          Container(
            padding: EdgeInsets.all(
              ResponsiveUtil.instance
                  .proportionateWidth(AppDimensions.paddingLarge),
            ),
            decoration: BoxDecoration(
              color: AppColors.softRose,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Center(
              child: Text(
                'No achievements unlocked yet',
                style: AppTypography.bodyMedium,
              ),
            ),
          ),
        ] else ...[
          ...unlockedAchievements.asMap().entries.map((entry) {
            final index = entry.key;
            final achievement = entry.value;

            return Container(
              margin: EdgeInsets.only(
                bottom: ResponsiveUtil.instance.proportionateHeight(12),
              ),
              padding: EdgeInsets.all(
                ResponsiveUtil.instance
                    .proportionateWidth(AppDimensions.paddingMedium),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColorLight,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Achievement icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.achievementGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(
                      width: ResponsiveUtil.instance.proportionateWidth(12)),

                  // Achievement info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Unlocked ${DateUtil.getRelativeTime(achievement.unlockedDate!)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 * index))
                .slideX(begin: 0.1, end: 0);
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildSettingsSection() {
    final settingsItems = [
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifications',
        'subtitle': 'Manage reminders',
        'onTap': () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Notification Settings',
                style: AppTypography.headingSmall,
              ),
              content: StatefulBuilder(
                builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Beauty Routine Reminders',
                        style: AppTypography.labelLarge,
                      ),
                      subtitle: Text(
                        'Daily notifications for routines',
                        style: AppTypography.bodySmall,
                      ),
                      value: _notificationsEnabled,
                      onChanged: (value) async {
                        try {
                          await _notificationService
                              .toggleRoutineReminder(value);
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Failed to update notification settings'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                        }
                      },
                    ),
                    if (_notificationsEnabled) ...[
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.access_time,
                            color: AppColors.primaryPink),
                        title: Text(
                          'Reminder Time',
                          style: AppTypography.labelLarge,
                        ),
                        subtitle: FutureBuilder<NotificationSettings>(
                          future: _notificationService.getSettings(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Text('Loading...');
                            }
                            final settings = snapshot.data!;
                            return Text(
                              '${settings.hour.toString().padLeft(2, '0')}:${settings.minute.toString().padLeft(2, '0')}',
                              style: AppTypography.bodySmall,
                            );
                          },
                        ),
                        onTap: () async {
                          final settings =
                              await _notificationService.getSettings();
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: settings.hour,
                              minute: settings.minute,
                            ),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppColors.primaryPink,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: AppColors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (picked != null) {
                            try {
                              await _notificationService.updateNotificationTime(
                                picked.hour,
                                picked.minute,
                              );
                              setState(() {}); // Refresh dialog
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reminder time updated'),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to update reminder time: ${e.toString()}'),
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Tap to change reminder time',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'title': 'Privacy Policy',
        'subtitle': 'How we protect your data',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen()),
          );
        },
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Terms of Service',
        'subtitle': 'Terms and conditions',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const TermsOfServiceScreen()),
          );
        },
      },
      {
        'icon': Icons.info_outline,
        'title': 'About',
        'subtitle': 'App information',
        'onTap': () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'About BeautyGlow',
                style: AppTypography.headingSmall,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.spa_rounded,
                    size: 48,
                    color: AppColors.primaryPink,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BeautyGlow',
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your personal beauty routine companion',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: AppTypography.headingSmall,
        ),
        SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
        ...settingsItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Container(
            margin: EdgeInsets.only(
              bottom: ResponsiveUtil.instance.proportionateHeight(8),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColorLight,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(
                item['icon'] as IconData,
                color: AppColors.primaryPink,
              ),
              title: Text(
                item['title'] as String,
                style: AppTypography.labelLarge,
              ),
              subtitle: Text(
                item['subtitle'] as String,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: item['onTap'] as VoidCallback,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
        }).toList(),
      ],
    );
  }
}
