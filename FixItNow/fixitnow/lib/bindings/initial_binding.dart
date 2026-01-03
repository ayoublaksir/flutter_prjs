import 'package:get/get.dart';
import '../services/auth_services.dart';
import '../services/api_services.dart';
import '../services/storage_services.dart';
import '../services/firebase_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.put(FirebaseService(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(StorageService(), permanent: true);
    
    // API Services
    Get.put(UserAPI(), permanent: true);
    Get.put(ServiceAPI(), permanent: true);
    Get.put(BookingAPI(), permanent: true);
    Get.put(PaymentAPI(), permanent: true);
    Get.put(NotificationAPI(), permanent: true);
    Get.put(ReviewAPI(), permanent: true);
    Get.put(ChatAPI(), permanent: true);
    Get.put(SupportAPI(), permanent: true);
  }
}