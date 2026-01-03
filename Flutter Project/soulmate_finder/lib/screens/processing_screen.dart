import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../widgets/loading_animation.dart';
import '../utils/soulmate_generator.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final UserData userData;

  const ProcessingScreen({super.key, required this.userData});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final List<String> loadingMessages = [
    "Consulting the stars... ⭐",
    "Aligning chakras... 🌈",
    "Reading cosmic tea leaves... 🍵",
    "Calculating soul frequencies... 🎵",
    "Checking parallel universes... 🌌",
  ];
  int currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    // Simulate processing with message changes
    for (int i = 0; i < loadingMessages.length; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          currentMessageIndex = i;
        });
      }
    }

    if (mounted) {
      final soulmate = SoulmateGenerator.generateSoulmate(widget.userData);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(soulmate: soulmate),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade100, Colors.purple.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoadingAnimation(),
              const SizedBox(height: 32),
              Text(
                loadingMessages[currentMessageIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}