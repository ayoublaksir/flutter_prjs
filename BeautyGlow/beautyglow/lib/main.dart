import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'core/responsive/responsive_util.dart';
import 'core/config/ads_config.dart';
import 'data/storage_service.dart';
import 'screens/splash/splash_screen.dart';
import 'core/theme/theme_provider.dart';
import 'services/notification_service.dart';
import 'models/notification_settings.dart';
import 'models/product.dart';
import 'models/settings.dart';
import 'models/user_profile.dart';
import 'models/beauty_data.dart';
import 'models/routine.dart';
import 'models/achievement.dart';
import 'models/beauty_tip.dart';
import 'models/time_of_day_adapter.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'services/ads_service.dart';
import 'services/rewarded_ad_service.dart';
import 'services/routine_service.dart';
import 'services/routine_notification_service.dart';
import 'services/tip_article_counter_service.dart';

Future<void> initGoogleMobileAds() async {
  try {
    await MobileAds.instance.initialize();

    // Get the device ID for testing
    String? deviceId = await MobileAds.instance
        .getRequestConfiguration()
        .then((config) => config.testDeviceIds?.firstOrNull);

    debugPrint('💡 AdMob Test Device ID: $deviceId');

    // Use our AdsConfig for proper test device configuration
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: AdsConfig.testDeviceIds,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        maxAdContentRating: MaxAdContentRating.pg,
      ),
    );

    debugPrint('✅ Mobile ads initialized with test configuration');
    debugPrint('📱 Test device IDs: ${AdsConfig.testDeviceIds}');
  } catch (e) {
    debugPrint('Error initializing mobile ads: $e');
    // Non-critical error, continue without ads
  }
}

Future<void> main() async {
  try {
    debugPrint('🚀 App: Starting initialization');

    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('✓ App: Flutter bindings initialized');

    // Initialize Firebase
    debugPrint('🔥 App: Initializing Firebase');
    await Firebase.initializeApp();
    debugPrint('✓ App: Firebase initialized');

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    debugPrint('✓ App: Screen orientation set');

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    debugPrint('✓ App: System UI style set');

    // Initialize Hive
    debugPrint('⚙️ App: Initializing Hive');
    await Hive.initFlutter();

    // Ensure Hive directory exists
    final appDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDir.path}/hive';
    await Directory(hivePath).create(recursive: true);
    debugPrint('📁 App: Hive directory ensured at $hivePath');

    debugPrint('✓ App: Hive initialized');

    // Register adapters in strict typeId order with verification
    debugPrint('📦 App: Registering adapters in strict order');

    try {
      // TypeId 0: BeautyData
      if (!Hive.isAdapterRegistered(0)) {
        debugPrint('📦 Registering BeautyDataAdapter (typeId: 0)');
        Hive.registerAdapter(BeautyDataAdapter());
      }

      // TypeId 1: UserProfile
      if (!Hive.isAdapterRegistered(1)) {
        debugPrint('📦 Registering UserProfileAdapter (typeId: 1)');
        Hive.registerAdapter(UserProfileAdapter());
      }

      // TypeId 2: Product
      if (!Hive.isAdapterRegistered(2)) {
        debugPrint('📦 Registering ProductAdapter (typeId: 2)');
        Hive.registerAdapter(ProductAdapter());
      }

      // TypeId 3: Routine
      if (!Hive.isAdapterRegistered(3)) {
        debugPrint('📦 Registering RoutineAdapter (typeId: 3)');
        Hive.registerAdapter(RoutineAdapter());
      }

      // TypeId 4: RoutineStep
      if (!Hive.isAdapterRegistered(4)) {
        debugPrint('📦 Registering RoutineStepAdapter (typeId: 4)');
        Hive.registerAdapter(RoutineStepAdapter());
      }

      // TypeId 5: Achievement
      if (!Hive.isAdapterRegistered(5)) {
        debugPrint('📦 Registering AchievementAdapter (typeId: 5)');
        Hive.registerAdapter(AchievementAdapter());
      }

      // TypeId 6: Settings
      if (!Hive.isAdapterRegistered(6)) {
        debugPrint('📦 Registering SettingsAdapter (typeId: 6)');
        Hive.registerAdapter(SettingsAdapter());
      }

      // TypeId 7: NotificationSettings
      if (!Hive.isAdapterRegistered(7)) {
        debugPrint('📦 Registering NotificationSettingsAdapter (typeId: 7)');
        Hive.registerAdapter(NotificationSettingsAdapter());
      }

      // TypeId 8: BeautyTip
      if (!Hive.isAdapterRegistered(8)) {
        debugPrint('📦 Registering BeautyTipAdapter (typeId: 8)');
        Hive.registerAdapter(BeautyTipAdapter());
      }

      // TypeId 9: TimeOfDay (for routine reminders)
      if (!Hive.isAdapterRegistered(9)) {
        debugPrint('📦 Registering TimeOfDayAdapter (typeId: 9)');
        Hive.registerAdapter(TimeOfDayAdapter());
      }

      // Verify all adapters are registered
      debugPrint('🔍 Verifying adapter registration');
      final requiredTypeIds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
      for (var typeId in requiredTypeIds) {
        if (!Hive.isAdapterRegistered(typeId)) {
          throw StateError(
              'Required adapter with typeId $typeId is not registered');
        }
      }

      debugPrint('✅ App: All Hive adapters registered and verified');

      // Create service instances
      debugPrint('⚙️ App: Creating service instances');
      final storageService = StorageService();
      final notificationService = NotificationService.instance;
      final adsService = AdsService();
      final rewardedAdService = RewardedAdService();
      final routineService = RoutineService();
      final routineNotificationService = RoutineNotificationService.instance;
      final tipArticleCounterService = TipArticleCounterService();
      debugPrint('✓ App: Service instances created');

      // Initialize services with proper error handling and sequential initialization
      debugPrint('⚙️ App: Initializing services sequentially');

      // Initialize Firebase-based AdsService first
      await adsService.init();
      debugPrint('✅ App: AdsService initialized');

      // Initialize RewardedAdService
      try {
        debugPrint('⚙️ App: Initializing RewardedAdService');
        rewardedAdService.init();
        debugPrint('✅ App: RewardedAdService initialized');
      } catch (e) {
        debugPrint('❌ App: RewardedAdService initialization failed: $e');
      }

      // Initialize StorageService second
      try {
        debugPrint('⚙️ App: Initializing StorageService');
        await storageService.init();
        debugPrint('✅ App: StorageService initialized');

        // Debug user existence
        final hasUser = storageService.hasUser();
        debugPrint('🔍 App: User exists: $hasUser');
        if (hasUser) {
          final currentUser = storageService.getCurrentUserData();
          debugPrint('🔍 App: Current user: ${currentUser?.userProfile.name}');
        }
      } catch (e) {
        debugPrint('❌ App: StorageService initialization failed: $e');
        // Try once more with a delay
        debugPrint('🔄 App: Retrying StorageService initialization');
        await Future.delayed(const Duration(milliseconds: 500));
        await storageService.init();
        debugPrint('✅ App: StorageService initialized on retry');
      }

      // Initialize NotificationService third
      try {
        debugPrint('⚙️ App: Initializing NotificationService');
        await notificationService.init();
        debugPrint('✅ App: NotificationService initialized');

        // Show current device time for verification
        final currentTime = DateTime.now();
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📱 DEVICE TIME CHECK:');
        print('🕐 Current device time: ${currentTime.toString()}');
        print(
            '⏰ Current time: ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}:${currentTime.second.toString().padLeft(2, '0')}');
        print(
            '📅 Today is: ${currentTime.day}/${currentTime.month}/${currentTime.year}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Always set up the daily notification (works even when app is closed)
        print(
            '📅 Setting up daily reminders for ${NotificationService.getFormattedReminderTime()}...');
        await NotificationService.instance.setupDailyNotificationAlways();
        print(
            '🔔 Daily notifications ready! Will remind you at ${NotificationService.getFormattedReminderTime()} every day');
        print('📱 Notifications will work even when the app is closed');
        print('');
        print(
            '🎯 WHEN DEVICE TIME MATCHES ${NotificationService.getFormattedReminderTime()}, YOU WILL SEE:');
        print('   🔔 Notification appears on your device');
        print('   📱 Console logs showing notification fired');
        print('   ✅ Confirmation that the system is working');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      } catch (e) {
        debugPrint('❌ App: NotificationService initialization failed: $e');
        // Try once more with a delay
        debugPrint('🔄 App: Retrying NotificationService initialization');
        await Future.delayed(const Duration(milliseconds: 500));
        await notificationService.init();
        debugPrint('✅ App: NotificationService initialized on retry');
      }

      // Initialize RoutineService
      try {
        debugPrint('⚙️ App: Initializing RoutineService');
        await routineService.init();
        debugPrint('✅ App: RoutineService initialized');
      } catch (e) {
        debugPrint('❌ App: RoutineService initialization failed: $e');
      }

      // Initialize RoutineNotificationService
      try {
        debugPrint('⚙️ App: Initializing RoutineNotificationService');
        await routineNotificationService.init();
        debugPrint('✅ App: RoutineNotificationService initialized');
      } catch (e) {
        debugPrint(
            '❌ App: RoutineNotificationService initialization failed: $e');
      }

      // Initialize TipArticleCounterService
      try {
        debugPrint('⚙️ App: Initializing TipArticleCounterService');
        await tipArticleCounterService.initialize();
        debugPrint('✅ App: TipArticleCounterService initialized');
      } catch (e) {
        debugPrint('❌ App: TipArticleCounterService initialization failed: $e');
      }

      debugPrint('✅ App: All services initialized successfully');

      // Initialize Google Mobile Ads first
      debugPrint('📱 App: Initializing Google Mobile Ads');
      await initGoogleMobileAds();
      debugPrint('✅ App: Google Mobile Ads initialized');

      // Initialize AdService after Google Mobile Ads
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<AdsService>.value(value: adsService),
            ChangeNotifierProvider<RewardedAdService>.value(
                value: rewardedAdService),
            ChangeNotifierProvider<RoutineService>.value(value: routineService),
            ChangeNotifierProvider<TipArticleCounterService>.value(
                value: tipArticleCounterService),
            Provider<StorageService>.value(value: storageService),
            Provider<NotificationService>.value(value: notificationService),
            Provider<RoutineNotificationService>.value(
                value: routineNotificationService),
          ],
          child: const BeautyGlowApp(),
        ),
      );
      debugPrint('✅ App: Application started successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ App: Error during initialization:');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());

      // Show error UI with retry option
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Failed to start the app',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${e.toString()}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        // Clean up Hive boxes before retrying
                        final boxNames = [
                          'users',
                          'routines',
                          'products',
                          'app_settings',
                          'notification_settings',
                          'beauty_data',
                        ];
                        for (final boxName in boxNames) {
                          try {
                            if (await Hive.boxExists(boxName)) {
                              await Hive.deleteBoxFromDisk(boxName);
                            }
                          } catch (e) {
                            debugPrint(
                                'Non-fatal error deleting box $boxName: $e');
                          }
                        }
                        main();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  } catch (e, stackTrace) {
    debugPrint('❌ App: Fatal error during initialization:');
    debugPrint(e.toString());
    debugPrint(stackTrace.toString());
    // Show error UI
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Failed to start the app',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => main(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Main application widget
class BeautyGlowApp extends StatelessWidget {
  const BeautyGlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeautyGlow',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      builder: (context, child) {
        // Initialize responsive utility here where MediaQuery is guaranteed to be available
        ResponsiveUtil().init(context);
        return child ?? const SizedBox();
      },
      home: const SplashScreen(),
    );
  }

  /// Build the app theme
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPink,
        primary: AppColors.primaryPink,
        secondary: AppColors.primaryPurple,
        surface: Colors.white,
        background: AppColors.backgroundLight,
        error: AppColors.errorRed,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headingSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primaryPink,
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          textStyle: AppTypography.buttonText,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          textStyle: AppTypography.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          side: const BorderSide(color: AppColors.primaryPink, width: 2),
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.dividerGray,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.dividerGray,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryPink,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: 2,
          ),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary.withOpacity(0.5),
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTypography.headingSmall,
        contentTextStyle: AppTypography.bodyLarge,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.softRose,
        selectedColor: AppColors.primaryPink,
        disabledColor: Colors.grey[300]!,
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: AppColors.dividerGray,
        thickness: 1,
        space: 16,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryPink,
        linearTrackColor: AppColors.softRose,
      ),
    );
  }
}
