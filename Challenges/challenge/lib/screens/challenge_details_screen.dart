import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_model.dart';
import '../services/database_service.dart';
import '../widgets/form_widgets.dart';

class ChallengeDetailsScreen extends StatelessWidget {
  final ChallengeModel challenge;

  const ChallengeDetailsScreen({Key? key, required this.challenge})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress =
        (challenge.progress.where((p) => p.completed).length /
                challenge.duration *
                100)
            .round();

    return Scaffold(
      appBar: AppBar(title: Text(challenge.title)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCard(progress),
            SizedBox(height: 16),
            _buildDetailsCard(),
            SizedBox(height: 16),
            _buildMotivationCard(),
            SizedBox(height: 24),
            CustomButton(
              text: 'Daily Check-in',
              onPressed: () => _navigateToCheckin(context),
            ),
            SizedBox(height: 16),
            CustomButton(
              text: 'View Progress',
              onPressed: () => _navigateToProgress(context),
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(int progress) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$progress%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            LinearProgressIndicator(
              value: progress / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            SizedBox(height: 8),
            Text(
              '${challenge.progress.where((p) => p.completed).length} of ${challenge.duration} days completed',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(challenge.description),
            SizedBox(height: 16),
            Text(
              'Started: ${challenge.startDate.toString().split(' ')[0]}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Duration: ${challenge.duration} days',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Motivation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(challenge.motivation),
          ],
        ),
      ),
    );
  }

  void _navigateToCheckin(BuildContext context) {
    Navigator.pushNamed(context, '/daily-checkin', arguments: challenge);
  }

  void _navigateToProgress(BuildContext context) {
    Navigator.pushNamed(context, '/progress', arguments: challenge);
  }
}
