import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage tip article opening count for alternating interstitial ads
/// Pattern: 1st = NO ads, 2nd = WITH ads, 3rd = NO ads, 4th = WITH ads, etc.
class TipArticleCounterService extends ChangeNotifier {
  static const String _tipCountKey = 'tip_article_opening_count';
  int _tipArticleCount = 0;

  /// Get current tip article opening count
  int get tipArticleCount => _tipArticleCount;

  /// Check if current article should show ads
  /// Returns true for even counts (2nd, 4th, 6th article...)
  /// Returns false for odd counts (1st, 3rd, 5th article...)
  bool get shouldShowAdsForCurrentArticle {
    // Even numbers (2, 4, 6, 8...) = WITH ads
    // Odd numbers (1, 3, 5, 7...) = NO ads
    return _tipArticleCount % 2 == 0;
  }

  /// Initialize the service and load saved count
  Future<void> initialize() async {
    await _loadTipCount();
    debugPrint(
        '🔢 TipArticleCounterService initialized - Current count: $_tipArticleCount');
  }

  /// Increment tip article count when a new tip detail is opened
  Future<void> incrementTipArticleCount() async {
    _tipArticleCount++;
    await _saveTipCount();
    notifyListeners();

    debugPrint('📖 Tip article opened! Count: $_tipArticleCount');
    debugPrint(
        '🎯 Next article will ${shouldShowAdsForCurrentArticle ? 'SHOW' : 'SKIP'} interstitial ads');
  }

  /// Load tip count from SharedPreferences
  Future<void> _loadTipCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _tipArticleCount = prefs.getInt(_tipCountKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Error loading tip count: $e');
      _tipArticleCount = 0;
    }
  }

  /// Save tip count to SharedPreferences
  Future<void> _saveTipCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_tipCountKey, _tipArticleCount);
    } catch (e) {
      debugPrint('❌ Error saving tip count: $e');
    }
  }

  /// Reset tip count (for testing/debugging)
  Future<void> resetTipCount() async {
    _tipArticleCount = 0;
    await _saveTipCount();
    notifyListeners();
    debugPrint('🔄 Tip article count reset to 0');
  }

  /// Get detailed status for debugging
  String getDebugStatus() {
    return '''
📊 TIP ARTICLE COUNTER STATUS:
📖 Articles opened: $_tipArticleCount
🎯 Current article ads: ${shouldShowAdsForCurrentArticle ? 'SHOW INTERSTITIAL' : 'NO ADS'}
📋 Pattern: Odd count = NO ads, Even count = WITH ads
''';
  }
}
