import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:package_info_plus/package_info_plus.dart';

/// A service class for providing utility functions throughout the app
class UtilityService {
  // Singleton instance
  static final UtilityService _instance = UtilityService._internal();
  factory UtilityService() => _instance;
  UtilityService._internal();

  // Format currency amounts
  String formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  // Format dates in a readable way
  String formatDate(DateTime date, {String format = 'MMM d, yyyy'}) {
    return DateFormat(format).format(date);
  }

  // Format time in a readable way
  String formatTime(DateTime time, {bool use24HourFormat = false}) {
    return DateFormat(use24HourFormat ? 'HH:mm' : 'h:mm a').format(time);
  }

  // Parse string to DateTime
  DateTime? parseDate(String dateStr, {String format = 'yyyy-MM-dd'}) {
    try {
      return DateFormat(format).parse(dateStr);
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return null;
    }
  }

  // Calculate the difference between two dates in days
  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Check if a date is today
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if a date is tomorrow
  bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // Get a friendly relative date string (Today, Tomorrow, etc.)
  String getRelativeDateString(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else {
      final difference = daysBetween(DateTime.now(), date);
      if (difference < 7) {
        return DateFormat('EEEE').format(date); // Day of week
      } else {
        return formatDate(date);
      }
    }
  }

  // Truncate a string to a maximum length with ellipsis
  String truncateString(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  // Format a phone number nicely
  String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    } else if (digitsOnly.length == 11 && digitsOnly[0] == '1') {
      return '${digitsOnly[0]} (${digitsOnly.substring(1, 4)}) ${digitsOnly.substring(4, 7)}-${digitsOnly.substring(7)}';
    }

    return phoneNumber; // Return as is if it doesn't match expected formats
  }

  // Convert a DateTime to a readable "time ago" format
  String timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Open URL in browser - COMMENTED OUT DUE TO MISSING PACKAGE
  Future<bool> launchURL(String url) async {
    // Placeholder implementation since url_launcher is missing
    debugPrint('Would launch URL: $url');
    return false;
  }

  // Make a phone call - COMMENTED OUT DUE TO MISSING PACKAGE
  Future<bool> makePhoneCall(String phoneNumber) async {
    // Placeholder implementation since url_launcher is missing
    debugPrint('Would call phone number: $phoneNumber');
    return false;
  }

  // Send an email - COMMENTED OUT DUE TO MISSING PACKAGE
  Future<bool> sendEmail(
    String email, {
    String subject = '',
    String body = '',
  }) async {
    // Placeholder implementation since url_launcher is missing
    debugPrint('Would send email to: $email, subject: $subject');
    return false;
  }

  // Open map with coordinates - COMMENTED OUT DUE TO MISSING PACKAGE
  Future<bool> openMap(
    double latitude,
    double longitude, {
    String label = '',
  }) async {
    // Placeholder implementation since url_launcher is missing
    debugPrint('Would open map at: $latitude, $longitude');
    return false;
  }

  // Get directions to a location - COMMENTED OUT DUE TO MISSING PACKAGE
  Future<bool> getDirections(double latitude, double longitude) async {
    // Placeholder implementation since url_launcher is missing
    debugPrint('Would get directions to: $latitude, $longitude');
    return false;
  }

  // Compress an image file - COMMENTED OUT DUE TO MISSING PACKAGE
  Future<File?> compressImage(File file, {int quality = 80}) async {
    // Placeholder implementation since flutter_image_compress is missing
    debugPrint('Would compress image: ${file.path} with quality: $quality');
    return file; // Return the original file
  }

  // Share content - COMMENTED OUT DUE TO MISSING PACKAGE
  Future<void> shareContent(
    String text, {
    String? subject,
    List<File>? files,
  }) async {
    // Placeholder implementation since share_plus is missing
    debugPrint('Would share content: $text');
  }

  // Show a loading dialog
  void showLoading({String message = 'Loading...'}) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Hide the loading dialog
  void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // Show a confirmation dialog
  Future<bool> showConfirmationDialog({
    String title = 'Confirm',
    required String message,
    String confirmText = 'Yes',
    String cancelText = 'No',
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Get device info - COMMENTED OUT DUE TO MISSING PACKAGE
  Future<Map<String, dynamic>> getDeviceInfo() async {
    // Placeholder implementation since device_info_plus is missing
    return {
      'deviceType':
          Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Unknown'),
      'model': 'Unknown',
    };
  }

  // Get app version - COMMENTED OUT DUE TO MISSING PACKAGE
  Future<String> getAppVersion() async {
    // Placeholder implementation since package_info_plus is missing
    return '1.0.0+1';
  }

  // Generate a random color based on a string (for avatars, etc.)
  Color getColorFromString(String string) {
    // Generate a consistent color based on string content
    int hash = 0;
    for (var i = 0; i < string.length; i++) {
      hash = string.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final finalHash = hash.abs() % 360;
    return HSLColor.fromAHSL(1.0, finalHash.toDouble(), 0.6, 0.6).toColor();
  }

  // Get initials from a name
  String getInitials(String name) {
    if (name.isEmpty) return '';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '';
  }
}
