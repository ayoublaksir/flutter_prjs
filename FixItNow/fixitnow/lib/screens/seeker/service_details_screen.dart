import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../models/service_models.dart';
import '../../models/user_models.dart';
import '../../routes.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({Key? key, required this.serviceId})
    : super(key: key);

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final ServiceAPI _serviceAPI = ServiceAPI();
  final UserAPI _userAPI = UserAPI();

  bool _isLoading = true;
  ProviderService? _service;
  ServiceProvider? _provider;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    setState(() => _isLoading = true);

    try {
      final service = await _serviceAPI.getServiceDetails(widget.serviceId);
      if (service != null) {
        final provider = await _userAPI.getProviderProfile(service.providerId);
        final isFavorite = await _serviceAPI.isServiceFavorite(
          widget.serviceId,
        );

        setState(() {
          _service = service;
          _provider = provider;
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      print('Error loading service details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading service details')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final newState = !_isFavorite;
      if (newState) {
        await _serviceAPI.addToFavorites(widget.serviceId);
      } else {
        await _serviceAPI.removeFromFavorites(widget.serviceId);
      }
      setState(() => _isFavorite = newState);
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error updating favorites')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_service == null) {
      return const Scaffold(body: Center(child: Text('Service not found')));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: PageView.builder(
                itemCount: _service!.images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    _service!.images[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Implement share functionality
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _service!.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${_service!.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _service!.priceType,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Provider information
                  if (_provider != null) ...[
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            _provider!.profileImage != null
                                ? NetworkImage(_provider!.profileImage!)
                                : null,
                        child:
                            _provider!.profileImage == null
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      title: Text(_provider!.businessName),
                      subtitle: Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(
                            ' ${_provider!.rating.toStringAsFixed(1)} (${_provider!.reviewCount})',
                          ),
                        ],
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.providerProfile,
                            arguments: {'providerId': _provider!.id},
                          );
                        },
                        child: const Text('View Profile'),
                      ),
                    ),
                    const Divider(),
                  ],

                  // Service description
                  Text(
                    'About this service',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(_service!.description),
                  const SizedBox(height: 24),

                  // What's included
                  Text(
                    'What\'s Included',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _service!.inclusions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.check_circle),
                        title: Text(_service!.inclusions[index]),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Additional options
                  if (_service!.additionalOptions.isNotEmpty) ...[
                    Text(
                      'Additional Options',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _service!.additionalOptions.length,
                      itemBuilder: (context, index) {
                        final option = _service!.additionalOptions[index];
                        return ListTile(
                          title: Text(option.name),
                          subtitle: Text(option.description),
                          trailing: Text(
                            '+\$${option.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.bookingForm,
                arguments: {'serviceId': widget.serviceId},
              );
            },
            child: const Text('Book Now'),
          ),
        ),
      ),
    );
  }
}
