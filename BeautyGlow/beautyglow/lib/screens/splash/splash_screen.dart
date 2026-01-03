import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_images.dart';
import '../../core/constants/app_typography.dart';
import '../../data/storage_service.dart';
import '../../services/notification_service.dart';
import '../../utils/animation_util.dart';
import '../onboarding/welcome_screen.dart';
import '../home/home_screen.dart';

/// Splash screen shown on app launch
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Simulate loading time for splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      // Check if user exists
      final hasUser = _storageService.hasUser();

      debugPrint('🔍 SplashScreen: User exists: $hasUser');

      if (hasUser) {
        final currentUser = _storageService.getCurrentUserData();
        debugPrint(
            '🔍 SplashScreen: Current user: ${currentUser?.userProfile.name}');
      }

      // Request notification permission by default for all users
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      try {
        debugPrint(
            '🔔 SplashScreen: Requesting notification permission by default');
        final hasPermission = await notificationService.requestPermission();

        if (hasPermission) {
          debugPrint(
              '✅ SplashScreen: Notification permission granted, enabling daily reminders');
          // Automatically enable notifications if permission was granted
          await notificationService.toggleRoutineReminder(true);
        } else {
          debugPrint('❌ SplashScreen: Notification permission denied');
        }
      } catch (e) {
        debugPrint(
            '❌ SplashScreen: Error requesting notification permission: $e');
      }

      // Navigate to appropriate screen
      final targetScreen = hasUser ? const HomeScreen() : const WelcomeScreen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      debugPrint('❌ SplashScreen: Error checking user status: $e');
      // On error, go to welcome screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/beautybglow-icon.jpg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(),

                const SizedBox(height: 32),

                // App name
                Text(
                  'BeautyGlow',
                  style: AppTypography.headingLarge.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 300))
                    .slideY(
                      begin: 0.5,
                      end: 0,
                      duration: const Duration(milliseconds: 500),
                    ),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Your Beauty Journey Starts Here',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 500))
                    .slideY(
                      begin: 0.5,
                      end: 0,
                      duration: const Duration(milliseconds: 500),
                    ),

                const SizedBox(height: 48),

                // Loading indicator
                SizedBox(
                  height: 40,
                  child: AnimationUtil.loadingDots(
                    color: Colors.white,
                    size: 12,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
