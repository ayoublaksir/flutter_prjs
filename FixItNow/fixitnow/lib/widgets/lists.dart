// widgets/lists.dart
// Reusable list components

import 'package:flutter/material.dart';
import '../models/service_models.dart';
import '../models/user_models.dart';
import '../models/booking_models.dart';
import '../widgets/cards.dart';
import '../routes.dart';

// Service Category List
class ServiceCategoryList extends StatelessWidget {
  final List<ServiceCategory> categories;

  const ServiceCategoryList({Key? key, required this.categories})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories available'));
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            width: 100,
            margin: EdgeInsets.only(
              right: index == categories.length - 1 ? 0 : 16,
            ),
            child: ServiceCategoryCard(
              category: category,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.categoryServices,
                  arguments: {'categoryId': category.id},
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Service Item List
class ServiceItemList extends StatelessWidget {
  final List<ServiceItem> services;

  const ServiceItemList({Key? key, required this.services}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const Center(child: Text('No services available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ServiceItemCard(
            service: service,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.providerListing,
                arguments: {'serviceId': service.id},
              );
            },
          ),
        );
      },
    );
  }
}

// Service Provider List
class ServiceProviderList extends StatelessWidget {
  final List<ServiceProvider> providers;

  const ServiceProviderList({Key? key, required this.providers})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const Center(child: Text('No providers available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ProviderCard(
            provider: provider,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.providerProfile,
                arguments: {'providerId': provider.id},
              );
            },
          ),
        );
      },
    );
  }
}

// Booking List
class BookingList extends StatelessWidget {
  final List<dynamic> bookings;

  const BookingList({Key? key, required this.bookings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.bookingDetails,
              arguments: {'bookingId': booking.id},
            );
          },
        );
      },
    );
  }
}

// Review List
class ReviewList extends StatelessWidget {
  final List<Review> reviews;

  const ReviewList({Key? key, required this.reviews}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Center(child: Text('No reviews available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ReviewCard(review: review);
      },
    );
  }
}

// Settings List Item
class SettingsListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;

  const SettingsListItem({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// Horizontal Service Scroller
class HorizontalServiceScroller extends StatelessWidget {
  final List<ServiceItem> services;
  final String title;
  final VoidCallback? onViewAll;

  const HorizontalServiceScroller({
    Key? key,
    required this.services,
    required this.title,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (onViewAll != null)
              TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Container(
                width: 200,
                margin: EdgeInsets.only(
                  right: index == services.length - 1 ? 0 : 16,
                ),
                child: ServiceItemCard(
                  service: service,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.providerListing,
                      arguments: {'serviceId': service.id},
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Horizontal Provider Scroller
class HorizontalProviderScroller extends StatelessWidget {
  final List<ServiceProvider> providers;
  final String title;
  final VoidCallback? onViewAll;

  const HorizontalProviderScroller({
    Key? key,
    required this.providers,
    required this.title,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (onViewAll != null)
              TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Container(
                width: 250,
                margin: EdgeInsets.only(
                  right: index == providers.length - 1 ? 0 : 16,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.providerProfile,
                        arguments: {'providerId': provider.id},
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage:
                                    provider.profileImage.isNotEmpty
                                        ? NetworkImage(provider.profileImage)
                                        : null,
                                child:
                                    provider.profileImage.isEmpty
                                        ? const Icon(Icons.person, size: 24)
                                        : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.businessName.isNotEmpty
                                          ? provider.businessName
                                          : provider.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          provider.rating.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${provider.completedJobs})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.description.isNotEmpty
                                ? provider.description
                                : 'Professional service provider',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  provider.businessAddress.isNotEmpty
                                      ? provider.businessAddress
                                      : 'Location not specified',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
