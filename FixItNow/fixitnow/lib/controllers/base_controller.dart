import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/auth_services.dart';

/// Base controller class that provides common functionality for all controllers
class BaseController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  final RxBool isLoading = false.obs;
  
  /// Get the current user from auth service
  get currentUser => _authService.currentUser;
  
  /// Get the current user ID or empty string if not logged in
  String get currentUserId => _authService.currentUser?.uid ?? '';
  
  /// Check if user is logged in
  bool get isLoggedIn => _authService.isLoggedIn;
  
  /// Check if user is a provider (assumes role is stored in user model)
  Future<bool> get isProvider async {
    if (!isLoggedIn) return false;
    
    // This would be implemented based on how roles are stored
    // For now, returning a placeholder
    return false;
  }
  
  /// Check if user is a seeker (assumes role is stored in user model)
  Future<bool> get isSeeker async {
    if (!isLoggedIn) return false;
    
    // This would be implemented based on how roles are stored
    // For now, returning a placeholder
    return false;
  }
  
  /// Show loading indicator
  void showLoading() {
    isLoading.value = true;
  }
  
  /// Hide loading indicator
  void hideLoading() {
    isLoading.value = false;
  }
  
  /// Show success snackbar
  void showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.7),
      colorText: Colors.white,
    );
  }
  
  /// Show error snackbar
  void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.7),
      colorText: Colors.white,
    );
  }
  
  /// Show info snackbar
  void showInfo(String message) {
    Get.snackbar(
      'Information',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withOpacity(0.7),
      colorText: Colors.white,
    );
  }
  
  /// Helper to run async code with loading state
  Future<T?> runWithLoading<T>(Future<T> Function() action) async {
    try {
      showLoading();
      return await action();
    } catch (e) {
      debugPrint('Error in runWithLoading: $e');
      showError('An error occurred');
      return null;
    } finally {
      hideLoading();
    }
  }
}