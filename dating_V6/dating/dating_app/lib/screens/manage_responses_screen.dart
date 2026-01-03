import 'package:flutter/material.dart';
import '../models/date_offer.dart';
import '../services/date_offer_service.dart';
import '../screens/user_profile_detail_screen.dart';
import '../services/user_service.dart';

class ManageResponsesScreen extends StatefulWidget {
  final String offerId;

  const ManageResponsesScreen({Key? key, required this.offerId})
    : super(key: key);

  @override
  _ManageResponsesScreenState createState() => _ManageResponsesScreenState();
}

class _ManageResponsesScreenState extends State<ManageResponsesScreen> {
  final DateOfferService _dateOfferService = DateOfferService();
  final UserService _userService = UserService();
  late Stream<DateOffer> _offerStream;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _offerStream = _dateOfferService.getDateOfferStream(widget.offerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Interested People')),
      body: StreamBuilder<DateOffer>(
        stream: _offerStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final offer = snapshot.data;
          if (offer == null) {
            return Center(child: Text('Offer not found'));
          }

          final responders = offer.pendingResponders;
          if (responders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pending responses yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: responders.length,
            itemBuilder: (context, index) {
              final responder = responders[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading:
                      responder.imageUrl != null
                          ? CircleAvatar(
                            backgroundImage: NetworkImage(responder.imageUrl!),
                          )
                          : CircleAvatar(child: Text(responder.name[0])),
                  title: Text(responder.name),
                  subtitle: Text(
                    'Responded ${_timeAgo(responder.respondedAt)}',
                  ),
                  onTap: () {
                    _viewResponderProfile(responder.id);
                  },
                  trailing:
                      _isProcessing
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                onPressed:
                                    () => _acceptResponder(offer, responder.id),
                                tooltip: 'Accept',
                              ),
                              IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red),
                                onPressed:
                                    () =>
                                        _declineResponder(offer, responder.id),
                                tooltip: 'Decline',
                              ),
                            ],
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _acceptResponder(DateOffer offer, String responderId) async {
    setState(() => _isProcessing = true);
    try {
      // Get the current user's profile for the creator name
      final currentUser = await _userService.getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('Could not get current user profile');
      }

      // Accept the response
      await _dateOfferService.handleResponse(
        offer.id,
        true, // accepted
        responderId,
        currentUser.name,
        currentUser.gender,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Response accepted! Messages have been sent to start the conversation.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error accepting response: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _declineResponder(DateOffer offer, String responderId) async {
    setState(() => _isProcessing = true);
    try {
      await _dateOfferService.declineResponse(offer.id, responderId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Response declined')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _viewResponderProfile(String responderId) async {
    try {
      final userProfile = await _userService.getUserProfile(responderId);
      if (userProfile != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => UserProfileDetailScreen(
                  userProfile: userProfile,
                  isResponder: true,
                  offerId: widget.offerId,
                ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'recently';

    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
}
