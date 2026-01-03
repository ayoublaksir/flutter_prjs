import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/form_widgets.dart';

class CreateChallengeScreen extends StatefulWidget {
  @override
  _CreateChallengeScreenState createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _motivationController = TextEditingController();
  DateTime _startDate = DateTime.now();
  int _duration = 30;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create New Challenge')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Challenge Title',
                controller: _titleController,
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                controller: _descriptionController,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Please enter a description'
                            : null,
              ),
              SizedBox(height: 16),
              DatePickerField(
                label: 'Start Date',
                value: _startDate,
                onChanged: (date) => setState(() => _startDate = date),
              ),
              SizedBox(height: 16),
              CustomDropdown<int>(
                label: 'Duration (days)',
                value: _duration,
                items: [7, 14, 21, 30, 60, 90],
                itemLabel: (value) => '$value days',
                onChanged: (value) => setState(() => _duration = value!),
              ),
              SizedBox(height: 16),
              CustomTextField(
                label: 'Motivation Message',
                controller: _motivationController,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Please enter a motivation message'
                            : null,
              ),
              SizedBox(height: 24),
              CustomButton(
                text: 'Create Challenge',
                onPressed: _handleCreateChallenge,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreateChallenge() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final userId = context.read<AuthService>().currentUser!.id;
        final challenge = ChallengeModel(
          id: '', // Will be set by Firestore
          userId: userId,
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          duration: _duration,
          progress: [],
          motivation: _motivationController.text,
        );

        await context.read<DatabaseService>().createChallenge(challenge);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _motivationController.dispose();
    super.dispose();
  }
}
