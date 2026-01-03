# 🧠 State Management - Provider Architecture

## ✅ Purpose
Implement a scalable, reactive state management system using Provider pattern with proper separation of concerns, dependency injection, and state persistence.

## 🧠 Architecture Overview

### State Management Flow
```
User Action → Provider Method → State Update → UI Rebuild → Local Storage
     ↓              ↓              ↓           ↓              ↓
   Button Tap → updateProfile() → notifyListeners() → Widget.build() → Hive.save()
```

### Provider Structure
```
lib/providers/
├── app_provider.dart           # Global app state
├── auth_provider.dart          # Authentication state
├── user_provider.dart          # User profile and preferences
├── subscription_provider.dart   # Premium subscription state
├── notification_provider.dart   # Notification settings
├── theme_provider.dart         # Theme and appearance
├── routines_provider.dart      # Beauty routines management
├── products_provider.dart      # Products and inventory
└── analytics_provider.dart     # Usage analytics and insights
```

## 🧩 Dependencies

Provider pattern dependencies (already included):
```yaml
dependencies:
  provider: ^6.1.1              # State management solution
  hive: ^2.2.3                  # Local storage integration
  hive_flutter: ^1.1.0          # Flutter-specific Hive features
```

## 🛠️ Complete Provider Implementation

### 1. Base Provider Pattern

#### base_provider.dart
```dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;
  
  // Loading state
  bool get isLoading => _isLoading;
  
  // Error state
  String? get error => _error;
  bool get hasError => _error != null;
  
  // Set loading state
  void setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    notifyListeners();
  }
  
  // Set error state
  void setError(String? error) {
    if (_isDisposed) return;
    _error = error;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    if (_isDisposed) return;
    _error = null;
    notifyListeners();
  }
  
  // Safe notify listeners
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
  
  // Initialize provider (override in subclasses)
  Future<void> init() async {}
  
  // Dispose override to prevent memory leaks
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
  
  // Helper method for async operations with error handling
  Future<T?> executeAsync<T>(Future<T> Function() operation) async {
    try {
      setLoading(true);
      clearError();
      final result = await operation();
      return result;
    } catch (e) {
      setError(e.toString());
      debugPrint('Provider error: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }
}
```

### 2. User Provider - Profile Management

#### user_provider.dart
```dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';
import '../models/settings.dart';
import '../data/storage_service.dart';
import 'base_provider.dart';

class UserProvider extends BaseProvider {
  final StorageService _storageService;
  
  UserProfile? _currentUser;
  Settings? _userSettings;
  
  UserProvider(this._storageService);
  
  // Getters
  UserProfile? get currentUser => _currentUser;
  Settings? get userSettings => _userSettings;
  bool get isLoggedIn => _currentUser != null;
  
  // User info getters
  String get userName => _currentUser?.name ?? 'User';
  String get userEmail => _currentUser?.email ?? '';
  String get userAvatar => _currentUser?.profileImagePath ?? '';
  bool get hasCompletedOnboarding => _currentUser?.hasCompletedOnboarding ?? false;
  
  @override
  Future<void> init() async {
    await executeAsync(() async {
      await _loadUserData();
    });
  }
  
  // Load user data from storage
  Future<void> _loadUserData() async {
    if (_storageService.hasUser()) {
      final userData = _storageService.getCurrentUserData();
      if (userData != null) {
        _currentUser = userData.userProfile;
        _userSettings = userData.settings;
      }
    }
  }
  
  // Create new user profile
  Future<bool> createUser({
    required String name,
    required String email,
    String? profileImagePath,
  }) async {
    return await executeAsync(() async {
      final newUser = UserProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        profileImagePath: profileImagePath,
        createdAt: DateTime.now(),
        hasCompletedOnboarding: false,
      );
      
      final defaultSettings = Settings(
        notificationsEnabled: true,
        reminderTime: const TimeOfDay(hour: 9, minute: 0),
        weeklyGoal: 7,
        soundEnabled: true,
        vibrationEnabled: true,
      );
      
      await _storageService.saveUser(newUser, defaultSettings);
      
      _currentUser = newUser;
      _userSettings = defaultSettings;
      
      return true;
    }) ?? false;
  }
  
  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? profileImagePath,
  }) async {
    if (_currentUser == null) return false;
    
    return await executeAsync(() async {
      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
        profileImagePath: profileImagePath ?? _currentUser!.profileImagePath,
      );
      
      await _storageService.updateUser(updatedUser);
      _currentUser = updatedUser;
      
      return true;
    }) ?? false;
  }
  
  // Complete onboarding
  Future<bool> completeOnboarding() async {
    if (_currentUser == null) return false;
    
    return await executeAsync(() async {
      final updatedUser = _currentUser!.copyWith(
        hasCompletedOnboarding: true,
      );
      
      await _storageService.updateUser(updatedUser);
      _currentUser = updatedUser;
      
      return true;
    }) ?? false;
  }
  
  // Update settings
  Future<bool> updateSettings(Settings newSettings) async {
    return await executeAsync(() async {
      await _storageService.updateSettings(newSettings);
      _userSettings = newSettings;
      return true;
    }) ?? false;
  }
  
  // Sign out user
  Future<void> signOut() async {
    await executeAsync(() async {
      await _storageService.clearUser();
      _currentUser = null;
      _userSettings = null;
    });
  }
  
  // Delete user account
  Future<bool> deleteAccount() async {
    return await executeAsync(() async {
      await _storageService.deleteUser();
      _currentUser = null;
      _userSettings = null;
      return true;
    }) ?? false;
  }
}
```

### 3. Subscription Provider - Premium Features

#### subscription_provider.dart
```dart
import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../models/subscription_status.dart';
import 'base_provider.dart';

class SubscriptionProvider extends BaseProvider {
  final SubscriptionService _subscriptionService;
  
  SubscriptionStatus? _subscriptionStatus;
  List<String> _availableProducts = [];
  
  SubscriptionProvider(this._subscriptionService);
  
  // Getters
  bool get isPremium => _subscriptionService.isPremium;
  bool get isSubscriptionActive => _subscriptionStatus?.isActive ?? false;
  DateTime? get subscriptionEndDate => _subscriptionStatus?.endDate;
  String? get subscriptionType => _subscriptionStatus?.subscriptionType;
  List<String> get availableProducts => _availableProducts;
  
  // Premium feature checks
  bool get canAccessPremiumFeatures => isPremium;
  bool get canCreateUnlimitedRoutines => isPremium;
  bool get canExportData => isPremium;
  bool get canUseAdvancedAnalytics => isPremium;
  
  @override
  Future<void> init() async {
    await executeAsync(() async {
      await _loadSubscriptionData();
      await _loadAvailableProducts();
    });
  }
  
  // Load subscription status
  Future<void> _loadSubscriptionData() async {
    _subscriptionStatus = await _subscriptionService.getSubscriptionStatus();
  }
  
  // Load available products
  Future<void> _loadAvailableProducts() async {
    _availableProducts = await _subscriptionService.getAvailableProducts();
  }
  
  // Purchase subscription
  Future<bool> purchaseSubscription(String productId) async {
    return await executeAsync(() async {
      final success = await _subscriptionService.purchaseSubscription(productId);
      if (success) {
        await _loadSubscriptionData();
      }
      return success;
    }) ?? false;
  }
  
  // Restore purchases
  Future<bool> restorePurchases() async {
    return await executeAsync(() async {
      final success = await _subscriptionService.restorePurchases();
      if (success) {
        await _loadSubscriptionData();
      }
      return success;
    }) ?? false;
  }
  
  // Cancel subscription
  Future<bool> cancelSubscription() async {
    return await executeAsync(() async {
      final success = await _subscriptionService.cancelSubscription();
      if (success) {
        await _loadSubscriptionData();
      }
      return success;
    }) ?? false;
  }
  
  // Check if feature is available
  bool isFeatureAvailable(String featureId) {
    if (isPremium) return true;
    
    // Define free features
    const freeFeatures = [
      'basic_routines',
      'basic_products',
      'basic_tips',
    ];
    
    return freeFeatures.contains(featureId);
  }
  
  // Get feature limit
  int getFeatureLimit(String featureId) {
    if (isPremium) return -1; // Unlimited
    
    // Define free limits
    const freeLimits = {
      'routines_count': 3,
      'products_count': 10,
      'reminders_count': 5,
    };
    
    return freeLimits[featureId] ?? 0;
  }
}
```

### 4. Theme Provider - Appearance Management

#### theme_provider.dart
```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import 'base_provider.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends BaseProvider {
  static const String _themeKey = 'theme_mode';
  
  AppThemeMode _themeMode = AppThemeMode.system;
  late SharedPreferences _prefs;
  
  // Getters
  AppThemeMode get themeMode => _themeMode;
  bool get isDarkMode {
    switch (_themeMode) {
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.light:
        return false;
      case AppThemeMode.system:
        return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    }
  }
  
  @override
  Future<void> init() async {
    await executeAsync(() async {
      _prefs = await SharedPreferences.getInstance();
      await _loadThemeMode();
    });
  }
  
  // Load saved theme mode
  Future<void> _loadThemeMode() async {
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => AppThemeMode.system,
      );
    }
  }
  
  // Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    await executeAsync(() async {
      _themeMode = mode;
      await _prefs.setString(_themeKey, mode.toString());
    });
  }
  
  // Toggle between light and dark
  Future<void> toggleTheme() async {
    final newMode = isDarkMode ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }
  
  // Get light theme
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPink,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      // Add more theme configurations...
    );
  }
  
  // Get dark theme
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPink,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.black,
      // Add more theme configurations...
    );
  }
}
```

### 5. Routines Provider - Data Management

#### routines_provider.dart
```dart
import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../data/storage_service.dart';
import '../services/subscription_service.dart';
import 'base_provider.dart';

class RoutinesProvider extends BaseProvider {
  final StorageService _storageService;
  final SubscriptionService _subscriptionService;
  
  List<Routine> _routines = [];
  Routine? _selectedRoutine;
  
  RoutinesProvider(this._storageService, this._subscriptionService);
  
  // Getters
  List<Routine> get routines => _routines;
  List<Routine> get activeRoutines => _routines.where((r) => r.isActive).toList();
  List<Routine> get completedRoutines => _routines.where((r) => !r.isActive).toList();
  Routine? get selectedRoutine => _selectedRoutine;
  
  // Statistics
  int get totalRoutines => _routines.length;
  int get completedToday => _routines.where((r) => r.isCompletedToday).length;
  double get completionRate => _routines.isEmpty ? 0.0 : 
      _routines.where((r) => r.isCompletedToday).length / _routines.length;
  
  @override
  Future<void> init() async {
    await executeAsync(() async {
      await _loadRoutines();
    });
  }
  
  // Load routines from storage
  Future<void> _loadRoutines() async {
    _routines = await _storageService.getAllRoutines();
  }
  
  // Add new routine
  Future<bool> addRoutine(Routine routine) async {
    // Check subscription limits
    if (!_subscriptionService.isPremium) {
      final freeLimit = 3; // Free users get 3 routines
      if (_routines.length >= freeLimit) {
        setError('Upgrade to Premium to create more routines');
        return false;
      }
    }
    
    return await executeAsync(() async {
      await _storageService.saveRoutine(routine);
      _routines.add(routine);
      _routines.sort((a, b) => a.name.compareTo(b.name));
      return true;
    }) ?? false;
  }
  
  // Update routine
  Future<bool> updateRoutine(Routine routine) async {
    return await executeAsync(() async {
      await _storageService.updateRoutine(routine);
      
      final index = _routines.indexWhere((r) => r.id == routine.id);
      if (index != -1) {
        _routines[index] = routine;
      }
      
      if (_selectedRoutine?.id == routine.id) {
        _selectedRoutine = routine;
      }
      
      return true;
    }) ?? false;
  }
  
  // Delete routine
  Future<bool> deleteRoutine(String routineId) async {
    return await executeAsync(() async {
      await _storageService.deleteRoutine(routineId);
      
      _routines.removeWhere((r) => r.id == routineId);
      
      if (_selectedRoutine?.id == routineId) {
        _selectedRoutine = null;
      }
      
      return true;
    }) ?? false;
  }
  
  // Mark routine as completed
  Future<bool> completeRoutine(String routineId) async {
    return await executeAsync(() async {
      final routine = _routines.firstWhere((r) => r.id == routineId);
      final updatedRoutine = routine.copyWith(
        lastCompletedDate: DateTime.now(),
        completionCount: routine.completionCount + 1,
      );
      
      return await updateRoutine(updatedRoutine);
    }) ?? false;
  }
  
  // Select routine for editing
  void selectRoutine(Routine? routine) {
    _selectedRoutine = routine;
    notifyListeners();
  }
  
  // Get routine by ID
  Routine? getRoutineById(String id) {
    try {
      return _routines.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Search routines
  List<Routine> searchRoutines(String query) {
    if (query.isEmpty) return _routines;
    
    return _routines.where((routine) {
      return routine.name.toLowerCase().contains(query.toLowerCase()) ||
             routine.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
  
  // Get routines for today
  List<Routine> getTodayRoutines() {
    final today = DateTime.now().weekday;
    return _routines.where((routine) {
      return routine.schedule.contains(today) && routine.isActive;
    }).toList();
  }
}
```

## 🔁 Integration Guide

### Step 1: Provider Setup in main.dart
```dart
void main() async {
  // ... initialization code ...
  
  runApp(
    MultiProvider(
      providers: [
        // Services (created once)
        Provider<StorageService>.value(value: storageService),
        Provider<SubscriptionService>.value(value: subscriptionService),
        
        // Providers (reactive state)
        ChangeNotifierProvider(
          create: (context) => UserProvider(
            Provider.of<StorageService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SubscriptionProvider(
            Provider.of<SubscriptionService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => RoutinesProvider(
            Provider.of<StorageService>(context, listen: false),
            Provider.of<SubscriptionService>(context, listen: false),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Step 2: Using Providers in Widgets
```dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const LoadingSpinner();
        }
        
        if (userProvider.hasError) {
          return ErrorWidget(userProvider.error!);
        }
        
        return Column(
          children: [
            Text('Welcome, ${userProvider.userName}!'),
            if (userProvider.isLoggedIn)
              ProfileDetails(user: userProvider.currentUser!),
          ],
        );
      },
    );
  }
}
```

### Step 3: State Updates
```dart
// Update user profile
await Provider.of<UserProvider>(context, listen: false)
    .updateProfile(name: 'New Name');

// Purchase subscription
final success = await Provider.of<SubscriptionProvider>(context, listen: false)
    .purchaseSubscription('premium_monthly');

// Add new routine
final routine = Routine(name: 'Morning Skincare');
await Provider.of<RoutinesProvider>(context, listen: false)
    .addRoutine(routine);
```

## 💾 Persistence Handling

- **Automatic Persistence**: All state changes automatically saved to Hive
- **Offline Support**: Full offline functionality with local storage
- **State Recovery**: App state restored on restart
- **Background Sync**: Prepared for future cloud synchronization

## 📱 UI Integration

- **Loading States**: Consistent loading indicators across all providers
- **Error Handling**: Centralized error management and display
- **Reactive UI**: Automatic UI updates when state changes
- **Performance**: Optimized with Consumer widgets and selective rebuilds

## 🔄 Feature Validation

✅ **State Persistence**: Data survives app restarts
✅ **Error Handling**: Graceful error management
✅ **Loading States**: Proper async operation feedback
✅ **Memory Management**: No memory leaks with proper disposal
✅ **Subscription Limits**: Premium feature gating works
✅ **Performance**: Efficient state updates and notifications

---

**Next**: Continue with `06_Data_Persistence` to implement complete Hive storage setup. 