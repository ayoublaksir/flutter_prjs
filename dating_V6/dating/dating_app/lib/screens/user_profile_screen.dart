import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/modern_app_bar.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  late UserProfile? _userProfile;
  bool _isCurrentUser = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // Get current user ID
      final currentUser = await _authService.getCurrentUserProfile();
      _currentUserId = currentUser.uid;

      // Check if viewing own profile
      _isCurrentUser = widget.userId == _currentUserId;

      // Load profile data
      _userProfile = await _userService.getUserProfile(widget.userId);
      if (_userProfile == null) {
        // Handle the case when profile is not found
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User profile not found')));
        Navigator.pop(context);
        return;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: _isLoading ? 'Profile' : _userProfile!.name,
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(context, '/edit_profile');
              },
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(),
                    if (_userProfile!.bio != null &&
                        _userProfile!.bio!.isNotEmpty)
                      _buildSection(
                        title: 'About',
                        icon: Icons.person,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(_userProfile!.bio!),
                        ),
                      ),
                    if (_userProfile!.interests.isNotEmpty)
                      _buildSection(
                        title: 'Interests',
                        icon: Icons.favorite,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _userProfile!.interests.map((interest) {
                                  return Chip(
                                    label: Text(interest),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    _buildActionButtons(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      color: Theme.of(context).colorScheme.primary,
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            backgroundImage:
                _userProfile!.profileImageUrl != null
                    ? NetworkImage(_userProfile!.profileImageUrl!)
                    : null,
            child:
                _userProfile!.profileImageUrl == null
                    ? Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
          ),
          SizedBox(height: 16),
          Text(
            _userProfile!.name +
                (_userProfile!.age != null ? ', ${_userProfile!.age}' : ''),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_userProfile!.city != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.white70),
                  SizedBox(width: 4),
                  Text(
                    _userProfile!.city!,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Only show message button if viewing someone else's profile
          if (!_isCurrentUser)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: {
                    'userId': _userProfile!.uid,
                    'name': _userProfile!.name,
                    'imageUrl': _userProfile!.profileImageUrl,
                  },
                );
              },
              icon: Icon(Icons.chat),
              label: Text('Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),

          if (!_isCurrentUser) SizedBox(height: 12),

          // Connect button (if not current user)
          if (!_isCurrentUser)
            ElevatedButton.icon(
              onPressed: () {
                // Implement connection functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connection request sent!')),
                );
              },
              icon: Icon(Icons.person_add),
              label: Text('Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

          if (_isCurrentUser) SizedBox(height: 24),

          // Sign out button (only if current user)
          if (_isCurrentUser)
            ElevatedButton(
              onPressed: () async {
                try {
                  await _authService.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
              child: Text('Sign Out'),
            ),

          if (_isCurrentUser) SizedBox(height: 12),

          // Delete account button (only if current user)
          if (_isCurrentUser)
            ElevatedButton(
              onPressed: () {
                // Show delete confirmation dialog
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('Delete Account'),
                        content: Text(
                          'Are you sure you want to delete your account? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Implement account deletion
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
              child: Text('Delete Account'),
            ),
        ],
      ),
    );
  }
}
