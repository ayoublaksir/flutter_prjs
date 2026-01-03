// lib/screens/challenge_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_model.dart';
import '../services/database_service.dart';
import '../widgets/form_widgets.dart';
import '../services/auth_service.dart';

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
        final challenge = ChallengeModel(
          id: '', // Will be set by Firestore
          userId: context.read<AuthService>().currentUser!.id,
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
}

class ChallengeDetailsScreen extends StatelessWidget {
  final ChallengeModel challenge;

  const ChallengeDetailsScreen({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(challenge.title),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue, Colors.purple],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressSection(context),
                  SizedBox(height: 24),
                  _buildMotivationCard(context),
                  SizedBox(height: 24),
                  Text(
                    'Daily Progress',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  _buildDailyProgress(context),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCheckInDialog(context),
        icon: Icon(Icons.check),
        label: Text('Check In'),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final progress =
        (challenge.progress.where((p) => p.completed).length /
                challenge.duration *
                100)
            .round();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: Theme.of(context).textTheme.titleMedium),
              Text(
                '$progress%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat(
                context,
                'Days Left',
                '${challenge.duration - challenge.progress.length}',
              ),
              _buildProgressStat(
                context,
                'Current Streak',
                '${challenge.currentStreak}',
              ),
              _buildProgressStat(
                context,
                'Best Streak',
                '${challenge.longestStreak}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // Continuing from previous ChallengeDetailsScreen...

  Widget _buildMotivationCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Daily Motivation',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.orange[800]),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            challenge.motivation,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.orange[900],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: challenge.progress.length,
      itemBuilder: (context, index) {
        final progress = challenge.progress[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    progress.completed ? Colors.green[100] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                progress.completed ? Icons.check : Icons.close,
                color: progress.completed ? Colors.green : Colors.grey,
              ),
            ),
            title: Text(
              'Day ${index + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: progress.note != null ? Text(progress.note!) : null,
            trailing: Text(
              _formatDate(progress.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCheckInDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CheckInDialog(challenge: challenge),
    );
  }
}

class CheckInDialog extends StatefulWidget {
  final ChallengeModel challenge;

  const CheckInDialog({required this.challenge});

  @override
  _CheckInDialogState createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<CheckInDialog> {
  final _noteController = TextEditingController();
  bool _isCompleted = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Daily Check-in',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          SwitchListTile(
            title: Text('Completed Today\'s Challenge?'),
            value: _isCompleted,
            onChanged: (value) => setState(() => _isCompleted = value),
            activeColor: Colors.green,
          ),
          SizedBox(height: 16),
          CustomTextField(
            label: 'Add Note (Optional)',
            controller: _noteController,
          ),
          SizedBox(height: 24),
          CustomButton(
            text: 'Submit Check-in',
            onPressed: _handleCheckIn,
            isLoading: _isLoading,
            color: _isCompleted ? Colors.green : Colors.blue,
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isLoading = true);
    try {
      final progress = DayProgress(
        date: DateTime.now(),
        completed: _isCompleted,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      await context.read<DatabaseService>().updateChallengeProgress(
        widget.challenge.id,
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
}
