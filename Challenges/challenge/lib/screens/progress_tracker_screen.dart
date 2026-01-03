import 'package:flutter/material.dart';
import '../models/challenge_model.dart';
import '../widgets/form_widgets.dart';

class ProgressTrackerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final challenge =
        ModalRoute.of(context)!.settings.arguments as ChallengeModel;

    return Scaffold(
      appBar: AppBar(title: Text('Progress Tracker')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStats(challenge),
            SizedBox(height: 24),
            Text(
              'Daily Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildProgressGrid(challenge),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(ChallengeModel challenge) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Current Streak: ${challenge.currentStreak} days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Longest Streak: ${challenge.longestStreak} days',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Completion Rate: ${_calculateCompletionRate(challenge)}%',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressGrid(ChallengeModel challenge) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: challenge.duration,
      itemBuilder: (context, index) {
        final dayProgress =
            challenge.progress.length > index
                ? challenge.progress[index]
                : null;
        return _buildDayTile(index + 1, dayProgress);
      },
    );
  }

  Widget _buildDayTile(int day, DayProgress? progress) {
    return Container(
      decoration: BoxDecoration(
        color:
            progress?.completed ?? false ? Colors.green[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          day.toString(),
          style: TextStyle(
            color:
                progress?.completed ?? false ? Colors.green : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  int _calculateCompletionRate(ChallengeModel challenge) {
    if (challenge.progress.isEmpty) return 0;
    final completedDays = challenge.progress.where((p) => p.completed).length;
    return ((completedDays / challenge.duration) * 100).round();
  }
}
