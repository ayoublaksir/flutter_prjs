import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/seeker/profile_controller.dart';
import '../../routes.dart';
import '../../widgets/common/index.dart';

class SeekerProfileScreen extends StatelessWidget {
  const SeekerProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(SeekerProfileController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Get.toNamed(AppRoutes.settings);
            },
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      // Profile Image
                      _buildProfileImage(controller),
                      const SizedBox(height: 24),

                      // Profile Form
                      _buildProfileForm(controller),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(context),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(
          () => ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : controller.updateProfile,
            child: controller.isLoading.value
                ? const CircularProgressIndicator()
                : const Text('Save Changes'),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(SeekerProfileController controller) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Obx(
          () => ProfileAvatar(
            imageUrl: controller.profileImageUrl.value,
            radius: 60,
            iconSize: 60,
          ),
        ),
        FloatingActionButton.small(
          onPressed: controller.pickImage,
          child: const Icon(Icons.camera_alt),
        ),
      ],
    );
  }

  Widget _buildProfileForm(SeekerProfileController controller) {
    return Column(
      children: [
        TextFormField(
          controller: controller.nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: controller.emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          enabled: false, // Email cannot be changed
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: controller.phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: controller.addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        ActionCard(
          title: 'My Bookings',
          icon: Icons.calendar_today,
          onTap: () => Get.toNamed(AppRoutes.bookingHistory),
        ),
        ActionCard(
          title: 'Saved Services',
          icon: Icons.favorite,
          onTap: () => Get.toNamed(AppRoutes.savedServices),
        ),
        ActionCard(
          title: 'Payment Methods',
          icon: Icons.payment,
          onTap: () => Get.toNamed(AppRoutes.paymentMethods),
        ),
        ActionCard(
          title: 'Help & Support',
          icon: Icons.help,
          onTap: () => Get.toNamed(AppRoutes.helpSupport),
        ),
      ],
    );
  }
}