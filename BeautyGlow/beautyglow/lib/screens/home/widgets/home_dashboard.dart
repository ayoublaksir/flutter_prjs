import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/responsive/responsive_util.dart';
import '../../../data/storage_service.dart';
import '../../../models/beauty_data.dart';
import '../../../utils/date_util.dart';
import '../../../widgets/buttons/custom_button.dart';
import '../../../services/ads_service.dart';
import '../../routines/execute_routine_screen.dart';
import '../../../data/beauty_quotes.dart';
import '../home_screen.dart';

/// Home dashboard displaying user stats and quick actions
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final StorageService _storageService = StorageService();
  BeautyData? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (mounted) {
      setState(() {
        _userData = _storageService.getCurrentUserData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // Decorative Top Header with Curved Background Image
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipPath(
            clipper: _TopCurveClipper(),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPink.withOpacity(0.7),
                    AppColors.primaryPurple.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/home_background.jpg',
                      fit: BoxFit.cover,
                      color: Colors.white.withOpacity(0.7),
                      colorBlendMode: BlendMode.modulate,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Main Content
        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Quote Section
                  SizedBox(height: 16),

                  const SizedBox(height: 80),
                  // Quote Card
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryPink.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          size: 36,
                          color: AppColors.primaryPink.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          BeautyQuotes.getRandomQuote(),
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            letterSpacing: 0.5,
                            color: AppColors.textPrimary,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 1000.ms).scale(),
                  // Quick Actions Grid (Modern, Feminine)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.05,
                      children: [
                        _buildQuickActionCard(
                          context: context,
                          title: 'Today\'s\nRoutine',
                          icon: Icons.spa_rounded,
                          color: const Color(0xFFE91E63), // Soft Pink
                          delay: 0,
                        ),
                        _buildQuickActionCard(
                          context: context,
                          title: 'My\nProducts',
                          icon: Icons.shopping_bag_rounded,
                          color: const Color(0xFF9C27B0), // Elegant Purple
                          delay: 200,
                        ),
                        _buildQuickActionCard(
                          context: context,
                          title: 'Track\nProgress',
                          icon: Icons.favorite_rounded,
                          color: const Color(0xFFF06292), // Light Rose
                          delay: 400,
                        ),
                        _buildQuickActionCard(
                          context: context,
                          title: 'Beauty\nTips',
                          icon: Icons.lightbulb_rounded,
                          color: const Color(0xFFBA68C8), // Soft Lavender
                          delay: 600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            // Handle navigation based on card title
            switch (title) {
              case 'Today\'s\nRoutine':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(initialIndex: 1),
                  ),
                );
                break;
              case 'My\nProducts':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(initialIndex: 2),
                  ),
                );
                break;
              case 'Track\nProgress':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(initialIndex: 4),
                  ),
                );
                break;
              case 'Beauty\nTips':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(initialIndex: 3),
                  ),
                );
                break;
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 800.ms,
        )
        .slideY(
          begin: 0.2,
          delay: Duration(milliseconds: delay),
          duration: 800.ms,
        );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtil.instance.proportionateWidth(AppDimensions.paddingLarge),
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Streak icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtil.instance.proportionateWidth(16)),

          // Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Streak',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  DateUtil.getStreakText(_userData!.streakDays),
                  style: AppTypography.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickStats() {
    final stats = [
      {
        'icon': Icons.event_available,
        'value': _userData!.totalCompletions.toString(),
        'label': 'Routines Done',
      },
      {
        'icon': Icons.shopping_bag,
        'value': _userData!.favoriteProducts.length.toString(),
        'label': 'Products',
      },
      {
        'icon': Icons.emoji_events,
        'value': _userData!.unlockedAchievements.length.toString(),
        'label': 'Achievements',
      },
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtil.instance.proportionateWidth(4),
            ),
            padding: EdgeInsets.all(
              ResponsiveUtil.instance.proportionateWidth(12),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  color: AppColors.primaryPink,
                  size: 24,
                ),
                SizedBox(
                    height: ResponsiveUtil.instance.proportionateHeight(4)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    stat['value'] as String,
                    style: AppTypography.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                    height: ResponsiveUtil.instance.proportionateHeight(2)),
                Text(
                  stat['label'] as String,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 100 * index))
              .slideY(begin: 0.1, end: 0),
        );
      }).toList(),
    );
  }

  Widget _buildTodayRoutines() {
    final activeRoutines = _userData!.activeRoutines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Routines',
              style: AppTypography.headingSmall,
            ),
            TextButton(
              onPressed: () {
                // Navigate to routines tab
                // This will be handled by parent
              },
              child: Text(
                'See All',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryPink,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),
        if (activeRoutines.isEmpty) ...[
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
              child: Column(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primaryPink,
                    size: 48,
                  ),
                  SizedBox(
                      height: ResponsiveUtil.instance.proportionateHeight(8)),
                  Text(
                    'No routines yet',
                    style: AppTypography.bodyMedium,
                  ),
                  Text(
                    'Create your first beauty routine',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Show routine cards
          ...activeRoutines.take(2).map((routine) {
            final isCompleted = routine.isCompletedToday;

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
                border: Border.all(
                  color: isCompleted
                      ? AppColors.successGreen
                      : AppColors.dividerGray,
                  width: 1,
                ),
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
                  // Routine icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: routine.timeOfDay == 'morning'
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      routine.timeOfDay == 'morning'
                          ? Icons.wb_sunny
                          : Icons.nightlight_round,
                      color: routine.timeOfDay == 'morning'
                          ? Colors.orange
                          : Colors.blue,
                    ),
                  ),
                  SizedBox(
                      width: ResponsiveUtil.instance.proportionateWidth(12)),

                  // Routine info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          '${routine.steps.length} steps • ${routine.formattedDuration}',
                          style: AppTypography.bodySmall.copyWith(
                            color: isCompleted
                                ? AppColors.textSecondary.withOpacity(0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action
                  if (isCompleted) ...[
                    Icon(
                      Icons.check_circle,
                      color: AppColors.successGreen,
                    ),
                  ] else ...[
                    CustomButton(
                      text: 'Start',
                      size: ButtonSize.small,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ExecuteRoutineScreen(routine: routine),
                          ),
                        );
                        if (result == true) {
                          _loadUserData();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn().slideX(begin: 0.1, end: 0);
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildRecentProducts() {
    final recentProducts = _userData!.favoriteProducts.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Products',
              style: AppTypography.headingSmall,
            ),
            TextButton(
              onPressed: () {
                // Navigate to products tab
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
        SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),
        if (recentProducts.isEmpty) ...[
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
              child: Column(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primaryPink,
                    size: 48,
                  ),
                  SizedBox(
                      height: ResponsiveUtil.instance.proportionateHeight(8)),
                  Text(
                    'No products added yet',
                    style: AppTypography.bodyMedium,
                  ),
                  Text(
                    'Tap to add your first product',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Product grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: ResponsiveUtil.instance.proportionateWidth(12),
              mainAxisSpacing: ResponsiveUtil.instance.proportionateHeight(12),
              childAspectRatio: 1.0,
            ),
            itemCount: recentProducts.length,
            itemBuilder: (context, index) {
              final product = recentProducts[index];

              return Container(
                padding: EdgeInsets.all(
                  ResponsiveUtil.instance.proportionateWidth(8),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColorLight,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 28,
                      color: AppColors.primaryPink,
                    ),
                    SizedBox(
                        height: ResponsiveUtil.instance.proportionateHeight(4)),
                    Flexible(
                      child: Text(
                        product.name,
                        style: AppTypography.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                        height: ResponsiveUtil.instance.proportionateHeight(2)),
                    Text(
                      product.brand,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 100 * index))
                  .scale(
                      begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAchievementProgress() {
    final unlockedCount = _userData!.unlockedAchievements.length;
    final totalCount = _userData!.achievements.length;
    final progress = _userData!.achievementProgress;

    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtil.instance.proportionateWidth(AppDimensions.paddingLarge),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: AppTypography.headingSmall,
              ),
              Text(
                '$unlockedCount / $totalCount',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryPink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),

          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.dividerGray,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),

          Text(
            'Keep going! You\'re ${(progress * 100).toInt()}% there',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

// Add a custom clipper for the top curve
class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
