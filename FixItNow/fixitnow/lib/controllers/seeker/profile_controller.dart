import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_services.dart';
import '../../services/storage_services.dart';
import '../../models/user_models.dart';
import '../base_controller.dart';

class SeekerProfileController extends BaseController {
  // Services via dependency injection
  final UserAPI _userAPI = Get.find<UserAPI>();
  final StorageService _storageServices = Get.find<StorageService>();
  final ImagePicker _imagePicker = ImagePicker();
  final Rx<ServiceSeeker?> profile = Rx<ServiceSeeker?>(null);
  final RxString profileImageUrl = ''.obs;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();

    // Use the runWithLoading method from BaseController
    runWithLoading(() async {
      await loadProfile();
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }

  Future<void> loadProfile() async {
    // No need for try-catch block as it's handled by runWithLoading
    final userId = currentUserId;
    if (userId.isEmpty) {
      showError('User not authenticated');
      return;
    }

    final userProfile = await _userAPI.getSeekerProfile(userId);
    if (userProfile != null) {
      profile.value = userProfile;
      profileImageUrl.value = userProfile.profileImage ?? '';
      nameController.text = userProfile.name;
      emailController.text = userProfile.email;
      phoneController.text = userProfile.phone ?? '';
      addressController.text = userProfile.address ?? '';
    }
  }

  Future<void> updateProfile() {
    if (!formKey.currentState!.validate()) {
      showError('Please fill all required fields correctly');
      return Future.value();
    }

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      if (profile.value != null) {
        final updatedProfile = profile.value!.copyWith(
          name: nameController.text,
          phone: phoneController.text,
          address: addressController.text,
          profileImage: profileImageUrl.value,
        );

        await _userAPI.updateSeekerProfile(updatedProfile);
        profile.value = updatedProfile;

        showSuccess('Profile updated successfully');
      }
    });
  }

  Future<void> pickImage() {
    return runWithLoading(() async {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null && profile.value != null) {
        final imageUrl = await _storageServices.uploadProfileImage(
          profile.value!.id,
          image,
        );

        profileImageUrl.value = imageUrl;

        // Update profile with new image
        await updateProfile();
      }
    });
  }

  /// Detect changes in form
  void onFormChanged() {
    // Compare current values with original values
    final profileData = profile.value;
    if (profileData == null) return;

    final hasChanges =
        nameController.text != profileData.name ||
        phoneController.text != (profileData.phone ?? '') ||
        addressController.text != (profileData.address ?? '');

    if (hasChanges) {
      showInfo('You have unsaved changes');
    }
  }

  /// Discard changes
  void discardChanges() {
    if (profile.value == null) return;

    // Reset form controllers to original values
    nameController.text = profile.value!.name;
    emailController.text = profile.value!.email;
    phoneController.text = profile.value!.phone ?? '';
    addressController.text = profile.value!.address ?? '';

    showInfo('Changes discarded');
  }
}
