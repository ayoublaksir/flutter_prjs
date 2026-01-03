import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/date_offer.dart';
import '../services/date_offer_service.dart';
import '../services/user_service.dart';
import 'package:carousel_slider/carousel_slider.dart';

class UserProfileDetailScreen extends StatefulWidget {
  final UserProfile userProfile;
  final bool isResponder;
  final String? offerId;
  final ResponderStatus? responderStatus;

  UserProfileDetailScreen({
    required this.userProfile,
    this.isResponder = false,
    this.offerId,
    this.responderStatus,
  });

  @override
  _UserProfileDetailScreenState createState() =>
      _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends State<UserProfileDetailScreen> {
  final DateOfferService _dateOfferService = DateOfferService();
  final UserService _userService = UserService();
  bool _isLoading = false;
  int _currentImageIndex = 0;
  UserProfile? _fullUserProfile;

  @override
  void initState() {
    super.initState();
    _loadFullUserProfile();
  }

  Future<void> _loadFullUserProfile() async {
    setState(() => _isLoading = true);
    try {
      // Get the complete user profile with all images and details
      final fullProfile = await _userService.getUserProfile(
        widget.userProfile.uid,
      );
      if (fullProfile != null) {
        print('Loaded profile: ${fullProfile.name}');
        print('Profile image: ${fullProfile.profileImageUrl}');
        print('Additional images: ${fullProfile.additionalImages}');
        print('Interests: ${fullProfile.preferences.preferredCategories}');

        setState(() {
          _fullUserProfile = fullProfile;
        });
      } else {
        print('Failed to load full profile - null returned');
      }
    } catch (e) {
      print('Error loading full profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the full profile if available, otherwise use the provided profile
    final profile = _fullUserProfile ?? widget.userProfile;

    print('Building profile view for: ${profile.name}');
    print('Gender: ${profile.gender}');
    print('Preferred categories: ${profile.preferences.preferredCategories}');
    print('Preferred moods: ${profile.preferences.preferredMoods}');

    return Scaffold(
      appBar: AppBar(title: Text(profile.name)),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image carousel with indicator
                    _buildProfileImagesWithIndicator(profile),

                    // Profile info
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${profile.name}, ${profile.age ?? "?"}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (profile.isVerified)
                                Icon(Icons.verified, color: Colors.blue),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Gender
                          Row(
                            children: [
                              Icon(
                                profile.gender.toString().contains('female')
                                    ? Icons.female
                                    : Icons.male,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 8),
                              Text(
                                profile.gender.toString().split('.').last,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Interests section
                          _buildInterestsSection(profile),
                          SizedBox(height: 24),

                          // Preferred moods
                          _buildMoodsSection(profile),

                          // Additional profile details
                          SizedBox(height: 24),
                          _buildAdditionalDetails(profile),
                        ],
                      ),
                    ),

                    // Action buttons for responders
                    if (widget.isResponder &&
                        widget.offerId != null &&
                        widget.responderStatus == ResponderStatus.pending)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () => _respondToUser(true),
                                child:
                                    _isLoading
                                        ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text('Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () => _respondToUser(false),
                                child: Text('Decline'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileImagesWithIndicator(UserProfile profile) {
    final List<String> images = [
      if (profile.profileImageUrl != null) profile.profileImageUrl!,
      ...profile.additionalImages,
    ];

    print('User images: $images'); // Debug log to check images

    return images.isEmpty
        ? Container(
          height: 350,
          color: Colors.grey[300],
          child: Icon(Icons.person, size: 100, color: Colors.grey[600]),
        )
        : Stack(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 350,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                enableInfiniteScroll: images.length > 1,
                autoPlay: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
              items:
                  images.map((imageUrl) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      images.asMap().entries.map((entry) {
                        return Container(
                          width: 8.0,
                          height: 8.0,
                          margin: EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentImageIndex == entry.key
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                ),
              ),
          ],
        );
  }

  Widget _buildInterestsSection(UserProfile profile) {
    if (profile.preferences.preferredCategories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('No interests specified', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              profile.preferences.preferredCategories
                  .map(
                    (category) => Chip(
                      label: Text(category.toString().split('.').last),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.1),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildMoodsSection(UserProfile profile) {
    if (profile.preferences.preferredMoods.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred Date Moods',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'No preferred moods specified',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Date Moods',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              profile.preferences.preferredMoods
                  .map(
                    (mood) => Chip(
                      label: Text(mood.toString().split('.').last),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.1),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetails(UserProfile profile) {
    // Only show this section if there's location data
    if (profile.location == null) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),

        // Location
        _buildDetailRow(
          Icons.location_on,
          'Location',
          profile.location.toString(),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(value, style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _respondToUser(bool accept) async {
    if (widget.offerId == null) return;

    setState(() => _isLoading = true);
    try {
      if (accept) {
        await _dateOfferService.acceptResponse(
          widget.offerId!,
          widget.userProfile.uid,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Response accepted!')));
      } else {
        await _dateOfferService.declineResponse(
          widget.offerId!,
          widget.userProfile.uid,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Response declined')));
      }
      Navigator.pop(context, true); // Return true to indicate action was taken
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
