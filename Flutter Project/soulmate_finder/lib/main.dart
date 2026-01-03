import 'package:flutter/material.dart';
import 'screens/input_screen.dart';

void main() {
  runApp(const SoulmateFinder());
}

class SoulmateFinder extends StatelessWidget {
  const SoulmateFinder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soulmate Finder',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const InputScreen(),
    );
  }
}