import 'package:get/get.dart';
import '../controllers/seeker/home_controller.dart';
import '../controllers/seeker/profile_controller.dart';
import '../controllers/seeker/search_controller.dart';
import '../controllers/seeker/booking_history_controller.dart';
import '../controllers/seeker/service_details_controller.dart';
import '../controllers/seeker/booking_controller.dart';
import '../controllers/seeker/saved_services_controller.dart';
import '../controllers/seeker/settings_controller.dart';
import '../controllers/seeker/address_controller.dart';
import '../controllers/chat_controller.dart';

/// Bindings for seeker screens
class SeekerHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SeekerHomeController>(() => SeekerHomeController());
  }
}

class SeekerProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SeekerProfileController>(() => SeekerProfileController());
  }
}

class SeekerSearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SearchController>(() => SearchController());
  }
}

class SeekerBookingHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingHistoryController>(() => BookingHistoryController());
  }
}

class SeekerServiceDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceDetailsController>(() => ServiceDetailsController(
      serviceId: Get.arguments?['serviceId'] ?? '',
    ));
  }
}

class SeekerBookingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingController>(() => BookingController(
      serviceId: Get.arguments?['serviceId'] ?? '',
      providerId: Get.arguments?['providerId'] ?? '',
      isRebooking: Get.arguments?['isRebooking'] ?? false,
      originalBookingId: Get.arguments?['originalBookingId'],
    ));
  }
}

class SeekerSavedServicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SavedServicesController>(() => SavedServicesController());
  }
}

class SeekerSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SeekerSettingsController>(() => SeekerSettingsController());
  }
}

class SeekerAddressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddressController>(() => AddressController());
  }
}

class SeekerChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController(
      conversationId: Get.arguments?['conversationId'],
      recipientId: Get.arguments?['recipientId'],
    ));
  }
}