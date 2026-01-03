// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/challenge_model.dart';
import '../widgets/challenge_widgets.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('My Challenges'),
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
            actions: [
              IconButton(
                icon: Icon(Icons.person),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: _buildStats(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Active Challenges',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          _buildChallengesList(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-challenge'),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            'Active',
            '5',
            Icons.directions_run,
            Colors.blue,
          ),
          _buildStatItem(
            context,
            'Completed',
            '12',
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatItem(
            context,
            'Streak',
            '7',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
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

  Widget _buildChallengesList(BuildContext context) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: context.read<DatabaseService>().getUserChallenges(
        context.read<AuthService>().currentUser!.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final challenges = snapshot.data!;
        if (challenges.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text('No challenges yet. Create your first one!'),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ChallengeCard(
              challenge: challenges[index],
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    '/challenge-details',
                    arguments: challenges[index],
                  ),
            ),
            childCount: challenges.length,
          ),
        );
      },
    );
  }

  int _calculateProgress(ChallengeModel challenge) {
    if (challenge.progress.isEmpty) return 0;
    final completedDays = challenge.progress.where((p) => p.completed).length;
    return ((completedDays / challenge.duration) * 100).round();
  }
}
