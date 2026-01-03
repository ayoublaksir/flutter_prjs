import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/date_mood.dart';
import '../models/date_category.dart';
import '../widgets/enhanced_button.dart';
import 'package:intl/intl.dart';
import '../models/gender.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/premium_badge.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool isCurrentUser;

  const ProfileScreen({Key? key, this.userId, this.isCurrentUser = true})
    : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = true;
  UserProfile? _userProfile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);

      // Check if user is logged in first
      if (!_authService.isLoggedIn) {
        setState(() {
          _isLoading = false;
          _error = "Please log in to view your profile";
        });
        return;
      }

      final userProfile = await _authService.getCurrentUserProfile();
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error loading profile: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Please log in to view your profile'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Profile',
        showNotifications: false,
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit-profile');
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: _authService.getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          }

          final userProfile = snapshot.data!;
          return ListView(
            children: [
              _buildProfileInfo(userProfile),
              if (userProfile.preferences.preferredMoods.isNotEmpty ||
                  userProfile.preferences.preferredCategories.isNotEmpty)
                _buildPreferencesSection(userProfile),
              _buildLocationSection(userProfile),
              _buildAccountSection(userProfile),
              _buildActionButtons(context),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Consumer<AuthService>(
                  builder: (context, authService, child) {
                    if (authService.isPremium) {
                      return ListTile(
                        leading: Icon(Icons.card_membership),
                        title: Text('Manage Subscription'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/subscription-management',
                          );
                        },
                      );
                    } else {
                      return ListTile(
                        leading: Icon(Icons.star),
                        title: Text('Get Premium'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pushNamed(context, '/premium');
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              'Error Loading Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(UserProfile userProfile) {
    return _buildSection(
      title: 'Dating Preferences',
      icon: Icons.favorite_border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userProfile.preferences.preferredMoods.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferred Date Moods',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        userProfile.preferences.preferredMoods.map((mood) {
                          return Chip(
                            label: Text(mood.displayName),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
          ],
          if (userProfile.preferences.preferredCategories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferred Date Activities',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        userProfile.preferences.preferredCategories.map((
                          category,
                        ) {
                          return Chip(
                            label: Text(category.displayName),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection(UserProfile userProfile) {
    return _buildSection(
      title: 'Location',
      icon: Icons.location_on,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  userProfile.city ?? 'Location not set',
                  style: TextStyle(fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final position = await Geolocator.getCurrentPosition();
                      final placemarks = await placemarkFromCoordinates(
                        position.latitude,
                        position.longitude,
                      );

                      if (placemarks.isNotEmpty) {
                        final place = placemarks.first;
                        final city =
                            place.locality ??
                            place.subAdministrativeArea ??
                            'Unknown';

                        // Update user's location
                        // This would typically call a method in your user service

                        setState(() {});
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update location: $e'),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(UserProfile userProfile) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final joinDate =
        userProfile.createdAt != null
            ? dateFormat.format(userProfile.createdAt!)
            : 'Unknown';

    return _buildSection(
      title: 'Account',
      icon: Icons.account_circle,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAccountItem(
              icon: Icons.email,
              title: 'Email',
              value: userProfile.email,
            ),
            Divider(),
            _buildAccountItem(
              icon: Icons.calendar_today,
              title: 'Member Since',
              value: joinDate,
            ),
            Divider(),
            _buildAccountItem(
              icon: Icons.verified_user,
              title: 'Verification',
              value: userProfile.isVerified ? 'Verified' : 'Not Verified',
              trailing:
                  !userProfile.isVerified
                      ? TextButton(
                        onPressed: () {
                          // Handle verification process
                        },
                        child: Text('Verify Now'),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountItem({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(value, style: TextStyle(fontSize: 16)),
          ],
        ),
        Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Show delete account confirmation dialog
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
                            // Handle account deletion
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
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(UserProfile userProfile) {
    return Container(
      padding: EdgeInsets.all(16),
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
          // Basic info section
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    userProfile.profileImageUrl != null
                        ? NetworkImage(userProfile.profileImageUrl!)
                        : null,
                child:
                    userProfile.profileImageUrl == null
                        ? Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${userProfile.name}, ${userProfile.age ?? "?"}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (userProfile.city != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            userProfile.city!,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getGenderIcon(userProfile.gender),
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatGender(userProfile.gender),
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bio section
          if (userProfile.bio != null && userProfile.bio!.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'About Me',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              userProfile.bio!,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
          ],

          // Professional info section
          if (_hasProfessionalInfo(userProfile)) ...[
            SizedBox(height: 16),
            Text(
              'Professional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (userProfile.jobTitle != null)
              _buildInfoRow(Icons.work, 'Job', userProfile.jobTitle!),
            if (userProfile.company != null)
              _buildInfoRow(Icons.business, 'Company', userProfile.company!),
            if (userProfile.education != null)
              _buildInfoRow(Icons.school, 'Education', userProfile.education!),
          ],

          // Interests section
          if (userProfile.interests.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Interests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  userProfile.interests.map((interest) {
                    return Chip(
                      label: Text(interest),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }).toList(),
            ),
          ],

          // Additional photos section
          if (userProfile.additionalImages.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Photos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: userProfile.additionalImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        userProfile.additionalImages[index],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to check if user has professional info
  bool _hasProfessionalInfo(UserProfile profile) {
    return profile.jobTitle != null ||
        profile.company != null ||
        profile.education != null;
  }

  // Helper method to format gender
  String _formatGender(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
    }
    return 'Unknown';
  }

  // Helper method to build info rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[900])),
          ),
        ],
      ),
    );
  }

  IconData _getGenderIcon(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Icons.male;
      case Gender.female:
        return Icons.female;
    }
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
              }),
              _buildNavItem(Icons.chat_bubble_outline, 'Chat', () {
                Navigator.pushReplacementNamed(context, '/chat-list');
              }),
              _buildNavItem(Icons.person_outline, 'Profile', () {
                Navigator.pushReplacementNamed(context, '/profile');
              }, isSelected: true),
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
