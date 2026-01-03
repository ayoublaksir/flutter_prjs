import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../utils/questions_data.dart';
import 'processing_screen.dart';

class QuestionsScreen extends StatefulWidget {
  final UserData userData;

  const QuestionsScreen({super.key, required this.userData});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  int currentQuestionIndex = 0;
  final Map<String, String> answers = {};

  @override
  Widget build(BuildContext context) {
    final question = QuestionData.funQuestions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soul Quest'),
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
              LinearProgressIndicator(
                value: (currentQuestionIndex + 1) / QuestionData.funQuestions.length,
                backgroundColor: Colors.purple.shade100,
                color: Colors.purple,
              ),
              const SizedBox(height: 24),
              Text(
                question['question'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ...question['options'].map<Widget>((option) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: () => _selectAnswer(option),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(option),
                  ),
                ),
              ).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _selectAnswer(String answer) {
    answers[QuestionData.funQuestions[currentQuestionIndex]['question']] = answer;

    if (currentQuestionIndex < QuestionData.funQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      _finishQuestions();
    }
  }

  void _finishQuestions() {
    widget.userData.answers.addAll(answers);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(userData: widget.userData),
      ),
    );
  }
}