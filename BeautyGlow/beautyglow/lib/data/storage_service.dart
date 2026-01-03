import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import '../models/beauty_data.dart';
import '../models/notification_settings.dart';
import '../models/product.dart';
import '../models/routine.dart';
import '../models/settings.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';
import 'package:flutter/foundation.dart';

/// Service for managing local storage with Hive
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  late Box<BeautyData> _usersBox;
  late Box<Routine> _routinesBox;
  late Box<Product> _productsBox;
  late Box _settingsBox;

  static const String _currentUserKey = 'current_user';
  static const String _notificationAskedKey = 'notification_permission_asked';
  static const String _usersBoxName = 'users';
  static const String _routinesBoxName = 'routines';
  static const String _productsBoxName = 'products';
  static const String _settingsBoxName = 'app_settings';

  StorageService._internal();

  /// Clean up all boxes
  Future<void> _cleanupBoxes() async {
    debugPrint('🧹 StorageService: Starting box cleanup');
    final boxNames = [
      _usersBoxName,
      _routinesBoxName,
      _productsBoxName,
      _settingsBoxName,
      'subscription_box',
      'article_views_box',
      'notification_settings',
    ];

    for (final boxName in boxNames) {
      try {
        if (await Hive.boxExists(boxName)) {
          debugPrint('🗑️ StorageService: Deleting box: $boxName');
          await Hive.deleteBoxFromDisk(boxName);
        }
      } catch (e) {
        debugPrint('⚠️ Non-fatal error deleting box $boxName: $e');
      }
    }
    debugPrint('✅ StorageService: Box cleanup completed');
  }

  /// Initialize storage boxes
  Future<void> init() async {
    debugPrint('🚀 StorageService: Starting initialization');
    try {
      // Only cleanup boxes if there are critical errors, not on every init
      // await _cleanupBoxes(); // COMMENTED OUT - was deleting all user data!

      // Verify Hive adapters are registered
      // Note: TypeId 9 (SubscriptionStatus) is not yet implemented
      final requiredTypeIds = [0, 1, 2, 3, 4, 5, 6, 7, 8];
      debugPrint(
          '🔍 StorageService: Verifying required adapters: $requiredTypeIds');

      for (var typeId in requiredTypeIds) {
        final isRegistered = Hive.isAdapterRegistered(typeId);
        debugPrint(
            '📋 StorageService: TypeId $typeId registered: $isRegistered');
        if (!isRegistered) {
          throw StateError(
              'Required Hive adapter with typeId $typeId is not registered');
        }
      }
      debugPrint('✓ StorageService: All required Hive adapters verified');

      // Open boxes with retry mechanism
      try {
        debugPrint('📦 StorageService: Opening boxes...');
        _usersBox = await _openBoxWithRetry<BeautyData>(_usersBoxName);
        _routinesBox = await _openBoxWithRetry<Routine>(_routinesBoxName);
        _productsBox = await _openBoxWithRetry<Product>(_productsBoxName);
        _settingsBox = await _openBoxWithRetry(_settingsBoxName);
        debugPrint('✓ StorageService: All boxes opened successfully');
      } catch (boxError) {
        debugPrint(
            '❌ StorageService: Error opening boxes, attempting cleanup and retry: $boxError');
        await _cleanupBoxes();
        debugPrint('🔄 StorageService: Retrying box opening after cleanup...');
        _usersBox = await _openBoxWithRetry<BeautyData>(_usersBoxName);
        _routinesBox = await _openBoxWithRetry<Routine>(_routinesBoxName);
        _productsBox = await _openBoxWithRetry<Product>(_productsBoxName);
        _settingsBox = await _openBoxWithRetry(_settingsBoxName);
        debugPrint(
            '✓ StorageService: All boxes opened successfully after retry');
      }

      // Verify boxes are open and properly typed
      debugPrint('🔍 StorageService: Verifying box integrity...');

      if (!_usersBox.isOpen || _usersBox.values.any((e) => e is! BeautyData)) {
        throw StateError('Users box is not properly initialized');
      }
      debugPrint(
          '✓ StorageService: Users box verified (${_usersBox.length} entries)');

      if (!_routinesBox.isOpen ||
          _routinesBox.values.any((e) => e is! Routine)) {
        throw StateError('Routines box is not properly initialized');
      }
      debugPrint(
          '✓ StorageService: Routines box verified (${_routinesBox.length} entries)');

      if (!_productsBox.isOpen ||
          _productsBox.values.any((e) => e is! Product)) {
        throw StateError('Products box is not properly initialized');
      }
      debugPrint(
          '✓ StorageService: Products box verified (${_productsBox.length} entries)');

      if (!_settingsBox.isOpen) {
        throw StateError('Settings box is not properly initialized');
      }
      debugPrint(
          '✓ StorageService: Settings box verified (${_settingsBox.length} entries)');

      debugPrint(
          '✅ StorageService: All boxes opened and verified successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ StorageService: Fatal error during initialization: $e');
      debugPrint('📋 StorageService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Open a box with retry mechanism
  Future<Box<T>> _openBoxWithRetry<T>(String boxName) async {
    debugPrint('📦 StorageService: Opening box $boxName');
    try {
      if (await Hive.boxExists(boxName)) {
        debugPrint(
            '🔄 StorageService: Box $boxName exists, attempting to open');
        try {
          final box = await Hive.openBox<T>(boxName);
          // Verify box contents
          if (box.isOpen) {
            debugPrint('✓ StorageService: Box $boxName opened successfully');
            return box;
          }
          throw StateError('Box failed to open properly');
        } catch (e) {
          debugPrint(
              '⚠️ StorageService: Error opening existing box $boxName: $e');
          debugPrint('🗑️ StorageService: Deleting corrupted box');
          await Hive.deleteBoxFromDisk(boxName);
        }
      }

      debugPrint('📦 StorageService: Creating new box $boxName');
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      debugPrint('❌ StorageService: Fatal error with box $boxName: $e');
      rethrow;
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _settingsBox.get(_currentUserKey) as String?;
  }

  /// Get current user data
  BeautyData? getCurrentUserData({bool refresh = false}) {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    return _usersBox.get(userId);
  }

  /// Create new user
  Future<void> createNewUser({
    required String name,
    String skinType = 'normal',
    List<String>? skinConcerns,
    String preferredRoutineTime = 'both',
  }) async {
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final userProfile = UserProfile(
      id: userId,
      name: name,
      joinDate: DateTime.now(),
      skinType: skinType,
      skinConcerns: skinConcerns ?? [],
      preferredRoutineTime: preferredRoutineTime,
    );
    final userData = BeautyData.create(userProfile: userProfile);
    await _usersBox.put(userId, userData);
    await _settingsBox.put(_currentUserKey, userId);
  }

  /// Check if user exists
  bool hasUser() {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    return _usersBox.containsKey(userId);
  }

  /// Check if notification permission has been asked
  bool hasAskedForNotificationPermission() {
    return _settingsBox.get(_notificationAskedKey, defaultValue: false) as bool;
  }

  /// Mark notification permission as asked
  Future<void> markNotificationPermissionAsked() async {
    await _settingsBox.put(_notificationAskedKey, true);
  }

  /// Get current user data with refreshed statistics
  BeautyData? getCurrentUserDataWithRefresh({bool refresh = false}) {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final userData = _usersBox.get(userId);
      if (userData == null) return null;

      if (refresh) {
        // Refresh product count
        final products = getAllProducts();
        userData.favoriteProducts = products;

        // Refresh routines and completion stats
        final routines = getAllRoutines();
        userData.routines = routines;

        // Save the parent object first
        _usersBox.put(userId, userData);

        // Now update achievements
        userData.checkAchievements();
      }

      return userData;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Save user data
  Future<void> saveUserData(BeautyData userData) async {
    await _usersBox.put(userData.userId, userData);
  }

  /// Get all products
  List<Product> getAllProducts() {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    final products = <Product>[];
    for (final key in _productsBox.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('${userId}_')) {
        final product = _productsBox.get(key);
        if (product != null) {
          products.add(product);
        }
      }
    }
    return products;
  }

  /// Add product
  Future<void> addProduct(Product product) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    // Save to products box with user-specific ID
    final productId = '${userId}_${product.id}';
    product.id = productId;
    await _productsBox.put(productId, product);

    // Update user data
    final userData = getCurrentUserData();
    if (userData != null) {
      userData.favoriteProducts.add(product);
      await saveUserData(userData);
    }
  }

  /// Update product
  Future<void> updateProduct(Product product) async {
    // Update in products box
    await _productsBox.put(product.id, product);

    // Update in user data
    final userData = getCurrentUserData();
    if (userData != null) {
      final index =
          userData.favoriteProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        userData.favoriteProducts[index] = product;
        await saveUserData(userData);
      }
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    // Delete from products box
    await _productsBox.delete(productId);

    // Update user data
    final userData = getCurrentUserData();
    if (userData != null) {
      userData.favoriteProducts.removeWhere((p) => p.id == productId);
      await saveUserData(userData);
    }
  }

  /// Get all routines
  List<Routine> getAllRoutines() {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    final routines = <Routine>[];
    for (final key in _routinesBox.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('${userId}_')) {
        final routine = _routinesBox.get(key);
        if (routine != null) {
          routines.add(routine);
        }
      }
    }
    return routines;
  }

  /// Add routine
  Future<void> addRoutine(Routine routine) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    // Save to routines box with user-specific ID
    final routineId = '${userId}_${routine.id}';
    routine.id = routineId;
    await _routinesBox.put(routineId, routine);

    // Update user data
    final userData = getCurrentUserData();
    if (userData != null) {
      userData.routines.add(routine);
      await saveUserData(userData);
    }
  }

  /// Update routine
  Future<void> updateRoutine(Routine routine) async {
    // Update in routines box
    await _routinesBox.put(routine.id, routine);

    // Update in user data
    final userData = getCurrentUserData();
    if (userData != null) {
      final index = userData.routines.indexWhere((r) => r.id == routine.id);
      if (index != -1) {
        userData.routines[index] = routine;
        await saveUserData(userData);
      }
    }
  }

  /// Delete routine
  Future<void> deleteRoutine(String routineId) async {
    final userData = getCurrentUserData();
    if (userData == null) return;

    // Remove from routines box
    await _routinesBox.delete(routineId);

    // Remove from user data
    userData.routines.removeWhere((r) => r.id == routineId);
    await saveUserData(userData);
  }

  /// Complete routine
  Future<void> completeRoutine(String routineId) async {
    try {
      final userData = getCurrentUserData();
      if (userData == null) return;

      // Find routine in both box and user data
      final routine = _routinesBox.get(routineId);
      if (routine == null) return;

      // Check if already completed today
      final today = DateTime.now();
      final isCompletedToday = routine.completionHistory.any((date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day);

      if (!isCompletedToday) {
        // Update routine in box
        routine.completedCount++;
        routine.completionHistory.add(today);
        await _routinesBox.put(routineId, routine);

        // Update routine in user data
        final userRoutineIndex =
            userData.routines.indexWhere((r) => r.id == routineId);
        if (userRoutineIndex != -1) {
          userData.routines[userRoutineIndex].completedCount =
              routine.completedCount;
          userData.routines[userRoutineIndex].completionHistory =
              routine.completionHistory;

          // Update streak and achievements
          userData.updateStreak();
          userData.checkAchievements();
          await saveUserData(userData);
        }
      }
    } catch (e) {
      debugPrint('Error completing routine: $e');
      rethrow;
    }
  }

  /// Get achievements
  List<Achievement> getAchievements() {
    final userData = getCurrentUserData();
    return userData?.achievements ?? [];
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    final userData = getCurrentUserData();
    if (userData != null) {
      userData.userProfile = profile;
      await saveUserData(userData);
    }
  }

  /// Get app settings
  Map<String, dynamic> getAppSettings() {
    final settings = <String, dynamic>{};
    for (final key in _settingsBox.keys) {
      if (key != _currentUserKey) {
        settings[key.toString()] = _settingsBox.get(key);
      }
    }
    return settings;
  }

  /// Save app setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  /// Get setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Clear all data (for logout or reset)
  Future<void> clearAllData() async {
    final userId = getCurrentUserId();
    if (userId != null) {
      // Delete user-specific routines and products
      for (final key in _routinesBox.keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith('${userId}_')) {
          await _routinesBox.delete(key);
        }
      }

      for (final key in _productsBox.keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith('${userId}_')) {
          await _productsBox.delete(key);
        }
      }
    }

    await _usersBox.clear();
    await _routinesBox.clear();
    await _productsBox.clear();
    await _settingsBox.clear();
  }

  /// Get streak information
  int getCurrentStreak() {
    final userData = getCurrentUserData();
    return userData?.streakDays ?? 0;
  }

  /// Close all boxes
  Future<void> closeBoxes() async {
    await _usersBox.close();
    await _routinesBox.close();
    await _productsBox.close();
    await _settingsBox.close();
  }
}
