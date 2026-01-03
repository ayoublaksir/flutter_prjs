import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/service_models.dart';

class ServiceFormController extends GetxController {
  final ServiceAPI _serviceAPI = ServiceAPI();
  final AuthService _authService = AuthService();
  
  final RxBool isLoading = false.obs;
  final RxString selectedCategoryId = ''.obs;
  
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    
    // Check if we have an existing service being edited
    if (Get.arguments != null && Get.arguments['service'] != null) {
      final service = Get.arguments['service'] as ProviderService;
      nameController.text = service.name;
      descriptionController.text = service.description;
      priceController.text = service.price.toString();
      selectedCategoryId.value = service.categoryId;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.onClose();
  }

  Future<void> saveService() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCategoryId.isEmpty) {
      Get.snackbar(
        'Error', 
        'Please select a category',
        snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    isLoading.value = true;

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final service = ProviderService(
          id: Get.arguments?['service']?.id ?? '',
          providerId: user.uid,
          serviceItemId: Get.arguments?['service']?.serviceItemId ?? selectedCategoryId.value,
          name: nameController.text,
          description: descriptionController.text,
          price: double.parse(priceController.text),
          categoryId: selectedCategoryId.value,
          isActive: true,
          images: Get.arguments?['service']?.images ?? [],
        );

        if (Get.arguments?['service'] == null) {
          await _serviceAPI.addProviderService(service);
        } else {
          await _serviceAPI.updateProviderService(service);
        }

        Get.back(result: true);
      }
    } catch (e) {
      debugPrint('Error saving service: $e');
      Get.snackbar(
        'Error',
        'Error saving service',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String categoryId) {
    selectedCategoryId.value = categoryId;
  }
}