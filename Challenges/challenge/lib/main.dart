// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/auth_screens.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_challenge_screen.dart';
import 'screens/challenge_details_screen.dart';
import 'screens/daily_checkin_screen.dart';
import 'screens/motivation_entry_screen.dart';
import 'screens/progress_tracker_screen.dart';
import 'models/challenge_model.dart';
import 'services/notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    final notificationService = NotificationService();
    await notificationService.initialize();

    runApp(MyApp());
  } catch (e) {
    print('Error initializing app: $e');
    // Consider showing an error screen instead of crashing
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => DatabaseService()),
        Provider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'Challenge App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => AuthWrapper());
            case '/home':
              return MaterialPageRoute(builder: (_) => HomeScreen());
            case '/profile':
              return MaterialPageRoute(builder: (_) => ProfileScreen());
            case '/create-challenge':
              return MaterialPageRoute(builder: (_) => CreateChallengeScreen());
            case '/challenge-details':
              final challenge = settings.arguments as ChallengeModel;
              return MaterialPageRoute(
                builder: (_) => ChallengeDetailsScreen(challenge: challenge),
              );
            case '/daily-checkin':
              final challenge = settings.arguments as ChallengeModel;
              return MaterialPageRoute(
                builder: (_) => DailyCheckinScreen(),
                settings: settings,
              );
            case '/motivation':
              final challengeId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => MotivationEntryScreen(challengeId: challengeId),
              );
            case '/progress':
              final challenge = settings.arguments as ChallengeModel;
              return MaterialPageRoute(
                builder: (_) => ProgressTrackerScreen(),
                settings: settings,
              );
            default:
              return MaterialPageRoute(builder: (_) => AuthWrapper());
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return authService.currentUser != null ? HomeScreen() : LoginScreen();
      },
    );
  }
}
