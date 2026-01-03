import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/provider/reviews_controller.dart';
import '../../models/review_models.dart';

class ProviderReviewsScreen extends StatelessWidget {
  const ProviderReviewsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(ReviewsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        actions: [
          PopupMenuButton<String>(
            initialValue: controller.selectedFilter.value,
            onSelected: (value) {
              controller.changeFilter(value);
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All Reviews')),
                  const PopupMenuItem(
                    value: 'positive',
                    child: Text('Positive Reviews'),
                  ),
                  const PopupMenuItem(
                    value: 'negative',
                    child: Text('Negative Reviews'),
                  ),
                ],
          ),
        ],
      ),
      body: Obx(
        () =>
            controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Obx(
                                    () => Text(
                                      controller.averageRating.value
                                          .toStringAsFixed(1),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineLarge?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Obx(
                                        () => Row(
                                          children: List.generate(
                                            5,
                                            (index) => Icon(
                                              Icons.star,
                                              size: 16,
                                              color:
                                                  index <
                                                          controller
                                                              .averageRating
                                                              .value
                                                      ? Colors.amber
                                                      : Colors.grey[300],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Obx(
                                        () => Text(
                                          '${controller.filteredReviews.length} reviews',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Rating distribution
                              ...List.generate(5, (index) {
                                final rating = 5 - index;
                                return Obx(() {
                                  final count =
                                      controller
                                          .ratingDistribution
                                          .value[rating] ??
                                      0;
                                  final percentage =
                                      controller.reviews.isEmpty
                                          ? 0.0
                                          : count / controller.reviews.length;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Text('$rating'),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: percentage,
                                            backgroundColor: Colors.grey[200],
                                            valueColor: AlwaysStoppedAnimation<
                                              Color
                                            >(Theme.of(context).primaryColor),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('$count'),
                                      ],
                                    ),
                                  );
                                });
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Reviews list
                      Text(
                        'Reviews',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () =>
                            controller.filteredReviews.isEmpty
                                ? const Center(child: Text('No reviews yet'))
                                : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: controller.filteredReviews.length,
                                  itemBuilder: (context, index) {
                                    final review =
                                        controller.filteredReviews[index];
                                    final seeker =
                                        controller.seekers.value[review
                                            .seekerId];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundImage:
                                                      seeker?.profileImage !=
                                                              null
                                                          ? NetworkImage(
                                                            seeker!
                                                                .profileImage,
                                                          )
                                                          : null,
                                                  child:
                                                      seeker?.profileImage ==
                                                              null
                                                          ? const Icon(
                                                            Icons.person,
                                                          )
                                                          : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        seeker?.name ??
                                                            'Anonymous',
                                                        style:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .titleMedium,
                                                      ),
                                                      Text(
                                                        review.timestamp
                                                            .toString()
                                                            .split(' ')[0],
                                                        style:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: List.generate(
                                                    5,
                                                    (index) => Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color:
                                                          index < review.rating
                                                              ? Colors.amber
                                                              : Colors
                                                                  .grey[300],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (review.comment != null &&
                                                review.comment!.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Text(review.comment!),
                                            ],
                                            if (review.images.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                height: 80,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount:
                                                      review.images.length,
                                                  itemBuilder: (
                                                    context,
                                                    imageIndex,
                                                  ) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 8,
                                                          ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        child: Image.network(
                                                          review
                                                              .images[imageIndex],
                                                          height: 80,
                                                          width: 80,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
