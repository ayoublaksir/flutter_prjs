import 'package:flutter/material.dart';
import '../widgets/modern_app_bar.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NearbyUsersScreen extends StatefulWidget {
  @override
  _NearbyUsersScreenState createState() => _NearbyUsersScreenState();
}

class _NearbyUsersScreenState extends State<NearbyUsersScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  List<UserProfile> _nearbyUsers = [];
  bool _isLoading = true;
  double _radius = 10.0; // 10km radius

  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }

  Future<void> _loadNearbyUsers() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _authService.getCurrentUserProfile();
      if (currentUser.location == null) {
        // Handle case where user location is not available
        setState(() => _isLoading = false);
        return;
      }

      // Get the stream of nearby users
      final nearbyUsersStream = _userService.getNearbyUsers(
        currentUser.uid,
        currentUser.location!,
        _radius,
      );

      // Listen to the stream and update the UI when data arrives
      nearbyUsersStream.listen(
        (users) {
          setState(() {
            _nearbyUsers = users;
            _isLoading = false;
          });
        },
        onError: (e) {
          print('Error loading nearby users: $e');
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      print('Error loading nearby users: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'People Nearby',
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
              _showFilterDialog();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _nearbyUsers.isEmpty
              ? _buildEmptyState()
              : _buildUsersList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Home tab (since nearby users is accessed from home)
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/date_offers');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/messages');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Dates'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Implement the build method to return a widget that represents an empty state
    // This is a placeholder and should be replaced with the actual implementation
    return Center(child: Text('No users found nearby'));
  }

  Widget _buildUsersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _nearbyUsers.length,
      itemBuilder: (context, index) => _buildUserCard(_nearbyUsers[index]),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
              child:
                  user.profileImageUrl == null
                      ? Icon(Icons.person, size: 30, color: Colors.white)
                      : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (user.city != null)
                    Text(user.city!, style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 8),
                  _buildInterestChips(user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestChips(UserProfile user) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          user.preferences.preferredCategories.map((category) {
            return Chip(
              label: Text(
                category.toString().split('.').last,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.secondary.withOpacity(0.2),
              padding: EdgeInsets.symmetric(horizontal: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
    );
  }

  void _showFilterDialog() {
    // Implement the showFilterDialog method
    // This is a placeholder and should be replaced with the actual implementation
    print('Show filter dialog');
  }
}
