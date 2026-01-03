import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_services.dart';
import '../../models/review_models.dart';
import '../../models/user_models.dart';
import '../base_controller.dart';

class ReviewsController extends BaseController {
  // Services via dependency injection
  final ReviewAPI _reviewAPI = Get.find<ReviewAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();
  final RxList<Review> reviews = <Review>[].obs;
  final RxList<Review> filteredReviews = <Review>[].obs;
  final Rx<Map<String, ServiceSeeker>> seekers = Rx<Map<String, ServiceSeeker>>(
    {},
  );
  final RxString selectedFilter = 'all'.obs; // all, positive, negative
  final RxDouble averageRating = 0.0.obs;
  final Rx<Map<int, int>> ratingDistribution = Rx<Map<int, int>>({});

  @override
  void onInit() {
    super.onInit();
    
    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      await loadReviews();
    });
  }

  Future<void> loadReviews() async {
    // No need for try-catch block as it's handled by runWithLoading
    final userId = currentUserId;
    if (userId.isEmpty) {
      showError('User not authenticated');
      return;
    }
    
    // Load all reviews
    final reviewData = await _reviewAPI.getProviderReviews(userId);

    // Load seeker details for all reviews
    final seekerIds = reviewData.map((r) => r.seekerId).toSet();
    final seekerProfiles = await Future.wait(
      seekerIds.map((id) => _userAPI.getSeekerProfile(id)),
    );

    // Calculate statistics
    double totalRating = 0;
    final distribution = <int, int>{};
    for (final review in reviewData) {
      totalRating += review.rating;
      distribution[review.rating.toInt()] =
          (distribution[review.rating.toInt()] ?? 0) + 1;
    }

    reviews.value = reviewData.cast<Review>();
    filteredReviews.value = filterReviews(reviews);

    Map<String, ServiceSeeker> seekersMap = {};
    for (var seeker in seekerProfiles.whereType<ServiceSeeker>()) {
      seekersMap[seeker.id] = seeker;
    }
    seekers.value = seekersMap;

    averageRating.value =
        reviewData.isEmpty ? 0 : totalRating / reviewData.length;
    ratingDistribution.value = distribution;
  }

  List<Review> filterReviews(List<Review> reviewsList) {
    switch (selectedFilter.value) {
      case 'positive':
        return reviewsList.where((r) => r.rating >= 4).toList();
      case 'negative':
        return reviewsList.where((r) => r.rating <= 2).toList();
      default:
        return reviewsList;
    }
  }

  void changeFilter(String filter) {
    if (selectedFilter.value == filter) return;
    
    selectedFilter.value = filter;
    filteredReviews.value = filterReviews(reviews);
  }
}
