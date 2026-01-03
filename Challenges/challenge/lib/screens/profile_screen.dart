// lib/screens/profile_screen.dart
import '../models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/common_widgets.dart';
import '../models/challenge_model.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel>(
      stream: context.read<DatabaseService>().getUserStream(
        context.read<AuthService>().currentUser!.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text('Profile'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthService>().signOut();
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 50,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(fontSize: 36),
                ),
              ),
              SizedBox(height: 16),
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              _buildStatsCard(user),
              SizedBox(height: 16),
              _buildAchievementsCard(user, context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(UserModel user) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Member since: ${_formatDate(user.createdAt)}'),
            Text('Achievements: ${user.badges.length}'),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildAchievementsCard(UserModel user, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (user.hasBadge('first_challenge'))
                _buildAchievementItem(
                  context,
                  'First Challenge',
                  'Started your first challenge',
                  Icons.emoji_events,
                  Colors.amber,
                ),
              if (user.hasBadge('week_streak'))
                _buildAchievementItem(
                  context,
                  '7-Day Streak',
                  'Maintained a week-long streak',
                  Icons.whatshot,
                  Colors.orange,
                ),
              if (user.hasBadge('challenge_master'))
                _buildAchievementItem(
                  context,
                  'Challenge Master',
                  'Completed 5 challenges',
                  Icons.military_tech,
                  Colors.purple,
                ),
              if (user.hasBadge('month_streak'))
                _buildAchievementItem(
                  context,
                  'Monthly Master',
                  'Completed a 30-day challenge',
                  Icons.stars,
                  Colors.blue,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
