// services/storage_services.dart
// Storage services for handling file uploads and retrievals

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile image
  Future<String> uploadProfileImage(String userId, XFile image) async {
    try {
      // Convert XFile to File
      final file = File(image.path);

      final storageRef = _storage.ref().child('profile_images/$userId');
      final uploadTask = await storageRef.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }

  // Upload work gallery image
  Future<String> uploadGalleryImage(String providerId, File imageFile) async {
    try {
      // Create storage reference with timestamp to ensure uniqueness
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = _storage.ref().child(
        'provider_gallery/$providerId/${timestamp}_${path.basename(imageFile.path)}',
      );

      // Upload file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading gallery image: $e');
      rethrow;
    }
  }

  // Upload service image
  Future<String> uploadServiceImage(String serviceId, File imageFile) async {
    try {
      // Create storage reference
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = _storage.ref().child(
        'service_images/$serviceId/${timestamp}_${path.basename(imageFile.path)}',
      );

      // Upload file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading service image: $e');
      rethrow;
    }
  }

  // Upload chat image
  Future<String> uploadChatImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'chat_images/$fileName';

      // Upload to Firebase Storage
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      // Get download URL
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error uploading chat image: $e');
      return '';
    }
  }

  // Upload review image
  Future<String> uploadReviewImage(String reviewId, File imageFile) async {
    try {
      // Create storage reference
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = _storage.ref().child(
        'review_images/$reviewId/${timestamp}_${path.basename(imageFile.path)}',
      );

      // Upload file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading review image: $e');
      rethrow;
    }
  }

  // Upload portfolio image
  Future<String> uploadPortfolioImage(String userId, XFile image) async {
    final fileName = path.basename(image.path);
    final destination = 'providers/$userId/portfolio/$fileName';
    final ref = _storage.ref().child(destination);

    final uploadTask = ref.putFile(File(image.path));
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  // Delete file from storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  // Delete portfolio image
  Future<void> deletePortfolioImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
      rethrow;
    }
  }
}

// Local storage service for device persistence
class LocalStorageService {
  // Save token
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  // Get token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  // Remove token
  Future<void> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      debugPrint('Error removing token: $e');
    }
  }

  // Save user role
  Future<void> saveUserRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
    } catch (e) {
      debugPrint('Error saving user role: $e');
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_role');
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  // Save user ID
  Future<void> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
    } catch (e) {
      debugPrint('Error saving user ID: $e');
    }
  }

  // Get user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  // Save app settings
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save individual settings
      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }
    } catch (e) {
      debugPrint('Error saving app settings: $e');
    }
  }

  // Get app settings
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
        'email_notifications': prefs.getBool('email_notifications') ?? true,
        'location_tracking': prefs.getBool('location_tracking') ?? true,
        'dark_mode': prefs.getBool('dark_mode') ?? false,
        'language': prefs.getString('language') ?? 'en',
      };
    } catch (e) {
      debugPrint('Error getting app settings: $e');
      // Return default settings
      return {
        'notifications_enabled': true,
        'email_notifications': true,
        'location_tracking': true,
        'dark_mode': false,
        'language': 'en',
      };
    }
  }

  // Save recent searches
  Future<void> saveRecentSearches(List<String> searches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', searches);
    } catch (e) {
      debugPrint('Error saving recent searches: $e');
    }
  }

  // Get recent searches
  Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('recent_searches') ?? [];
    } catch (e) {
      debugPrint('Error getting recent searches: $e');
      return [];
    }
  }

  // Add search to recent searches
  Future<void> addRecentSearch(String search) async {
    try {
      final searches = await getRecentSearches();

      // Remove if already exists
      searches.remove(search);

      // Add to beginning
      searches.insert(0, search);

      // Keep only the last 10 searches
      if (searches.length > 10) {
        searches.removeRange(10, searches.length);
      }

      await saveRecentSearches(searches);
    } catch (e) {
      debugPrint('Error adding recent search: $e');
    }
  }

  // Clear recent searches
  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }
}
