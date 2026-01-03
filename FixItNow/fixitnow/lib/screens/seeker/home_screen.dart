import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/seeker/home_controller.dart';
import '../../routes.dart';
import '../../widgets/common/index.dart';

class SeekerHomeScreen extends StatelessWidget {
  const SeekerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(SeekerHomeController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Get.toNamed(AppRoutes.search);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Get.toNamed(AppRoutes.notifications);
            },
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: controller.loadHomeData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.search);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.search),
                              SizedBox(width: 8),
                              Text('What service do you need?'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Popular Categories
                      SectionHeader(
                        title: 'Popular Categories',
                      ),
                      const SizedBox(height: 16),
                      _buildPopularCategories(context, controller),
                      const SizedBox(height: 24),

                      // Top Providers
                      SectionHeader(
                        title: 'Top Providers',
                        actionText: 'See All',
                        onAction: () {
                          Get.toNamed(AppRoutes.providerListing);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTopProviders(context, controller),
                      const SizedBox(height: 24),

                      // Featured Services
                      SectionHeader(
                        title: 'Featured Services',
                      ),
                      const SizedBox(height: 16),
                      _buildFeaturedServices(context, controller),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.quickBooking);
        },
        child: const Icon(Icons.flash_on),
        tooltip: 'Quick Booking',
      ),
    );
  }

  Widget _buildPopularCategories(BuildContext context, SeekerHomeController controller) {
    return SizedBox(
      height: 120,
      child: Obx(
        () => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.popularCategories.length,
          itemBuilder: (context, index) {
            final category = controller.popularCategories[index];
            return GestureDetector(
              onTap: () {
                Get.toNamed(
                  AppRoutes.categoryServices,
                  arguments: {'category': category},
                );
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Icon(
                        category.icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopProviders(BuildContext context, SeekerHomeController controller) {
    return Obx(
      () => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.topProviders.take(3).length,
        itemBuilder: (context, index) {
          final provider = controller.topProviders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: provider.profileImage.isNotEmpty
                    ? NetworkImage(provider.profileImage)
                    : null,
                child: provider.profileImage.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(provider.businessName),
              subtitle: RatingDisplay(
                rating: provider.rating,
                reviewCount: provider.reviewCount,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed(
                  AppRoutes.providerProfile,
                  arguments: {'providerId': provider.id},
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedServices(BuildContext context, SeekerHomeController controller) {
    return Obx(
      () => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: controller.featuredServices.length,
        itemBuilder: (context, index) {
          final service = controller.featuredServices[index];
          return GestureDetector(
            onTap: () {
              Get.toNamed(
                AppRoutes.serviceDetails,
                arguments: {'serviceId': service.id},
              );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.images.isNotEmpty)
                    Image.network(
                      service.images.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${service.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}