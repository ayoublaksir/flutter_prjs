import 'package:flutter/material.dart';
import '../models/user_data.dart';
import 'questions_screen.dart';
import '../widgets/custom_input_fields.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✨ Soulmate Finder'),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CustomInputField(
                controller: _nameController,
                label: 'Your Magical Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                controller: _ageController,
                label: 'Your Earth Age',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                value: _selectedGender,
                items: const ['Celestial Being', 'Star Child', 'Cosmic Entity'],
                label: 'Your Cosmic Identity',
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _proceedToQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Begin Soul Journey ✨'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToQuestions() {
    if (_isValid()) {
      final userData = UserData(
        name: _nameController.text,
        age: int.parse(_ageController.text),
        gender: _selectedGender!,
        answers: {},
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionsScreen(userData: userData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields to begin your journey!'),
          backgroundColor: Colors.purple,
        ),
      );
    }
  }

  bool _isValid() {
    return _nameController.text.isNotEmpty &&
           _ageController.text.isNotEmpty &&
           _selectedGender != null;
  }
}