// lib/widgets/challenge_widgets.dart
import 'package:flutter/material.dart';
import '../models/challenge_model.dart';
import '../screens/challenge_screens.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback onTap;

  const ChallengeCard({Key? key, required this.challenge, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(challenge.title),
        subtitle: Text(challenge.description),
        onTap: onTap,
        trailing: CircularProgressIndicator(
          value:
              challenge.progress.where((p) => p.completed).length /
              challenge.duration,
          backgroundColor: Colors.grey[200],
        ),
      ),
    );
  }
}

class ProgressChart extends StatelessWidget {
  final List<int> dailyProgress;

  const ProgressChart({required this.dailyProgress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                dailyProgress.length,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: FractionallySizedBox(
                      heightFactor: dailyProgress[index] / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
