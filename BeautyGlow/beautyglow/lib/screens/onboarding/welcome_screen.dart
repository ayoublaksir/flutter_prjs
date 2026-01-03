import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../core/navigation/navigation_manager.dart';
import '../../data/storage_service.dart';
import '../../services/notification_service.dart';
import '../../utils/validation_util.dart';
import '../home/home_screen.dart';

/// Welcome screen for first-time users
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  int _currentPage = 0;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _initError;
  String _selectedSkinType = 'normal';
  List<String> _selectedConcerns = [];
  String _selectedRoutineTime = 'both';

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 WelcomeScreen: initState called');
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    debugPrint('🚀 WelcomeScreen: Starting services initialization');
    try {
      setState(() {
        _isInitializing = true;
        _initError = null;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ WelcomeScreen: Error during initialization: $e');
      debugPrint(stackTrace.toString());
      if (mounted) {
        setState(() {
          _initError = 'Failed to initialize services. Please restart the app.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(
          '🔄 WelcomeScreen: Creating new user with name: ${_nameController.text.trim()}');

      // Create new user with all profile information
      await _storageService.createNewUser(
        name: _nameController.text.trim(),
        skinType: _selectedSkinType,
        skinConcerns: _selectedConcerns,
        preferredRoutineTime: _selectedRoutineTime,
      );

      debugPrint('✅ WelcomeScreen: User created successfully');

      if (!mounted) return;

      // Verify user was created
      final hasUser = _storageService.hasUser();
      debugPrint('🔍 WelcomeScreen: User exists after creation: $hasUser');

      // Request notification permission by default for new users
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      try {
        debugPrint(
            '🔔 WelcomeScreen: Requesting notification permission by default');
        final hasPermission = await notificationService.requestPermission();

        if (hasPermission) {
          debugPrint(
              '✅ WelcomeScreen: Notification permission granted, enabling daily reminders');
          // Automatically enable notifications if permission was granted
          await notificationService.toggleRoutineReminder(true);
        } else {
          debugPrint('❌ WelcomeScreen: Notification permission denied');
        }
      } catch (e) {
        debugPrint(
            '❌ WelcomeScreen: Error requesting notification permission: $e');
      }

      // Navigate to home screen
      NavigationManager.pushAndRemoveUntil(
        context,
        const HomeScreen(),
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ WelcomeScreen: Error creating profile: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating profile: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading or error state
    if (_isInitializing || _initError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: _initError != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.errorRed,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _initError!,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.errorRed,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Retry',
                        onPressed: _initializeServices,
                        isFullWidth: false,
                      ),
                    ],
                  )
                : const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPink,
                    ),
                  ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              margin: EdgeInsets.all(
                ResponsiveUtil.instance
                    .proportionateWidth(AppDimensions.paddingMedium),
              ),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtil.instance.proportionateWidth(4),
                      ),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppColors.primaryPink
                            : AppColors.dividerGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                        .animate(
                          target: index <= _currentPage ? 1 : 0,
                        )
                        .scaleX(
                          begin: 0.8,
                          end: 1,
                          duration: const Duration(milliseconds: 300),
                        ),
                  );
                }),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildBenefitsPage(),
                  _buildProfilePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: EdgeInsets.all(
        ResponsiveUtil.instance.proportionateWidth(AppDimensions.paddingLarge),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Welcome icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: Colors.white,
              size: 50,
            ),
          )
              .animate()
              .scale(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
              )
              .fadeIn(),

          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(32)),

          // Welcome text
          Text(
            'Welcome to BeautyGlow',
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 200))
              .slideY(begin: 0.2, end: 0),

          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

          Text(
            'Your personal beauty companion for tracking routines, managing products, and achieving your beauty goals',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 400))
              .slideY(begin: 0.2, end: 0),

          const Spacer(),

          // Next button
          CustomButton(
            text: 'Get Started',
            onPressed: _nextPage,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsPage() {
    final benefits = [
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'Track Your Routines',
        'description': 'Never miss your morning or evening beauty routine',
      },
      {
        'icon': Icons.shopping_bag_rounded,
        'title': 'Manage Products',
        'description': 'Keep track of your favorite beauty products',
      },
      {
        'icon': Icons.emoji_events_rounded,
        'title': 'Earn Achievements',
        'description': 'Stay motivated with streaks and rewards',
      },
      {
        'icon': Icons.lightbulb_rounded,
        'title': 'Beauty Tips',
        'description': 'Discover new tips and techniques',
      },
    ];

    return Padding(
      padding: EdgeInsets.all(
        ResponsiveUtil.instance.proportionateWidth(AppDimensions.paddingLarge),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Why BeautyGlow?',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(32)),
          ...benefits.asMap().entries.map((entry) {
            final index = entry.key;
            final benefit = entry.value;

            return Container(
              margin: EdgeInsets.only(
                bottom: ResponsiveUtil.instance.proportionateHeight(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      benefit['icon'] as IconData,
                      color: AppColors.primaryPink,
                      size: 24,
                    ),
                  ),
                  SizedBox(
                      width: ResponsiveUtil.instance.proportionateWidth(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefit['title'] as String,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          benefit['description'] as String,
                          style: AppTypography.bodySmall.copyWith(
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
                .fadeIn(
                  delay: Duration(milliseconds: 200 + (index * 100)),
                )
                .slideX(begin: 0.2, end: 0);
          }).toList(),
          const Spacer(),
          CustomButton(
            text: 'Continue',
            onPressed: _nextPage,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: EdgeInsets.all(
        ResponsiveUtil.instance.proportionateWidth(AppDimensions.paddingLarge),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let\'s Get to Know You',
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),

              Text(
                'Tell us about yourself so we can personalize your experience',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 200))
                  .slideY(begin: 0.2, end: 0),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(32)),

              // Name input
              TextFormField(
                controller: _nameController,
                validator: ValidationUtil.validateName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'Enter your name',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 400))
                  .slideY(begin: 0.2, end: 0),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Skin Type Selection
              Text(
                'What\'s your skin type?',
                style: AppTypography.labelLarge,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),
              DropdownButtonFormField<String>(
                value: _selectedSkinType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.face_outlined),
                ),
                items: [
                  'Normal',
                  'Dry',
                  'Oily',
                  'Combination',
                  'Sensitive',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value.toLowerCase(),
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSkinType = newValue ?? 'normal';
                  });
                },
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 500))
                  .slideY(begin: 0.2, end: 0),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Skin Concerns
              Text(
                'What are your skin concerns?',
                style: AppTypography.labelLarge,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Acne',
                  'Aging',
                  'Dark Spots',
                  'Dryness',
                  'Dullness',
                  'Fine Lines',
                  'Pores',
                  'Redness',
                ].map((concern) {
                  final isSelected =
                      _selectedConcerns.contains(concern.toLowerCase());
                  return FilterChip(
                    label: Text(concern),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedConcerns.add(concern.toLowerCase());
                        } else {
                          _selectedConcerns.remove(concern.toLowerCase());
                        }
                      });
                    },
                    selectedColor: AppColors.primaryPink.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryPink,
                  );
                }).toList(),
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 600))
                  .slideY(begin: 0.2, end: 0),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Preferred Routine Time
              Text(
                'When do you prefer to do your routine?',
                style: AppTypography.labelLarge,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),
              DropdownButtonFormField<String>(
                value: _selectedRoutineTime,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                items: [
                  'Morning',
                  'Evening',
                  'Both',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value.toLowerCase(),
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRoutineTime = newValue ?? 'both';
                  });
                },
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 700))
                  .slideY(begin: 0.2, end: 0),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(32)),

              CustomButton(
                text: 'Start My Journey',
                onPressed: _completeOnboarding,
                isFullWidth: true,
                isLoading: _isLoading,
              ),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
            ],
          ),
        ),
      ),
    );
  }
}
