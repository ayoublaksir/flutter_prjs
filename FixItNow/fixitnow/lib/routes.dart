// routes.dart
// Application routes configuration

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/provider_bindings.dart';
import 'bindings/seeker_bindings.dart';

// Import screens
import 'screens/auth_screens.dart';
import 'screens/welcome_screen.dart' as welcome_screen;
import 'screens/help_center_screen.dart';

// Seeker screens
import 'screens/seeker/home_screen.dart';
import 'screens/seeker/profile_screen.dart';
import 'screens/seeker/settings_screen.dart';
import 'screens/seeker/search_screen.dart';
import 'screens/seeker/notification_screen.dart';
import 'screens/seeker/booking_history_screen.dart';
import 'screens/seeker/quick_booking_screen.dart';
import 'screens/seeker/saved_services_screen.dart';
import 'screens/seeker/recurring_service_screen.dart';
import 'screens/seeker/payment_methods_screen.dart';
import 'screens/seeker/help_support_screen.dart';
import 'screens/seeker/privacy_policy_screen.dart';
import 'screens/seeker/terms_conditions_screen.dart';
import 'screens/seeker/service_details_screen.dart';
import 'screens/seeker/reviews_screen.dart';
import 'screens/seeker/category_services_screen.dart';
import 'screens/seeker/booking_screen.dart';
import 'screens/seeker/address_management_screen.dart';
import 'screens/seeker/notification_preferences_screen.dart';
import 'screens/seeker/booking_completion_screen.dart';

// Provider screens
import 'screens/provider/home_screen.dart';
import 'screens/provider/dashboard_screen.dart';
import 'screens/provider/profile_screen.dart';
import 'screens/provider/settings_screen.dart';
import 'screens/provider/chat_screen.dart';
import 'screens/provider/service_management_screen.dart';
import 'screens/provider/portfolio_management_screen.dart';
import 'screens/provider/booking_requests_screen.dart';
import 'screens/provider/schedule_screen.dart';
import 'screens/provider/earning_screen.dart';
import 'screens/provider/analytics_screen.dart';
import 'screens/provider/availability_settings_screen.dart';
import 'screens/provider/professional_details_screen.dart';
import 'screens/provider/payment_settings_screen.dart';
import 'screens/provider/notification_settings_screen.dart';
import 'screens/provider/service_categories_selection_screen.dart';
import 'screens/provider/profile_settings_screen.dart';
import 'screens/provider/credits_screen.dart';
import 'screens/provider/metrics_dashboard_screen.dart';
import 'screens/provider/credit_purchase_confirmation_screen.dart';
import 'screens/provider/receipt_screen.dart';

class AppRoutes {
  // Auth & Onboarding routes
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String roleSelection = '/role-selection';
  static const String locationPermission = '/location-permission';

  // Seeker Main Navigation routes
  static const String seekerHome = '/seeker-home';
  static const String search = '/search';
  static const String notifications = '/notifications';
  static const String seekerProfile = '/seeker-profile';
  static const String seekerSettings = '/seeker-settings';

  // Seeker Booking routes
  static const String bookingHistory = '/booking-history';
  static const String quickBooking = '/quick-booking';
  static const String savedServices = '/saved-services';
  static const String recurringServices = '/recurring-services';
  static const String bookingCompletion = '/booking-completion';

  // Seeker Management
  static const String paymentMethods = '/payment-methods';
  static const String addressManagement = '/address-management';
  static const String notificationPreferences = '/notification-preferences';

  // Support & Info
  static const String helpSupport = '/help-support';
  static const String helpCenter = '/help-center';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';

  // Provider Main Navigation
  static const String providerHome = '/provider-home';
  static const String providerDashboard = '/provider-dashboard';
  static const String providerChat = '/provider-chat';
  static const String providerProfile = '/provider-profile';
  static const String providerSettings = '/provider-settings';
  static const String providerMetrics = '/provider-metrics';

  // Provider Business Management
  static const String serviceManagement = '/service-management';
  static const String portfolioManagement = '/portfolio-management';
  static const String bookingRequests = '/booking-requests';
  static const String schedule = '/schedule';
  static const String earnings = '/earnings';
  static const String analytics = '/analytics';

  // Provider Settings & Profile
  static const String availabilitySettings = '/availability-settings';
  static const String professionalDetails = '/professional-details';
  static const String paymentSettings = '/payment-settings';
  static const String notificationSettings = '/notification-settings';
  static const String profileSettings = '/profile-settings';

  // Provider Onboarding
  static const String serviceCategoriesSelection =
      '/service-categories-selection';

  // Provider Credits
  static const String providerCredits = '/provider/credits';
  static const String providerCreditsPurchase = '/provider/credits/purchase';
  static const String providerCreditsConfirmation =
      '/provider/credits/confirmation';
  static const String providerCreditsReceipt = '/provider/credits/receipt';

  // Other routes
  static const String reviews = '/reviews';
  static const String serviceDetails = '/service-details';
  static const String bookingDetails = '/booking-details';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String categoryServices = '/category-services';
  static const String settings = '/settings';
  static const String bookingForm = '/booking-form';
  static const String providerListing = '/provider-listing';
  static const String changePassword = '/change-password';

  // Add this to your routes
  static const String providerAnalytics = '/provider/analytics';

  // GetX Routes
  static final List<GetPage> getPages = [
    // Auth & Onboarding
    GetPage(name: welcome, page: () => const welcome_screen.WelcomeScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: signup, page: () => const SignupScreen()),
    GetPage(name: roleSelection, page: () => const RoleSelectionScreen()),
    GetPage(
      name: locationPermission,
      page: () => const LocationPermissionScreen(),
    ),

    // Seeker Main Navigation
    GetPage(
      name: seekerHome,
      page: () => const SeekerHomeScreen(),
      binding: SeekerHomeBinding(),
    ),
    GetPage(
      name: seekerProfile,
      page: () => const SeekerProfileScreen(),
      binding: SeekerProfileBinding(),
    ),
    GetPage(
      name: seekerSettings,
      page: () => const SeekerSettingsScreen(),
      binding: SeekerSettingsBinding(),
    ),
    GetPage(
      name: search,
      page: () => const SearchScreen(),
      binding: SeekerSearchBinding(),
    ),
    GetPage(name: notifications, page: () => const NotificationsScreen()),

    // Seeker Booking & Services
    GetPage(
      name: bookingHistory,
      page: () => const BookingHistoryScreen(),
      binding: SeekerBookingHistoryBinding(),
    ),
    GetPage(name: quickBooking, page: () => const QuickBookingScreen()),
    GetPage(
      name: savedServices,
      page: () => const SavedServicesScreen(),
      binding: SeekerSavedServicesBinding(),
    ),
    GetPage(
      name: recurringServices,
      page: () => const RecurringServicesScreen(),
    ),
    GetPage(
      name: bookingCompletion,
      page:
          () => BookingCompletionScreen(
            bookingId: Get.arguments?['bookingId'] ?? '',
          ),
    ),

    // Seeker Management
    GetPage(name: paymentMethods, page: () => const PaymentMethodsScreen()),
    GetPage(
      name: addressManagement,
      page: () => const AddressManagementScreen(),
      binding: SeekerAddressBinding(),
    ),
    GetPage(
      name: notificationPreferences,
      page: () => const NotificationPreferencesScreen(),
    ),

    // Support & Info
    GetPage(name: helpSupport, page: () => const HelpSupportScreen()),
    GetPage(name: helpCenter, page: () => const HelpCenterScreen()),
    GetPage(name: privacyPolicy, page: () => const PrivacyPolicyScreen()),
    GetPage(name: termsConditions, page: () => const TermsConditionsScreen()),

    // Provider Main Navigation
    GetPage(
      name: providerHome,
      page: () => const ProviderHomeScreen(),
      binding: ProviderHomeBinding(),
    ),
    GetPage(
      name: providerDashboard,
      page: () => const ProviderDashboardScreen(),
      binding: ProviderDashboardBinding(),
    ),
    GetPage(
      name: providerChat,
      page:
          () => ProviderChatScreen(seekerId: Get.arguments?['seekerId'] ?? ''),
      binding: ChatBinding(),
    ),
    GetPage(
      name: providerProfile,
      page: () => const ProviderProfileScreen(),
      binding: ProviderProfileBinding(),
    ),
    GetPage(name: providerSettings, page: () => const ProviderSettingsScreen()),
    GetPage(
      name: providerMetrics,
      page: () => const ProviderMetricsDashboardScreen(),
    ),

    // Provider Business Management
    GetPage(
      name: serviceManagement,
      page: () => const ServiceManagementScreen(),
    ),
    GetPage(
      name: portfolioManagement,
      page: () => const PortfolioManagementScreen(),
      binding: ProviderPortfolioBinding(),
    ),
    GetPage(
      name: bookingRequests,
      page: () => const BookingRequestsScreen(),
      binding: ProviderBookingRequestsBinding(),
    ),
    GetPage(
      name: schedule,
      page: () => const ScheduleScreen(),
      binding: ProviderScheduleBinding(),
    ),
    GetPage(
      name: earnings,
      page: () => const ProviderEarningsScreen(),
      binding: ProviderEarningBinding(),
    ),
    GetPage(
      name: analytics,
      page: () => const ProviderAnalyticsScreen(),
      binding: ProviderAnalyticsBinding(),
    ),
    GetPage(
      name: availabilitySettings,
      page: () => const AvailabilitySettingsScreen(),
      binding: ProviderAvailabilityBinding(),
    ),
    GetPage(
      name: professionalDetails,
      page: () => const ProfessionalDetailsScreen(),
    ),
    GetPage(
      name: paymentSettings,
      page: () => const PaymentSettingsScreen(),
      binding: ProviderPaymentSettingsBinding(),
    ),
    GetPage(
      name: notificationSettings,
      page: () => const NotificationSettingsScreen(),
      binding: ProviderNotificationSettingsBinding(),
    ),
    GetPage(
      name: serviceCategoriesSelection,
      page: () => const ServiceCategoriesSelectionScreen(),
    ),
    GetPage(
      name: profileSettings,
      page: () => const ProviderProfileSettingsScreen(),
    ),

    // Provider Credits
    GetPage(name: providerCredits, page: () => const ProviderCreditsScreen()),
    GetPage(
      name: providerCreditsPurchase,
      page: () => const CreditPurchaseScreen(),
    ),
    GetPage(
      name: providerCreditsConfirmation,
      page:
          () => CreditPurchaseConfirmationScreen(
            creditBundle: Get.arguments?['creditBundle'],
            selectedPaymentMethod: Get.arguments?['paymentMethod'],
          ),
    ),
    GetPage(
      name: providerCreditsReceipt,
      page:
          () => ReceiptScreen(
            transactionId: Get.arguments?['transactionId'] ?? '',
            credits: Get.arguments?['credits'] ?? 0,
            amount: Get.arguments?['amount'] ?? 0.0,
            date: Get.arguments?['date'] ?? DateTime.now(),
          ),
    ),

    // Other routes
    GetPage(
      name: reviews,
      page: () => ReviewsScreen(providerId: Get.arguments?['providerId'] ?? ''),
    ),
    GetPage(
      name: serviceDetails,
      page:
          () => ServiceDetailsScreen(
            serviceId: Get.arguments?['serviceId'] ?? '',
          ),
      binding: SeekerServiceDetailsBinding(),
    ),
    GetPage(
      name: bookingDetails,
      page:
          () => Scaffold(
            appBar: AppBar(title: const Text('Booking Details')),
            body: Center(
              child: Text('Booking ID: ${Get.arguments?['bookingId'] ?? ''}'),
            ),
          ),
    ),
    GetPage(
      name: bookingConfirmation,
      page:
          () => Scaffold(
            appBar: AppBar(title: const Text('Booking Confirmation')),
            body: Center(
              child: Text(
                'Booking Confirmed! ID: ${Get.arguments?['bookingId'] ?? ''}',
              ),
            ),
          ),
    ),
    GetPage(
      name: categoryServices,
      page:
          () => CategoryServicesScreen(
            category: Get.arguments?['category'] ?? {},
          ),
    ),
    GetPage(name: settings, page: () => const SeekerSettingsScreen()),
    GetPage(
      name: bookingForm,
      page:
          () =>
              SeekerBookingScreen(serviceId: Get.arguments?['serviceId'] ?? ''),
      binding: SeekerBookingBinding(),
    ),
    GetPage(
      name: providerListing,
      page:
          () => Scaffold(
            appBar: AppBar(title: const Text('Service Providers')),
            body: const Center(child: Text('Provider listing coming soon')),
          ),
    ),
    GetPage(
      name: changePassword,
      page:
          () => Scaffold(
            appBar: AppBar(title: const Text('Change Password')),
            body: const Center(
              child: Text('Change password screen coming soon'),
            ),
          ),
    ),
  ];

  // Traditional Route generator (kept for backward compatibility)
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth & Onboarding
      case AppRoutes.welcome:
        return MaterialPageRoute(
          builder: (_) => const welcome_screen.WelcomeScreen(),
        );
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case AppRoutes.roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case AppRoutes.locationPermission:
        return MaterialPageRoute(
          builder: (_) => const LocationPermissionScreen(),
        );

      // Seeker Main Navigation
      case AppRoutes.seekerHome:
        return MaterialPageRoute(builder: (_) => const SeekerHomeScreen());
      case AppRoutes.seekerProfile:
        return MaterialPageRoute(builder: (_) => const SeekerProfileScreen());
      case AppRoutes.seekerSettings:
        return MaterialPageRoute(builder: (_) => const SeekerSettingsScreen());
      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      // Seeker Booking & Services
      case AppRoutes.bookingHistory:
        return MaterialPageRoute(builder: (_) => const BookingHistoryScreen());
      case AppRoutes.quickBooking:
        return MaterialPageRoute(builder: (_) => const QuickBookingScreen());
      case AppRoutes.savedServices:
        return MaterialPageRoute(builder: (_) => const SavedServicesScreen());
      case AppRoutes.recurringServices:
        return MaterialPageRoute(
          builder: (_) => const RecurringServicesScreen(),
        );

      // Seeker Management
      case AppRoutes.paymentMethods:
        return MaterialPageRoute(builder: (_) => const PaymentMethodsScreen());
      case AppRoutes.addressManagement:
        return MaterialPageRoute(
          builder: (_) => const AddressManagementScreen(),
        );

      // Support & Info
      case AppRoutes.helpSupport:
        return MaterialPageRoute(builder: (_) => const HelpSupportScreen());
      case AppRoutes.helpCenter:
        return MaterialPageRoute(builder: (_) => const HelpCenterScreen());
      case AppRoutes.privacyPolicy:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case AppRoutes.termsConditions:
        return MaterialPageRoute(builder: (_) => const TermsConditionsScreen());

      // Provider Credits
      case AppRoutes.providerCredits:
        return MaterialPageRoute(builder: (_) => const ProviderCreditsScreen());
      case AppRoutes.providerCreditsPurchase:
        return MaterialPageRoute(builder: (_) => const CreditPurchaseScreen());

      // Default route
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
