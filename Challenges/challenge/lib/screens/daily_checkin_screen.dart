import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_model.dart';
import '../services/database_service.dart';
import '../widgets/form_widgets.dart';

class DailyCheckinScreen extends StatefulWidget {
  @override
  _DailyCheckinScreenState createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final _noteController = TextEditingController();
  bool _isCompleted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final challenge =
        ModalRoute.of(context)!.settings.arguments as ChallengeModel;

    return Scaffold(
      appBar: AppBar(title: Text('Daily Check-in')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How did it go today?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            SwitchListTile(
              title: Text('Completed Today\'s Challenge'),
              value: _isCompleted,
              onChanged: (value) => setState(() => _isCompleted = value),
            ),
            SizedBox(height: 16),
            CustomTextField(
              label: 'Notes (optional)',
              controller: _noteController,
              maxLines: 3,
            ),
            SizedBox(height: 24),
            CustomButton(
              text: 'Submit Check-in',
              onPressed: () => _handleCheckin(context, challenge),
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckin(
    BuildContext context,
    ChallengeModel challenge,
  ) async {
    setState(() => _isLoading = true);
    try {
      final progress = DayProgress(
        date: DateTime.now(),
        completed: _isCompleted,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      await context.read<DatabaseService>().updateChallengeProgress(
        challenge.id,
        progress,
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
