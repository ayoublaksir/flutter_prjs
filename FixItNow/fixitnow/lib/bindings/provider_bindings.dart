import 'package:get/get.dart';
import '../controllers/provider/dashboard_controller.dart';
import '../controllers/provider/profile_controller.dart';
import '../controllers/provider/booking_requests_controller.dart';
import '../controllers/provider/earning_controller.dart';
import '../controllers/provider/analytics_controller.dart';
import '../controllers/provider/reviews_controller.dart';
import '../controllers/provider/settings_controller.dart';
import '../controllers/provider/home_controller.dart';
import '../controllers/provider/schedule_controller.dart';
import '../controllers/provider/portfolio_controller.dart';
import '../controllers/provider/notification_controller.dart';
import '../controllers/provider/availability_controller.dart';
import '../controllers/provider/payment_settings_controller.dart';
import '../controllers/provider/notification_settings_controller.dart';
import '../controllers/chat_controller.dart';

/// Bindings for provider screens
class ProviderHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProviderHomeController>(() => ProviderHomeController());
  }
}

class ProviderDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}

class ProviderProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}

class ProviderBookingRequestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingRequestsController>(() => BookingRequestsController());
  }
}

class ProviderEarningBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EarningController>(() => EarningController());
  }
}

class ProviderAnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnalyticsController>(() => AnalyticsController());
  }
}

class ProviderReviewsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReviewsController>(() => ReviewsController());
  }
}

class ProviderSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}

class ProviderScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScheduleController>(() => ScheduleController());
  }
}

class ProviderPortfolioBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PortfolioController>(() => PortfolioController());
  }
}

class ProviderNotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}

class ProviderAvailabilityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AvailabilityController>(() => AvailabilityController());
  }
}

class ProviderPaymentSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentSettingsController>(() => PaymentSettingsController());
  }
}

class ProviderNotificationSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationSettingsController>(() => NotificationSettingsController());
  }
}

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController(
      conversationId: Get.arguments?['conversationId'],
      recipientId: Get.arguments?['recipientId'],
    ));
  }
}