import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/provider_models.dart';
import '../../services/api_services.dart';
import '../../services/storage_services.dart';
import '../base_controller.dart';

class PortfolioController extends BaseController {
  // Services via dependency injection
  final UserAPI _userAPI = Get.find<UserAPI>();
  final StorageService _storageServices = Get.find<StorageService>();

  // Reactive state
  final RxList<PortfolioItem> portfolioItems = <PortfolioItem>[].obs;
  final RxList<File> selectedImages = <File>[].obs;

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadPortfolioItems();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Load portfolio items
  Future<void> loadPortfolioItems() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final items = await _userAPI.getProviderPortfolio(userId);
      portfolioItems.value = items;
    });
  }

  /// Add portfolio item
  Future<void> addPortfolioItem() {
    if (!formKey.currentState!.validate()) {
      showError('Please fill all required fields correctly');
      return Future.value();
    }

    if (selectedImages.isEmpty) {
      showError('Please select at least one image');
      return Future.value();
    }

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Upload images
      final List<String> imageUrls = [];
      for (final image in selectedImages) {
        final xFile = XFile(image.path);
        final url = await _storageServices.uploadPortfolioImage(userId, xFile);
        if (url.isNotEmpty) {
          imageUrls.add(url);
        }
      }

      if (imageUrls.isEmpty) {
        showError('Failed to upload images');
        return;
      }

      // Create portfolio item
      final item = PortfolioItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleController.text,
        description: descriptionController.text,
        images: imageUrls,
        createdAt: DateTime.now(),
      );

      // Add to database
      await _userAPI.addPortfolioItem(userId, item);

      // Update local state
      portfolioItems.add(item);

      // Reset form
      titleController.clear();
      descriptionController.clear();
      selectedImages.clear();

      showSuccess('Portfolio item added');
    });
  }

  /// Update portfolio item
  Future<void> updatePortfolioItem(String itemId) {
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

      // Find existing item
      final index = portfolioItems.indexWhere((item) => item?.id == itemId);
      if (index == -1) {
        showError('Portfolio item not found');
        return;
      }

      final existingItem = portfolioItems[index];

      // Upload new images if any
      List<String> updatedImageUrls = List.from(existingItem.images);

      for (final image in selectedImages) {
        final xFile = XFile(image.path);
        final url = await _storageServices.uploadPortfolioImage(userId, xFile);
        if (url.isNotEmpty) {
          updatedImageUrls.add(url);
        }
      }

      // Create updated item
      final updatedItem = PortfolioItem(
        id: existingItem.id,
        title: titleController.text,
        description: descriptionController.text,
        images: updatedImageUrls,
        createdAt: existingItem.createdAt,
      );

      // Update in database
      await _userAPI.updatePortfolioItem(userId, updatedItem);

      // Update local state
      portfolioItems[index] = updatedItem;

      // Reset form
      titleController.clear();
      descriptionController.clear();
      selectedImages.clear();

      showSuccess('Portfolio item updated');
    });
  }

  /// Delete portfolio item
  Future<void> deletePortfolioItem(String itemId) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Delete from database
      await _userAPI.deletePortfolioItem(userId, itemId);

      // Update local state
      portfolioItems.removeWhere((item) => item?.id == itemId);

      showSuccess('Portfolio item deleted');
    });
  }

  /// Remove image from portfolio item
  Future<void> removePortfolioImage(String itemId, String imageUrl) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Find existing item
      final index = portfolioItems.indexWhere((item) => item?.id == itemId);
      if (index == -1) {
        showError('Portfolio item not found');
        return;
      }

      final existingItem = portfolioItems[index];

      // Create updated item with image removed
      final updatedImageUrls =
          existingItem.images.where((url) => url != imageUrl).toList();

      if (updatedImageUrls.isEmpty) {
        showError('Cannot remove all images. Please add a new image first.');
        return;
      }

      final updatedItem = PortfolioItem(
        id: existingItem.id,
        title: existingItem.title,
        description: existingItem.description,
        images: updatedImageUrls,
        createdAt: existingItem.createdAt,
      );

      // Update in database
      await _userAPI.updatePortfolioItem(userId, updatedItem);

      // Update local state
      portfolioItems[index] = updatedItem;

      showSuccess('Image removed');
    });
  }

  /// Select images from gallery
  Future<void> selectImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final files = images.map((image) => File(image.path)).toList();
        selectedImages.addAll(files);
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      showError('Failed to pick images');
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        selectedImages.add(File(photo.path));
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      showError('Failed to take photo');
    }
  }

  /// Remove selected image
  void removeSelectedImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  /// Load item for editing
  void loadItemForEditing(String itemId) {
    final item = portfolioItems.firstWhere((item) => item?.id == itemId);

    titleController.text = item.title;
    descriptionController.text = item.description;

    // Clear any currently selected images
    selectedImages.clear();
  }

  /// Clear form
  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedImages.clear();
  }
}
