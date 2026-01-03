import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/service_models.dart';
import '../../models/user_models.dart';
import '../../services/api_services.dart';
import '../../services/location_services.dart';
import '../base_controller.dart';

class SearchController extends BaseController {
  // Services via dependency injection
  final ServiceAPI _serviceAPI = Get.find<ServiceAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();
  final LocationService _locationServices = Get.find<LocationService>();

  // Reactive state
  final RxList<ServiceCategory> categories = <ServiceCategory>[].obs;
  final RxList<ServiceItem> searchResults = <ServiceItem>[].obs;
  final RxList<ServiceItem> recentSearches = <ServiceItem>[].obs;
  final RxList<User> providerResults = <User>[].obs;

  // Search state
  final searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxBool showProviders = false.obs;

  // Filter state
  final RxDouble maxDistance = 50.0.obs;
  final RxDouble minRating = 0.0.obs;
  final RxDouble maxPrice = 1000.0.obs;
  final RxList<String> selectedCategories = <String>[].obs;
  final RxBool availableNow = false.obs;

  // Location
  final Rx<Map<String, double>?> currentLocation = Rx<Map<String, double>?>(
    null,
  );

  @override
  void onInit() {
    super.onInit();
    loadCategories();

    // Set up search listener
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      if (searchQuery.isNotEmpty) {
        performSearch();
      } else {
        searchResults.clear();
        providerResults.clear();
        isSearching.value = false;
      }
    });

    // Load user location
    _loadUserLocation();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load service categories
  Future<void> loadCategories() {
    return runWithLoading(() async {
      final result = await _serviceAPI.getServiceCategories();
      categories.value = result;
    });
  }

  /// Load user's recent searches
  Future<void> loadRecentSearches() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) return;

      final result = await _serviceAPI.getRecentSearches(userId);
      recentSearches.value = result;
    });
  }

  /// Load user location
  Future<void> _loadUserLocation() async {
    try {
      final location = await _locationServices.getCurrentLocation();
      if (location != null) {
        currentLocation.value = {
          'latitude': location.latitude ?? 0.0,
          'longitude': location.longitude ?? 0.0,
        };
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  /// Perform search
  void performSearch() {
    if (searchQuery.isEmpty) return;

    isSearching.value = true;

    // Debounce the search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (searchQuery.value == searchController.text) {
        _executeSearch();
      }
    });
  }

  /// Execute the search with API call
  Future<void> _executeSearch() async {
    try {
      // If we're showing providers, search for providers
      if (showProviders.value) {
        final providers = await _userAPI.searchProviders(
          query: searchQuery.value,
          filters: {
            'maxDistance': maxDistance.value,
            'minRating': minRating.value,
            'categories': selectedCategories,
            'availableNow': availableNow.value,
          },
          location: currentLocation.value,
        );
        providerResults.value = providers;
      }
      // Otherwise search for services
      else {
        final services = await _serviceAPI.searchServices(
          query: searchQuery.value,
          filters: {
            'maxDistance': maxDistance.value,
            'minRating': minRating.value,
            'maxPrice': maxPrice.value,
            'categories': selectedCategories,
            'availableNow': availableNow.value,
          },
          location: currentLocation.value,
        );
        searchResults.value = services;

        // Save to recent searches if user is logged in
        if (isLoggedIn) {
          _serviceAPI.saveSearch(currentUserId, searchQuery.value);
        }
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      showError('Failed to perform search');
    } finally {
      isSearching.value = false;
    }
  }

  /// Toggle search mode (services/providers)
  void toggleSearchMode(bool showProviders) {
    if (this.showProviders.value == showProviders) return;

    this.showProviders.value = showProviders;

    if (searchQuery.isNotEmpty) {
      _executeSearch();
    }
  }

  /// Update max distance filter
  void updateMaxDistance(double value) {
    maxDistance.value = value;
    applyFilters();
  }

  /// Update min rating filter
  void updateMinRating(double value) {
    minRating.value = value;
    applyFilters();
  }

  /// Update max price filter
  void updateMaxPrice(double value) {
    maxPrice.value = value;
    applyFilters();
  }

  /// Toggle category selection
  void toggleCategory(String categoryId) {
    if (selectedCategories.contains(categoryId)) {
      selectedCategories.remove(categoryId);
    } else {
      selectedCategories.add(categoryId);
    }
    applyFilters();
  }

  /// Toggle available now filter
  void toggleAvailableNow(bool value) {
    availableNow.value = value;
    applyFilters();
  }

  /// Apply all filters
  void applyFilters() {
    if (searchQuery.isNotEmpty) {
      _executeSearch();
    }
  }

  /// Reset all filters
  void resetFilters() {
    maxDistance.value = 50.0;
    minRating.value = 0.0;
    maxPrice.value = 1000.0;
    selectedCategories.clear();
    availableNow.value = false;

    if (searchQuery.isNotEmpty) {
      _executeSearch();
    }
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    searchResults.clear();
    providerResults.clear();
    isSearching.value = false;
  }

  /// Get category by ID
  ServiceCategory? getCategoryById(String id) {
    return categories.firstWhereOrNull((cat) => cat.id == id);
  }

  /// Format price
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Format rating
  String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Format distance
  String formatDistance(double distance) {
    if (distance < 1.0) {
      return '${(distance * 1000).toInt()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Navigate to service details
  void navigateToServiceDetails(String serviceId) {
    Get.toNamed('/service-details', arguments: {'serviceId': serviceId});
  }

  /// Navigate to provider profile
  void navigateToProviderProfile(String providerId) {
    Get.toNamed('/provider-profile', arguments: {'providerId': providerId});
  }
}
