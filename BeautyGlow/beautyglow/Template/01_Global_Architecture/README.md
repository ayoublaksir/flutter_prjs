# 🏛️ Global App Architecture - Complete Setup Guide

## ✅ Purpose
Establish the foundational architecture for a production-ready Flutter app with clean code organization, dependency injection, theming, and responsive design setup.

## 🧠 Architecture Overview

### Folder Structure
```
lib/
├── main.dart                         # App entry point with complete initialization
├── core/                            # Core application infrastructure
│   ├── constants/                   # App-wide constants
│   │   ├── app_colors.dart         # Color palette and theming colors
│   │   ├── app_typography.dart     # Text styles and typography system
│   │   ├── app_dimensions.dart     # Spacing, sizes, and layout dimensions
│   │   └── app_images.dart         # Image asset constants
│   ├── theme/                      # Theme configuration
│   │   └── theme_provider.dart     # App theme state management
│   ├── responsive/                 # Responsive design utilities
│   │   └── responsive_util.dart    # Screen size and layout utilities
│   ├── navigation/                 # Navigation system
│   │   ├── navigation_manager.dart # Navigation state and logic
│   │   ├── custom_routes.dart      # Route definitions and transitions
│   │   └── nav_items.dart          # Navigation item configurations
│   └── config/                     # Configuration files
│       └── ads_config.dart         # Advertisement configuration
├── services/                       # Business logic and external services
├── screens/                        # Application screens/pages
├── widgets/                        # Reusable UI components
├── models/                         # Data models with Hive adapters
├── data/                          # Data layer (storage, repositories)
└── utils/                         # Utility functions and helpers
```

### Architecture Flow
```
main.dart → Services Init → Provider Setup → App Launch → Theme Application → Screen Rendering
```

## 🧩 Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  
  # State Management
  provider: ^6.1.1
  
  # Navigation
  go_router: ^13.0.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1
  
  # UI Components
  flutter_animate: ^4.3.0
  percent_indicator: ^4.2.3
  flutter_rating_bar: ^4.0.1
  shimmer: ^3.0.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  
  # Utilities
  intl: ^0.18.1
  uuid: ^4.2.2
  collection: ^1.18.0
  permission_handler: ^11.1.0
  
  # Notifications
  flutter_local_notifications: ^19.2.1
  shared_preferences: ^2.2.2
  timezone: ^0.10.0
  
  # Ads & Monetization
  google_mobile_ads: ^3.0.0
  in_app_purchase: ^3.1.11
  in_app_purchase_platform_interface: ^1.4.0
  firebase_analytics: ^11.4.6
  
  # Image handling
  image_picker: ^1.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  hive_generator: ^2.0.0
  build_runner: ^2.4.8
  flutter_launcher_icons: ^0.13.1
```

## 🛠️ Full Configuration Files

### 1. main.dart - Complete App Entry Point

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Core imports
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'core/responsive/responsive_util.dart';
import 'core/config/ads_config.dart';
import 'core/theme/theme_provider.dart';

// Service imports
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'services/ad_service.dart';
import 'data/storage_service.dart';

// Model imports (add your generated Hive adapters)
import 'models/user_profile.dart';
import 'models/settings.dart';
// ... add all your model imports

// Screen imports
import 'screens/splash/splash_screen.dart';

Future<void> initGoogleMobileAds() async {
  try {
    await MobileAds.instance.initialize();
    
    // Configure test devices for development
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['YOUR_TEST_DEVICE_ID'], // Add your test device ID
      ),
    );
    debugPrint('✅ Mobile ads initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing mobile ads: $e');
  }
}

Future<void> main() async {
  try {
    debugPrint('🚀 App: Starting initialization');

    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Initialize Hive
    await Hive.initFlutter();
    
    // Ensure Hive directory exists
    final appDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDir.path}/hive';
    await Directory(hivePath).create(recursive: true);

    // Register Hive adapters (update with your models)
    debugPrint('📦 Registering Hive adapters');
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SettingsAdapter());
    // ... register all your adapters

    // Create service instances
    final subscriptionService = SubscriptionService();
    final storageService = StorageService();
    final notificationService = NotificationService.instance;
    final adService = AdService();

    // Initialize services sequentially
    await subscriptionService.init();
    await storageService.init();
    await notificationService.init();
    adService.init(subscriptionService);

    // Initialize Google Mobile Ads
    await initGoogleMobileAds();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<SubscriptionService>.value(value: subscriptionService),
          Provider<StorageService>.value(value: storageService),
          Provider<NotificationService>.value(value: notificationService),
          Provider<AdService>.value(value: adService),
        ],
        child: const MyApp(),
      ),
    );
    
    debugPrint('✅ App: Application started successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ App: Fatal error during initialization: $e');
    debugPrint(stackTrace.toString());
    
    // Show error UI with retry option
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Failed to start the app',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      builder: (context, child) {
        // Initialize responsive utility
        ResponsiveUtil().init(context);
        return child ?? const SizedBox();
      },
      home: const SplashScreen(),
    );
  }

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
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primaryPink,
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          textStyle: AppTypography.buttonText,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          textStyle: AppTypography.buttonText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPink, width: 2),
        ),
      ),
    );
  }
}
```

### 2. Core Constants Files

#### app_colors.dart
```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color primaryBlue = Color(0xFF2196F3);
  
  // Secondary Colors
  static const Color secondaryPink = Color(0xFFF8BBD9);
  static const Color secondaryPurple = Color(0xFFE1BEE7);
  static const Color secondaryBlue = Color(0xFFBBDEFB);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPink, primaryPurple],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundWhite, backgroundLight],
  );
}
```

#### app_typography.dart
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  // Heading Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Button Text
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  // Caption & Labels
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    height: 1.3,
  );
  
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );
}
```

#### app_dimensions.dart
```dart
class AppDimensions {
  // Padding & Margins
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  
  // Button Heights
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
  
  // Screen Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
}
```

### 3. Responsive Utility

#### responsive_util.dart
```dart
import 'package:flutter/material.dart';

class ResponsiveUtil {
  static ResponsiveUtil? _instance;
  static ResponsiveUtil get instance => _instance ??= ResponsiveUtil._();
  ResponsiveUtil._();
  
  factory ResponsiveUtil() => instance;
  
  late BuildContext _context;
  
  void init(BuildContext context) {
    _context = context;
  }
  
  // Screen dimensions
  double get screenWidth => MediaQuery.of(_context).size.width;
  double get screenHeight => MediaQuery.of(_context).size.height;
  
  // Device type checks
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
  
  // Responsive values
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
  
  // Responsive padding
  EdgeInsets get screenPadding => responsive(
    mobile: const EdgeInsets.all(16.0),
    tablet: const EdgeInsets.all(24.0),
    desktop: const EdgeInsets.all(32.0),
  );
  
  // Grid columns
  int get gridColumns => responsive(
    mobile: 2,
    tablet: 3,
    desktop: 4,
  );
}
```

### 4. Theme Provider

#### theme_provider.dart
```dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
```

## 🔁 Integration Guide

1. **Create folder structure**: Set up the lib/ directory with all subfolders
2. **Add dependencies**: Copy the pubspec.yaml dependencies section
3. **Configure main.dart**: Use the provided main.dart as your entry point
4. **Add constants**: Copy all constant files to lib/core/constants/
5. **Set up responsive**: Add the responsive utility to lib/core/responsive/
6. **Configure theme**: Add theme provider to lib/core/theme/
7. **Test setup**: Run `flutter run` to verify everything works

## 💾 Persistence Handling

- **Hive initialization**: Automatic database setup with error handling
- **Service initialization**: Sequential service startup with retry logic
- **State persistence**: Theme and app state saved automatically
- **Error recovery**: Automatic cleanup and retry on initialization failures

## 📱 UI Details

- **Material 3 Design**: Modern Google design system
- **Responsive breakpoints**: Mobile (< 600px), Tablet (600-1024px), Desktop (> 1024px)
- **Custom theme**: Consistent colors, typography, and spacing
- **System UI**: Transparent status bar with proper icon contrast
- **Smooth transitions**: Built-in animation support

## 🔄 Feature Validation

✅ **App starts without errors**
✅ **Services initialize properly**
✅ **Theme system works**
✅ **Responsive design adapts**
✅ **Error handling functions**
✅ **Performance optimized**

---

**Next**: Continue with `02_Navigation_System` to set up routing and navigation. 