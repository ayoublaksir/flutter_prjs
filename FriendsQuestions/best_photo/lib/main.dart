import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BestPicturePicker());
}

class BestPicturePicker extends StatelessWidget {
  const BestPicturePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Best Picture Picker',
      theme: ThemeData(
        primaryColor: const Color(0xFF2D3250),
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D3250),
          secondary: const Color(0xFF7077A1),
          tertiary: const Color(0xFFF6B17A),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}