// screens/provider/profile_screen.dart
// Provider profile screen

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/provider/profile_controller.dart';
import '../../routes.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.pushNamed(context, AppRoutes.providerSettings),
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
                      // Profile header with image and basic info
                      _buildProfileHeader(controller),
                      const SizedBox(height: 24),

                      // Navigation menu items
                      _buildMenuSection('Account', [
                        _buildMenuItem(
                          'Settings',
                          Icons.settings,
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.providerSettings,
                          ),
                        ),
                        _buildMenuItem(
                          'Professional Details',
                          Icons.business,
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.professionalDetails,
                          ),
                        ),
                        _buildMenuItem(
                          'Portfolio Management',
                          Icons.photo_library,
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.portfolioManagement,
                          ),
                        ),
                      ]),

                      // More menu sections as needed
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(ProfileController controller) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                controller.provider.value!.profileImage.isNotEmpty
                    ? NetworkImage(controller.provider.value!.profileImage)
                    : null,
            child:
                controller.provider.value!.profileImage.isEmpty
                    ? const Icon(Icons.person, size: 50)
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            controller.provider.value!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            controller.provider.value!.businessName,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${controller.provider.value!.rating} (${controller.provider.value!.completedJobs} jobs)',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
