import 'package:flutter/material.dart';
import '../models/date_offer.dart';
import '../services/date_offer_service.dart';
import '../services/auth_service.dart';
import '../widgets/enhanced_button.dart';
import '../widgets/modern_app_bar.dart';

class MatchesScreen extends StatefulWidget {
  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final DateOfferService _dateOfferService = DateOfferService();
  final AuthService _authService = AuthService();
  Stream<List<DateOffer>>? _matchesStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMatches();
  }

  Future<void> _initializeMatches() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _matchesStream = _dateOfferService.getUserMatches(user.uid);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing matches: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(title: 'Matches', showBackButton: false),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildMatchesList(),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildMatchesList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.background,
          ],
        ),
      ),
      child: StreamBuilder<List<DateOffer>>(
        stream: _matchesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading matches: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                  ElevatedButton(
                    onPressed: _initializeMatches,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No matches yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Keep responding to date offers to find matches!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return _buildMatchCard(match);
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(DateOffer match) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap:
            () => Navigator.pushNamed(
              context,
              '/match-details',
              arguments: match,
            ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    match.creatorImageUrl != null
                        ? NetworkImage(match.creatorImageUrl!)
                        : null,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child:
                    match.creatorImageUrl == null
                        ? Icon(Icons.person, color: Colors.white, size: 32)
                        : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${match.creatorName} • ${match.dateTime.toString().split('.')[0]}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', () {
                Navigator.pushReplacementNamed(context, '/home');
              }),
              _buildNavItem(Icons.explore_outlined, 'Explore', () {
                Navigator.pushReplacementNamed(context, '/offers-feed');
              }),
              _buildNavItem(Icons.favorite_border_outlined, 'Matches', () {
                Navigator.pushReplacementNamed(context, '/matches');
              }, isSelected: true),
              _buildNavItem(Icons.chat_bubble_outline, 'Chat', () {
                Navigator.pushReplacementNamed(context, '/chat-list');
              }),
              _buildNavItem(Icons.person_outline, 'Profile', () {
                Navigator.pushReplacementNamed(context, '/profile');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
