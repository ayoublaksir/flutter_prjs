import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/service_models.dart';
import '../../routes.dart';

class SavedServicesScreen extends StatefulWidget {
  const SavedServicesScreen({Key? key}) : super(key: key);

  @override
  State<SavedServicesScreen> createState() => _SavedServicesScreenState();
}

class _SavedServicesScreenState extends State<SavedServicesScreen> {
  final ServiceAPI _serviceAPI = ServiceAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  List<ProviderService> _savedServices = [];

  @override
  void initState() {
    super.initState();
    _loadSavedServices();
  }

  Future<void> _loadSavedServices() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final services = await _serviceAPI.getSavedServices(user.uid);
        setState(() => _savedServices = services);
      }
    } catch (e) {
      print('Error loading saved services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading saved services')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromSaved(String serviceId) async {
    try {
      await _serviceAPI.removeFromFavorites(serviceId);
      setState(() {
        _savedServices.removeWhere((service) => service.id == serviceId);
      });
    } catch (e) {
      print('Error removing service: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error removing service')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Services')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _savedServices.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text('No saved services'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.search);
                      },
                      child: const Text('Browse Services'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _savedServices.length,
                itemBuilder: (context, index) {
                  final service = _savedServices[index];
                  return Dismissible(
                    key: Key(service.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _removeFromSaved(service.id);
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.serviceDetails,
                            arguments: {'serviceId': service.id},
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (service.images.isNotEmpty)
                              Image.network(
                                service.images.first,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    service.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${service.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.bookingForm,
                                            arguments: {
                                              'serviceId': service.id,
                                            },
                                          );
                                        },
                                        child: const Text('Book Now'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
