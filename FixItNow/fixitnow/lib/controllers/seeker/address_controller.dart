import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user_models.dart';
import '../../models/app_models.dart';
import '../../services/api_services.dart';
import '../../services/location_services.dart';
import '../base_controller.dart';

class AddressController extends BaseController {
  // Services via dependency injection
  final UserAPI _userAPI = Get.find<UserAPI>();
  final LocationService _locationServices = Get.find<LocationService>();

  // Reactive state
  final RxList<Address> addresses = <Address>[].obs;
  final Rx<Address?> selectedAddress = Rx<Address?>(null);
  final RxString defaultAddressId = ''.obs;

  // Form controllers
  final labelController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipCodeController = TextEditingController();
  final countryController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadAddresses();
  }

  @override
  void onClose() {
    // Dispose form controllers
    labelController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    countryController.dispose();
    super.onClose();
  }

  /// Load user addresses
  Future<void> loadAddresses() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final seeker = await _userAPI.getSeekerProfile(userId);

      // Update addresses
      addresses.value = seeker?.addresses ?? [];

      // Set default address ID
      defaultAddressId.value = seeker?.defaultAddressId ?? '';

      // Set selected address to default if available
      if (defaultAddressId.isNotEmpty) {
        selectedAddress.value = addresses.firstWhereOrNull(
          (addr) => addr.id == defaultAddressId.value,
        );
      }
    });
  }

  /// Add new address
  Future<void> addAddress() {
    if (!formKey.currentState!.validate()) {
      showError('Please fill in all required fields');
      return Future.value();
    }

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Get coordinates for the address
      final addressString =
          '${streetController.text}, ${cityController.text}, ${stateController.text} ${zipCodeController.text}, ${countryController.text}';

      String coordinates = '';
      try {
        final location = await _locationServices.getCoordinatesFromAddress(
          addressString,
        );
        coordinates = '${location[0].latitude},${location[0].longitude}';
      } catch (e) {
        debugPrint('Error getting coordinates: $e');
        // Continue without coordinates
      }

      // Create new address
      final newAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: labelController.text,
        street: streetController.text,
        city: cityController.text,
        state: stateController.text,
        zipCode: zipCodeController.text,
        country: countryController.text,
        isDefault: addresses.isEmpty, // First address is default
        coordinates: coordinates,
      );

      // Update local list
      final updatedAddresses = [...addresses, newAddress];

      // Update default address ID if this is the first address
      String updatedDefaultId = defaultAddressId.value;
      if (addresses.isEmpty) {
        updatedDefaultId = newAddress.id;
      }

      // Update in database
      await _userAPI.updateSeekerAddresses(
        userId,
        updatedAddresses,
        updatedDefaultId,
      );

      // Update local state
      addresses.value = updatedAddresses;
      defaultAddressId.value = updatedDefaultId;

      // Reset form
      _resetForm();

      showSuccess('Address added successfully');
    });
  }

  /// Update an existing address
  Future<void> updateAddress(String addressId) {
    if (!formKey.currentState!.validate()) {
      showError('Please fill in all required fields');
      return Future.value();
    }

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Find the address
      final index = addresses.indexWhere((addr) => addr.id == addressId);
      if (index == -1) {
        showError('Address not found');
        return;
      }

      // Get coordinates for the address
      final addressString =
          '${streetController.text}, ${cityController.text}, ${stateController.text} ${zipCodeController.text}, ${countryController.text}';

      String coordinates = '';
      try {
        final location = await _locationServices.getCoordinatesFromAddress(
          addressString,
        );
        coordinates = '${location[0].latitude},${location[0].longitude}';
      } catch (e) {
        debugPrint('Error getting coordinates: $e');
        // Continue with existing coordinates or empty
        coordinates = addresses[index].coordinates;
      }

      // Create updated address
      final updatedAddress = Address(
        id: addressId,
        label: labelController.text,
        street: streetController.text,
        city: cityController.text,
        state: stateController.text,
        zipCode: zipCodeController.text,
        country: countryController.text,
        isDefault: addresses[index].isDefault,
        coordinates: coordinates,
      );

      // Update local list
      final updatedAddresses = [...addresses];
      updatedAddresses[index] = updatedAddress;

      // Update in database
      await _userAPI.updateSeekerAddresses(
        userId,
        updatedAddresses,
        defaultAddressId.value,
      );

      // Update local state
      addresses.value = updatedAddresses;

      // Reset form
      _resetForm();

      showSuccess('Address updated successfully');
    });
  }

  /// Delete an address
  Future<void> deleteAddress(String addressId) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Check if it's the default address
      final isDefault = addressId == defaultAddressId.value;

      // Remove from list
      final updatedAddresses =
          addresses.where((addr) => addr.id != addressId).toList();

      // Update default address ID if needed
      String updatedDefaultId = defaultAddressId.value;
      if (isDefault && updatedAddresses.isNotEmpty) {
        updatedDefaultId = updatedAddresses.first.id;
      } else if (updatedAddresses.isEmpty) {
        updatedDefaultId = '';
      }

      // Update in database
      await _userAPI.updateSeekerAddresses(
        userId,
        updatedAddresses,
        updatedDefaultId,
      );

      // Update local state
      addresses.value = updatedAddresses;
      defaultAddressId.value = updatedDefaultId;

      showSuccess('Address deleted successfully');
    });
  }

  /// Set address as default
  Future<void> setDefaultAddress(String addressId) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Update in database
      await _userAPI.updateSeekerDefaultAddress(userId, addressId);

      // Update local state
      defaultAddressId.value = addressId;

      showSuccess('Default address updated');
    });
  }

  /// Load address for editing
  void loadAddressForEdit(String addressId) {
    final address = addresses.firstWhereOrNull((addr) => addr.id == addressId);
    if (address == null) {
      showError('Address not found');
      return;
    }

    // Populate form controllers
    labelController.text = address.label;
    streetController.text = address.street;
    cityController.text = address.city;
    stateController.text = address.state;
    zipCodeController.text = address.zipCode;
    countryController.text = address.country;

    // Set selected address
    selectedAddress.value = address;
  }

  /// Reset form
  void _resetForm() {
    labelController.clear();
    streetController.clear();
    cityController.clear();
    stateController.clear();
    zipCodeController.clear();
    countryController.clear();
    selectedAddress.value = null;
  }

  /// Format address
  String formatAddress(Address address) {
    return '${address.street}, ${address.city}, ${address.state} ${address.zipCode}, ${address.country}';
  }

  /// Check if an address is the default
  bool isDefaultAddress(String addressId) {
    return addressId == defaultAddressId.value;
  }
}
