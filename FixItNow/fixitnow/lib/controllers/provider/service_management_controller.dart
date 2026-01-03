import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/service_models.dart';

class ServiceManagementController extends GetxController {
  final ServiceAPI _serviceAPI = ServiceAPI();
  final AuthService _authService = AuthService();

  final RxBool isLoading = true.obs;
  final RxList<ProviderService> services = <ProviderService>[].obs;
  final RxList<ServiceCategory> categories = <ServiceCategory>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMockServices();
  }

  Future<void> loadMockServices() async {
    isLoading.value = true;

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    services.value = List.generate(
      3,
      (index) => ProviderService(
        id: 'service-$index',
        providerId: 'provider-1',
        serviceItemId: 'item-$index',
        name: 'Service ${index + 1}',
        description: 'This is a description for service ${index + 1}',
        price: 50.0 + (index * 25),
        categoryId: 'category-${index % 8}',
        isActive: true,
        images: [],
      ),
    );

    // Real service categories with subcategories
    categories.value = [
      ServiceCategory(
        id: 'category-0',
        name: 'Plumbing',
        description: 'Water systems, pipes, fixtures, and drainage services',
        icon: Icons.plumbing,
        imageUrl: 'assets/images/categories/plumbing.jpg',
        subcategories: [
          'Pipe Repair',
          'Drain Cleaning',
          'Fixture Installation',
          'Water Heater Services',
          'Leak Detection',
        ],
      ),
      ServiceCategory(
        id: 'category-1',
        name: 'Electrical',
        description: 'Wiring, lighting, electrical panels and installations',
        icon: Icons.electrical_services,
        imageUrl: 'assets/images/categories/electrical.jpg',
        subcategories: [
          'Wiring Installation',
          'Lighting Installation',
          'Electrical Panel Upgrades',
          'Smart Home Installation',
          'Electrical Repairs',
        ],
      ),
      ServiceCategory(
        id: 'category-2',
        name: 'Cleaning',
        description: 'Home cleaning, deep cleaning, and specialized cleaning services',
        icon: Icons.cleaning_services,
        imageUrl: 'assets/images/categories/cleaning.jpg',
        subcategories: [
          'Regular House Cleaning',
          'Deep Cleaning',
          'Move-in/Move-out Cleaning',
          'Carpet Cleaning',
          'Window Cleaning',
        ],
      ),
      ServiceCategory(
        id: 'category-3',
        name: 'Carpentry',
        description: 'Woodworking, furniture repair, and custom installations',
        icon: Icons.handyman,
        imageUrl: 'assets/images/categories/carpentry.jpg',
        subcategories: [
          'Furniture Repair',
          'Custom Cabinets',
          'Deck Construction',
          'Door Installation',
          'Trim Work',
        ],
      ),
      ServiceCategory(
        id: 'category-4',
        name: 'Painting',
        description: 'Interior and exterior painting services',
        icon: Icons.format_paint,
        imageUrl: 'assets/images/categories/painting.jpg',
        subcategories: [
          'Interior Painting',
          'Exterior Painting',
          'Cabinet Painting',
          'Deck & Fence Staining',
          'Wallpaper Installation',
        ],
      ),
      ServiceCategory(
        id: 'category-5',
        name: 'HVAC',
        description: 'Heating, ventilation, and air conditioning services',
        icon: Icons.hvac,
        imageUrl: 'assets/images/categories/hvac.jpg',
        subcategories: [
          'AC Installation & Repair',
          'Heating System Services',
          'Duct Cleaning',
          'Thermostat Installation',
          'HVAC Maintenance',
        ],
      ),
      ServiceCategory(
        id: 'category-6',
        name: 'Landscaping',
        description: 'Garden design, lawn care, and outdoor maintenance',
        icon: Icons.grass,
        imageUrl: 'assets/images/categories/landscaping.jpg',
        subcategories: [
          'Lawn Mowing',
          'Garden Design',
          'Tree Trimming',
          'Irrigation Systems',
          'Hardscaping',
        ],
      ),
      ServiceCategory(
        id: 'category-7',
        name: 'Appliance Repair',
        description: 'Repair and maintenance of household appliances',
        icon: Icons.kitchen,
        imageUrl: 'assets/images/categories/appliance.jpg',
        subcategories: [
          'Refrigerator Repair',
          'Washer/Dryer Repair',
          'Dishwasher Repair',
          'Oven & Range Repair',
          'Small Appliance Repair',
        ],
      ),
    ];

    isLoading.value = false;
  }

  // Original API call method (commented for now)
  /*
  Future<void> loadServices() async {
    isLoading.value = true;

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Load data in parallel
        final results = await Future.wait([
          _serviceAPI.getProviderServices(user.uid),
          _serviceAPI.getServiceCategories(),
        ]);

        services.value = results[0] as List<ProviderService>;
        categories.value = results[1] as List<ServiceCategory>;
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
    } finally {
      isLoading.value = false;
    }
  }
  */

  Future<void> deleteService(String serviceId) async {
    try {
      isLoading.value = true;
      await _serviceAPI.deleteProviderService(serviceId);
      loadMockServices();
    } catch (e) {
      debugPrint('Error deleting service: $e');
      Get.snackbar(
        'Error',
        'Error deleting service',
        snackPosition: SnackPosition.BOTTOM,
      );
      isLoading.value = false;
    }
  }
}