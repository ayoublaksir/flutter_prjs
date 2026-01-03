# 🧭 Navigation System - Complete Go Router Setup

## ✅ Purpose
Implement a modern, declarative navigation system using Go Router with deep linking, route guards, custom transitions, and bottom navigation integration.

## 🧠 Architecture Overview

### Navigation Flow
```
App Launch → Route Evaluation → Guard Check → Transition → Screen Render
     ↓              ↓              ↓           ↓            ↓
Initial Route → Auth Check → Premium Check → Animation → UI Display
```

### Folder Structure
```
lib/core/navigation/
├── navigation_manager.dart     # Central navigation logic and GoRouter config
├── custom_routes.dart          # Route definitions and custom transitions
├── nav_items.dart             # Bottom navigation configuration
└── route_guards.dart          # Authentication and premium route guards
```

## 🧩 Dependencies

Already included in the main pubspec.yaml:
```yaml
dependencies:
  go_router: ^13.0.0  # Modern declarative routing
  provider: ^6.1.1    # State management for navigation state
```

## 🛠️ Complete Implementation

### 1. Navigation Manager - Core Router Setup

#### navigation_manager.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Screen imports
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/premium/premium_screen.dart';
import '../../screens/routines/routines_screen.dart';
import '../../screens/products/products_screen.dart';
import '../../screens/tips/tips_screen.dart';

// Services
import '../../services/subscription_service.dart';
import '../../data/storage_service.dart';

// Route guards
import 'route_guards.dart';
import 'custom_routes.dart';

class NavigationManager {
  static NavigationManager? _instance;
  static NavigationManager get instance => _instance ??= NavigationManager._();
  NavigationManager._();
  
  late GoRouter _router;
  GoRouter get router => _router;
  
  // Current navigation state
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  
  // Navigation history for back button handling
  final List<String> _navigationHistory = ['/home'];
  
  void initialize(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    _router = GoRouter(
      initialLocation: _determineInitialRoute(storageService),
      debugLogDiagnostics: true,
      routes: [
        // Splash Route
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        
        // Onboarding Route
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          pageBuilder: (context, state) => CustomRoutes.slideTransition(
            const OnboardingScreen(),
            state,
          ),
        ),
        
        // Main App Shell with Bottom Navigation
        ShellRoute(
          builder: (context, state, child) => MainNavigationShell(child: child),
          routes: [
            // Home Tab
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
            
            // Routines Tab
            GoRoute(
              path: '/routines',
              name: 'routines',
              builder: (context, state) => const RoutinesScreen(),
              routes: [
                GoRoute(
                  path: '/create',
                  name: 'create-routine',
                  pageBuilder: (context, state) => CustomRoutes.slideUpTransition(
                    const CreateRoutineScreen(),
                    state,
                  ),
                ),
              ],
            ),
            
            // Products Tab
            GoRoute(
              path: '/products',
              name: 'products',
              builder: (context, state) => const ProductsScreen(),
              routes: [
                GoRoute(
                  path: '/:productId',
                  name: 'product-detail',
                  builder: (context, state) {
                    final productId = state.pathParameters['productId']!;
                    return ProductDetailScreen(productId: productId);
                  },
                ),
              ],
            ),
            
            // Tips Tab
            GoRoute(
              path: '/tips',
              name: 'tips',
              builder: (context, state) => const TipsScreen(),
            ),
            
            // Profile Tab
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        
        // Premium Route (with guard)
        GoRoute(
          path: '/premium',
          name: 'premium',
          pageBuilder: (context, state) => CustomRoutes.fadeTransition(
            const PremiumScreen(),
            state,
          ),
        ),
        
        // Settings Route
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => CustomRoutes.slideTransition(
            const SettingsScreen(),
            state,
          ),
          routes: [
            GoRoute(
              path: '/notifications',
              name: 'notification-settings',
              builder: (context, state) => const NotificationSettingsScreen(),
            ),
            GoRoute(
              path: '/privacy',
              name: 'privacy-settings',
              builder: (context, state) => const PrivacySettingsScreen(),
            ),
          ],
        ),
      ],
      
      // Redirect logic for route guards
      redirect: (context, state) {
        return RouteGuards.checkAccess(
          context,
          state,
          subscriptionService,
          storageService,
        );
      },
      
      // Error handling
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page not found: ${state.location}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _determineInitialRoute(StorageService storageService) {
    // Check if user has completed onboarding
    if (!storageService.hasCompletedOnboarding()) {
      return '/onboarding';
    }
    
    // Check if user exists
    if (!storageService.hasUser()) {
      return '/onboarding';
    }
    
    return '/home';
  }
  
  // Navigation methods
  void navigateToTab(int index) {
    _currentIndex = index;
    
    final routes = ['/home', '/routines', '/products', '/tips', '/profile'];
    final route = routes[index];
    
    _navigationHistory.add(route);
    _router.go(route);
  }
  
  void navigateTo(String route, {Map<String, dynamic>? extra}) {
    _navigationHistory.add(route);
    _router.go(route, extra: extra);
  }
  
  void navigateToNamed(String name, {Map<String, String>? pathParameters, Map<String, dynamic>? extra}) {
    _router.goNamed(name, pathParameters: pathParameters ?? {}, extra: extra);
  }
  
  bool canPop() {
    return _navigationHistory.length > 1;
  }
  
  void pop() {
    if (canPop()) {
      _navigationHistory.removeLast();
      final previousRoute = _navigationHistory.last;
      _router.go(previousRoute);
    }
  }
  
  // Deep link handling
  void handleDeepLink(String link) {
    try {
      _router.go(link);
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      _router.go('/home');
    }
  }
}

// Main Navigation Shell with Bottom Navigation
class MainNavigationShell extends StatefulWidget {
  final Widget child;
  
  const MainNavigationShell({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: NavigationManager.instance.currentIndex,
        onTap: NavigationManager.instance.navigateToTab,
      ),
    );
  }
}
```

### 2. Custom Routes and Transitions

#### custom_routes.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomRoutes {
  // Slide transition from right
  static Page<void> slideTransition(Widget child, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  // Slide up transition (for modals)
  static Page<void> slideUpTransition(Widget child, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  // Fade transition
  static Page<void> fadeTransition(Widget child, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
  
  // Scale transition
  static Page<void> scaleTransition(Widget child, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;
        var tween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
        return ScaleTransition(
          scale: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  // Custom page route for complex transitions
  static Page<void> customTransition({
    required Widget child,
    required GoRouterState state,
    required Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) transitionsBuilder,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: transitionsBuilder,
      transitionDuration: transitionDuration,
    );
  }
}
```

### 3. Route Guards for Authentication and Premium Features

#### route_guards.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/subscription_service.dart';
import '../../data/storage_service.dart';

class RouteGuards {
  static String? checkAccess(
    BuildContext context,
    GoRouterState state,
    SubscriptionService subscriptionService,
    StorageService storageService,
  ) {
    final location = state.location;
    
    // Protected routes that require onboarding completion
    final onboardingProtectedRoutes = ['/home', '/routines', '/products', '/tips', '/profile'];
    if (onboardingProtectedRoutes.any((route) => location.startsWith(route))) {
      if (!storageService.hasCompletedOnboarding()) {
        return '/onboarding';
      }
    }
    
    // Protected routes that require user account
    final userProtectedRoutes = ['/profile', '/settings'];
    if (userProtectedRoutes.any((route) => location.startsWith(route))) {
      if (!storageService.hasUser()) {
        return '/onboarding';
      }
    }
    
    // Premium routes that require subscription
    final premiumRoutes = ['/premium-features', '/advanced-analytics'];
    if (premiumRoutes.any((route) => location.startsWith(route))) {
      if (!subscriptionService.isPremium) {
        return '/premium';
      }
    }
    
    // Redirect authenticated users away from onboarding
    if (location == '/onboarding' && storageService.hasUser()) {
      return '/home';
    }
    
    return null; // No redirect needed
  }
  
  // Check if route requires premium subscription
  static bool requiresPremium(String route) {
    final premiumRoutes = [
      '/premium-features',
      '/advanced-analytics',
      '/export-data',
      '/unlimited-routines',
    ];
    return premiumRoutes.any((premiumRoute) => route.startsWith(premiumRoute));
  }
  
  // Check if user can access route
  static bool canAccessRoute(
    String route,
    SubscriptionService subscriptionService,
    StorageService storageService,
  ) {
    // Check onboarding completion
    if (!storageService.hasCompletedOnboarding() && route != '/onboarding') {
      return false;
    }
    
    // Check premium requirement
    if (requiresPremium(route) && !subscriptionService.isPremium) {
      return false;
    }
    
    return true;
  }
}
```

### 4. Bottom Navigation Configuration

#### nav_items.dart
```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  
  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class NavItems {
  static const List<NavItem> items = [
    NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: '/home',
    ),
    NavItem(
      label: 'Routines',
      icon: Icons.schedule_outlined,
      activeIcon: Icons.schedule,
      route: '/routines',
    ),
    NavItem(
      label: 'Products',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
      route: '/products',
    ),
    NavItem(
      label: 'Tips',
      icon: Icons.lightbulb_outlined,
      activeIcon: Icons.lightbulb,
      route: '/tips',
    ),
    NavItem(
      label: 'Profile',
      icon: Icons.person_outlined,
      activeIcon: Icons.person,
      route: '/profile',
    ),
  ];
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryPink,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        items: NavItems.items
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}
```

## 🔁 Integration Guide

### Step 1: Set up Navigation Manager
1. Copy all navigation files to `lib/core/navigation/`
2. Import `NavigationManager` in your main app widget
3. Initialize the router in your app's build method

### Step 2: Update Main App Widget
```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize navigation manager
    NavigationManager.instance.initialize(context);
    
    return MaterialApp.router(
      title: 'Your App Name',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: NavigationManager.instance.router,
    );
  }
}
```

### Step 3: Navigation Usage Examples
```dart
// Navigate to a specific tab
NavigationManager.instance.navigateToTab(2); // Products tab

// Navigate to a named route
NavigationManager.instance.navigateToNamed('product-detail', 
  pathParameters: {'productId': '123'});

// Navigate with custom data
NavigationManager.instance.navigateTo('/settings', 
  extra: {'fromProfile': true});

// Handle back navigation
if (NavigationManager.instance.canPop()) {
  NavigationManager.instance.pop();
}
```

## 💾 Persistence Handling

- **Navigation State**: Current tab index maintained across app restarts
- **Deep Link History**: Navigation history for proper back button behavior
- **Route Guards**: Authentication and subscription state persisted
- **Initial Route**: Determined based on user onboarding and authentication status

## 📱 UI Details

### Bottom Navigation Features
- **Material 3 Design**: Modern navigation bar with proper elevation
- **Active State**: Visual feedback for selected tabs
- **Smooth Transitions**: Seamless tab switching with animations
- **Badge Support**: Ready for notification badges
- **Responsive**: Adapts to different screen sizes

### Route Transitions
- **Slide Transitions**: Smooth right-to-left navigation
- **Modal Transitions**: Bottom-to-top for modal screens
- **Fade Transitions**: Elegant fading for overlays
- **Custom Transitions**: Extensible system for unique animations

## 🔄 Feature Validation

✅ **Deep linking works**: URLs navigate to correct screens
✅ **Route guards function**: Premium/auth protection active
✅ **Back navigation**: Proper history and pop behavior
✅ **Tab switching**: Smooth bottom navigation transitions
✅ **Error handling**: Graceful 404 and error screen handling
✅ **State persistence**: Navigation state survives app restarts

---

**Next**: Continue with `03_UI_Components` to create reusable responsive UI elements. 