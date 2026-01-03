class OnboardingItem {
  final String title;
  final String description;
  final String imageUrl;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imageUrl,
  });
}

// Sample onboarding data
List<OnboardingItem> onboardingItems = [
  OnboardingItem(
    title: "Find Your Perfect Match",
    description: "Discover people who share your interests and values",
    imageUrl: "assets/images/couple1.jpg",
  ),
  OnboardingItem(
    title: "Create Date Offers",
    description: "Suggest fun activities and find someone to join you",
    imageUrl: "assets/images/couple2.jpg",
  ),
  OnboardingItem(
    title: "Safe and Secure",
    description: "Your privacy and safety are our top priorities",
    imageUrl: "assets/images/couple3.jpg",
  ),
];
