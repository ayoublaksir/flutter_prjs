import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/date_offer.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import 'user_profile_detail_screen.dart';

class MatchDetailsScreen extends StatefulWidget {
  @override
  _MatchDetailsScreenState createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _viewUserProfile(String userId) async {
    setState(() => _isLoading = true);
    try {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => UserProfileDetailScreen(
                  userProfile: userProfile,
                  isResponder: false,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateOffer match =
        ModalRoute.of(context)!.settings.arguments as DateOffer;
    final currentUserId = _authService.getCurrentUserId();

    // Determine if the current user is the creator or responder
    final bool isCreator = match.creatorId == currentUserId;
    final String partnerId = isCreator ? match.responderId! : match.creatorId;
    final String partnerName =
        isCreator ? match.responderName ?? 'Unknown' : match.creatorName;
    final String? partnerImageUrl =
        isCreator ? match.responderImageUrl : match.creatorImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('Match Details'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Match header with date details
                    Container(
                      padding: EdgeInsets.all(24),
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            match.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _formatDate(match.dateTime),
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _formatTime(match.dateTime),
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          if (match.location != null) ...[
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  // Convert GeoPoint to readable format
                                  match.location is GeoPoint
                                      ? "Lat: ${(match.location as GeoPoint).latitude.toStringAsFixed(2)}, Long: ${(match.location as GeoPoint).longitude.toStringAsFixed(2)}"
                                      : match.location.toString(),
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Partner info card - enlarged and centered
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => _viewUserProfile(partnerId),
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage:
                                      partnerImageUrl != null
                                          ? NetworkImage(partnerImageUrl)
                                          : null,
                                  child:
                                      partnerImageUrl == null
                                          ? Icon(Icons.person, size: 60)
                                          : null,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  partnerName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  isCreator
                                      ? 'Your match'
                                      : 'Date offer creator',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _viewUserProfile(partnerId),
                                  icon: Icon(Icons.person),
                                  label: Text('View Full Profile'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Description if available
                    if (match.description != null &&
                        match.description!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About this date',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  match.description!,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
