import 'package:dating_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dating_app/screens/login_screen.dart';
import 'package:dating_app/screens/register_screen.dart';
import 'package:dating_app/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/create_date_offer_screen.dart';
import 'screens/date_offers_feed_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/my_offers_screen.dart';
import 'screens/match_details_screen.dart';
import 'screens/date_recommendation_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/recommendation_details_screen.dart';
import 'models/date_models.dart' as date_models;
import 'screens/manage_responses_screen.dart';
import 'models/date_offer.dart';
import 'screens/map_screen.dart';
import 'screens/select_location_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/signup/multi_step_signup_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/nearby_users_screen.dart';
import 'package:dating_app/models/relationship_stage.dart';
import 'screens/chat_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/date_offer_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/purchase_service.dart';
import 'screens/subscription_management_screen.dart';
import 'models/user_preferences.dart' as prefs;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'models/date_category.dart';
import 'models/date_mood.dart';
import 'package:dating_app/screens/create_date_offer_screen.dart';
import 'package:dating_app/screens/date_offers_feed_screen.dart';
import 'package:dating_app/screens/matches_screen.dart';
import 'package:dating_app/screens/nearby_users_screen.dart';
import 'package:dating_app/screens/match_details_screen.dart';
import 'package:dating_app/screens/manage_responses_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/filtered_places_screen.dart';

void main() async {
  // Add proper error handling
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter error caught: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  try {
    await Firebase.initializeApp();

    // Initialize purchase service
    final purchaseService = PurchaseService();
    await purchaseService.initialize();

    // Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => purchaseService),
          // Add other providers...
        ],
        child: MyApp(onboardingComplete: onboardingComplete),
      ),
    );
  } catch (e, stackTrace) {
    print('Error initializing app: $e');
    print('Stack trace: $stackTrace');

    // Show a simple error app instead of crashing
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 60),
                SizedBox(height: 20),
                Text(
                  'Error initializing app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(e.toString(), textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final bool onboardingComplete;

  const MyApp({Key? key, required this.onboardingComplete}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  bool _onboardingComplete = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _onboardingComplete = widget.onboardingComplete;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking onboarding status
    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'Dating App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          primary: Colors.purple,
          secondary: Colors.pink,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // Improved error handling wrapper
        return ErrorBoundary(child: child ?? Container());
      },
      initialRoute: _onboardingComplete ? '/login' : '/onboarding',
      routes: _buildRoutes(),
      onGenerateRoute: (settings) {
        // Fallback for routes not defined in routes map
        print('Generating route for: ${settings.name}');

        // Handle dynamic routes
        if (settings.name?.startsWith('/profile/') ?? false) {
          final userId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder:
                (context) =>
                    ProfileScreen(userId: userId, isCurrentUser: false),
          );
        }

        if (settings.name?.startsWith('/chat/') ?? false) {
          final chatId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  receiverId: chatId,
                  receiverName: 'User', // Provide a default name
                  // If receiverImageUrl is required, provide a default or null value
                  receiverImageUrl: null,
                ),
          );
        }

        if (settings.name?.startsWith('/manage-responses/') ?? false) {
          final offerId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => ManageResponsesScreen(offerId: offerId),
          );
        }

        // Default fallback route
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: Text('Page Not Found')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Route "${settings.name}" not found'),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            () => Navigator.pushReplacementNamed(
                              context,
                              '/home',
                            ),
                        child: Text('Go Home'),
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => OnboardingScreen(),
      '/onboarding': (context) => OnboardingScreen(),
      '/login': (context) => LoginScreen(),
      '/register': (context) => RegisterScreen(),
      '/home': (context) => HomeScreen(),
      '/profile': (context) => ProfileScreen(),
      '/chat-list': (context) => ChatListScreen(),
      '/premium': (context) => PremiumScreen(),
      '/recommendations': (context) => DateRecommendationScreen(),
      '/date_recommendation': (context) => DateRecommendationScreen(),
      '/create-offer': (context) => CreateDateOfferScreen(),
      '/offers-feed': (context) => DateOffersFeedScreen(),
      '/matches': (context) => MatchesScreen(),
      '/nearby-users': (context) => NearbyUsersScreen(),
      '/match-details': (context) => MatchDetailsScreen(),
      '/map': (context) => MapScreen(),
      '/select-location': (context) => SelectLocationScreen(),
      '/payment':
          (context) => PaymentScreen(
            product:
                ModalRoute.of(context)!.settings.arguments as ProductDetails,
          ),
      '/subscription-management': (context) => SubscriptionManagementScreen(),
      '/settings': (context) => SettingsScreen(),
      '/edit-profile': (context) => EditProfileScreen(),
      '/notifications': (context) => NotificationsScreen(),
      '/manage-responses':
          (context) => Scaffold(
            appBar: AppBar(title: Text('Manage Responses')),
            body: Center(
              child: Text(
                'Please use /manage-responses/{offerId} to access this screen',
              ),
            ),
          ),
      '/my-offers': (context) => MyOffersScreen(),
      '/filtered-places': (context) => FilteredPlacesScreen(),
    };
  }
}

// Update your ErrorBoundary class
class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set the error builder first, then return the child
    ErrorWidget.builder = (FlutterErrorDetails details) {
      print('Error caught by ErrorBoundary: ${details.exception}');
      print('Error stack trace: ${details.stack}');

      // Return a more user-friendly error widget
      return Material(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 16),
              Text(
                'Oops! Something went wrong.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please try again later or contact support.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Try to restart the app
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                child: Text('Restart App'),
              ),
            ],
          ),
        ),
      );
    };

    return child;
  }
}
