import 'package:flutter/material.dart';
import '../utils/image_analyzer.dart';
import 'result_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final List<String> imagePaths;
  final String purpose;

  const AnalysisScreen({
    super.key,
    required this.imagePaths,
    required this.purpose,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int currentStep = 0;
  final List<String> analysisSteps = [
    "Analyzing lighting and composition... 🎨",
    "Checking facial expressions... 😊",
    "Evaluating professional appeal... 👔",
    "Calculating purpose alignment... 🎯",
    "Making final decision... ✨",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    for (var i = 0; i < analysisSteps.length; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          currentStep = i;
        });
      }
    }
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      final analysis = ImageAnalyzer.analyzePhotos(
        widget.imagePaths,
        widget.purpose,
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            analysis: analysis,
            purpose: widget.purpose,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * 2 * 3.14159,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: SweepGradient(
                              colors: [
                                Theme.of(context).colorScheme.tertiary,
                                Colors.transparent,
                              ],
                              stops: const [0.8, 1.0],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    analysisSteps[currentStep],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}