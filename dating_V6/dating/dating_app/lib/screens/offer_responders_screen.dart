import 'package:flutter/material.dart';
import '../models/date_offer.dart';
import '../models/user_profile.dart';
import '../services/date_offer_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'user_profile_detail_screen.dart';

class OfferRespondersScreen extends StatefulWidget {
  final String offerId;

  OfferRespondersScreen({required this.offerId});

  @override
  _OfferRespondersScreenState createState() => _OfferRespondersScreenState();
}

class _OfferRespondersScreenState extends State<OfferRespondersScreen> {
  final DateOfferService _dateOfferService = DateOfferService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  DateOffer? _offer;
  Map<String, UserProfile> _responderProfiles = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResponders();
  }

  Future<void> _loadResponders() async {
    try {
      setState(() => _isLoading = true);

      // Get the offer details
      _offer = await _dateOfferService.getOffer(widget.offerId);

      // Load each responder's profile
      if (_offer != null && _offer!.responders.isNotEmpty) {
        for (final responderId in _offer!.responders.keys) {
          final profile = await _userService.getUserProfile(responderId);
          if (profile != null) {
            setState(() {
              _responderProfiles[responderId] = profile;
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading responders: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Interested People')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _offer == null || _offer!.responders.isEmpty
              ? Center(child: Text('No one has responded to this offer yet'))
              : ListView.builder(
                itemCount: _offer!.responders.length,
                itemBuilder: (context, index) {
                  final responderId = _offer!.responders.keys.elementAt(index);
                  final responderStatus = _offer!.responders[responderId];
                  final profile = _responderProfiles[responderId];

                  if (profile == null) {
                    return SizedBox.shrink();
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => UserProfileDetailScreen(
                                  userProfile: profile,
                                  isResponder: true,
                                  offerId: widget.offerId,
                                  responderStatus:
                                      _offer!.responders[responderId]?.status,
                                ),
                          ),
                        ).then((value) {
                          if (value == true) {
                            // Refresh if action was taken
                            _loadResponders();
                          }
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Profile image
                            CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  profile.profileImageUrl != null
                                      ? NetworkImage(profile.profileImageUrl!)
                                      : null,
                              child:
                                  profile.profileImageUrl == null
                                      ? Icon(Icons.person)
                                      : null,
                            ),
                            SizedBox(width: 16),

                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (profile.age != null)
                                    Text('${profile.age} years'),
                                  SizedBox(height: 4),
                                  _buildStatusChip(
                                    _offer!.responders[responderId]?.status,
                                  ),
                                ],
                              ),
                            ),

                            // Arrow icon
                            Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildStatusChip(ResponderStatus? status) {
    if (status == null) return SizedBox.shrink();

    Color color;
    String label;

    switch (status) {
      case ResponderStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case ResponderStatus.accepted:
        color = Colors.green;
        label = 'Accepted';
        break;
      case ResponderStatus.declined:
        color = Colors.red;
        label = 'Declined';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
