import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/date_offer.dart';
import '../services/date_offer_service.dart';
import '../services/auth_service.dart';
import '../services/purchase_service.dart';
import '../widgets/premium_popup.dart';
import 'manage_responses_screen.dart';
import '../models/subscription.dart';
import 'offer_responders_screen.dart';
import '../widgets/premium_badge.dart';
import '../widgets/modern_app_bar.dart';

class MyOffersScreen extends StatefulWidget {
  @override
  _MyOffersScreenState createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  final DateOfferService _dateOfferService = DateOfferService();
  final AuthService _authService = AuthService();
  final PurchaseService _purchaseService = PurchaseService();
  Stream<List<DateOffer>>? _myOffersStream;
  bool _isPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyOffers();
  }

  Future<void> _loadMyOffers() async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        // Check if user has premium
        final subscription = await _purchaseService.getCurrentSubscription(
          userId,
        );
        setState(() {
          _myOffersStream = _dateOfferService.getUserOffers(userId);
          _isPremium = subscription.type != SubscriptionType.free;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading offers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: '',
        showBackButton: false,
        showNotifications: false,
        showProfileIcon: false,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadMyOffers),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PremiumBadge(
              mini: true,
              onTap: () => Navigator.pushNamed(context, '/premium'),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<DateOffer>>(
        stream: _myOffersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final offers = snapshot.data ?? [];

          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No date offers yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first date offer to get started',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/create-offer');
                    },
                    icon: Icon(Icons.add),
                    label: Text('Create Date Offer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Group offers by status
          final activeOffers =
              offers.where((o) => o.status == DateOfferStatus.active).toList();
          final pendingOffers =
              offers.where((o) => o.status == DateOfferStatus.pending).toList();
          final matchedOffers =
              offers.where((o) => o.status == DateOfferStatus.matched).toList();
          final pastOffers =
              offers
                  .where(
                    (o) =>
                        o.status == DateOfferStatus.expired ||
                        o.status == DateOfferStatus.declined ||
                        o.dateTime.isBefore(DateTime.now()),
                  )
                  .toList();

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              if (activeOffers.isNotEmpty) ...[
                _buildSectionHeader('Active Offers', Icons.local_activity),
                ...activeOffers.map((offer) => _buildOfferCard(context, offer)),
                SizedBox(height: 16),
              ],

              if (pendingOffers.isNotEmpty) ...[
                _buildSectionHeader('Pending Offers', Icons.pending_actions),
                ...pendingOffers.map(
                  (offer) => _buildOfferCard(context, offer),
                ),
                SizedBox(height: 16),
              ],

              if (matchedOffers.isNotEmpty) ...[
                _buildSectionHeader('Matched Offers', Icons.favorite),
                ...matchedOffers.map(
                  (offer) => _buildOfferCard(context, offer),
                ),
                SizedBox(height: 16),
              ],

              if (pastOffers.isNotEmpty) ...[
                _buildSectionHeader('Past Offers', Icons.history),
                ...pastOffers.map((offer) => _buildOfferCard(context, offer)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-offer');
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, DateOffer offer) {
    final bool isMatched = offer.status == DateOfferStatus.matched;
    final bool isActive = offer.status == DateOfferStatus.active;
    final bool isPending = offer.status == DateOfferStatus.pending;
    final bool isPast =
        offer.dateTime.isBefore(DateTime.now()) ||
        offer.status == DateOfferStatus.expired ||
        offer.status == DateOfferStatus.declined;

    Color cardColor = Colors.white;
    if (isMatched) cardColor = Colors.green[50]!;
    if (isPast) cardColor = Colors.grey[100]!;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isMatched ? Colors.green[300]! : Colors.grey[300]!,
          width: isMatched ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/offer-details', arguments: offer);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      offer.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(offer.status),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(offer.dateTime),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(offer.dateTime),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (offer.place != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        offer.place,
                        style: TextStyle(color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],

              // Responders count or match info
              if (isPending) ...[
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.blue[400]),
                    SizedBox(width: 4),
                    Text(
                      '${offer.responders.length} ${offer.responders.length == 1 ? 'person' : 'people'} responded',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ManageResponsesScreen(offerId: offer.id),
                          ),
                        );
                      },
                      child: Text('View Responses'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (isMatched && offer.responderName != null) ...[
                Divider(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage:
                          offer.responderImageUrl != null
                              ? NetworkImage(offer.responderImageUrl!)
                              : null,
                      child:
                          offer.responderImageUrl == null
                              ? Icon(Icons.person, size: 16)
                              : null,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Matched with ${offer.responderName}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/match-details',
                          arguments: offer,
                        );
                      },
                      child: Text('View Match'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(DateOfferStatus status) {
    Color chipColor;
    String label;
    IconData icon;

    switch (status) {
      case DateOfferStatus.active:
        chipColor = Colors.blue;
        label = 'Active';
        icon = Icons.local_activity;
        break;
      case DateOfferStatus.pending:
        chipColor = Colors.orange;
        label = 'Pending';
        icon = Icons.pending_actions;
        break;
      case DateOfferStatus.matched:
        chipColor = Colors.green;
        label = 'Matched';
        icon = Icons.favorite;
        break;
      case DateOfferStatus.declined:
        chipColor = Colors.red;
        label = 'Declined';
        icon = Icons.cancel;
        break;
      case DateOfferStatus.expired:
        chipColor = Colors.grey;
        label = 'Expired';
        icon = Icons.timer_off;
        break;
      default:
        chipColor = Colors.grey;
        label = 'Unknown';
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCancelConfirmation(BuildContext context, String offerId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Cancel Date Offer'),
            content: Text('Are you sure you want to cancel this date offer?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _dateOfferService.cancelDateOffer(offerId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Date offer cancelled')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: Text('Yes'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }
}
