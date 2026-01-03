import 'package:flutter/material.dart';
import '../widgets/modern_app_bar.dart';
import '../models/date_offer.dart';
import '../services/date_offer_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/premium_popup.dart';
import '../services/purchase_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class DateOffersFeedScreen extends StatefulWidget {
  @override
  _DateOffersFeedScreenState createState() => _DateOffersFeedScreenState();
}

class _DateOffersFeedScreenState extends State<DateOffersFeedScreen> {
  final DateOfferService _dateOfferService = DateOfferService();
  final AuthService _authService = AuthService();
  final PurchaseService _purchaseService = PurchaseService();
  Stream<List<DateOffer>>? _offersStream;
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Nearby', 'Today', 'This Week'];

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      setState(() {
        _offersStream = _dateOfferService.getNearbyDateOffers(
          user.uid,
          user.gender,
          user.location ?? const GeoPoint(0, 0),
          user.city ?? 'Unknown',
          radius: 50, // 50km radius
          limit: 100, // Show more offers
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing date offers feed: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Date Offers',
        actions: [
          IconButton(
            icon: Icon(Icons.place),
            onPressed: () => Navigator.pushNamed(context, '/filtered-places'),
            tooltip: 'Browse Places',
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildOffersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-offer'),
        child: Icon(Icons.add),
        tooltip: 'Create Date Offer',
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildOffersList() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child:
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<DateOffer>>(
                    stream: _offersStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final offers = snapshot.data ?? [];
                      if (offers.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: offers.length,
                        itemBuilder: (context, index) {
                          return _buildDateOfferCard(offers[index]);
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                  // Apply filter logic here
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateOfferCard(DateOffer offer) {
    final dateTime = offer.dateTime;
    final formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final formattedTime =
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator info and date header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      offer.creatorImageUrl != null
                          ? NetworkImage(offer.creatorImageUrl!)
                          : null,
                  child:
                      offer.creatorImageUrl == null
                          ? Text(offer.creatorName[0])
                          : null,
                  radius: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.creatorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${offer.creatorAge} • ${offer.creatorGender.toString().split('.').last}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Date title and description
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (offer.description != null && offer.description!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      offer.description!,
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Location and cost info
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.place, color: Colors.grey[600], size: 20),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    offer.place,
                    style: TextStyle(color: Colors.grey[800]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (offer.estimatedCost != null &&
                    offer.estimatedCost! > 0) ...[
                  Icon(Icons.attach_money, color: Colors.grey[600], size: 20),
                  Text(
                    _formatCost(offer.estimatedCost ?? 0),
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ],
            ),
          ),

          // Interests tags
          if (offer.interests.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    offer.interests.map((interest) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showOfferDetails(offer),
                  icon: Icon(Icons.info_outline),
                  label: Text('Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _respondToOffer(offer),
                  icon: Icon(Icons.favorite),
                  label: Text('I\'m Interested'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No date offers available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to create a date offer!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/create-offer'),
            icon: Icon(Icons.add),
            label: Text('Create Date Offer'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCost(double cost) {
    if (cost < 10) return 'Budget';
    if (cost < 50) return 'Moderate';
    if (cost < 100) return 'Expensive';
    return 'Luxury';
  }

  void _showOfferDetails(DateOffer offer) {
    Navigator.pushNamed(context, '/match-details', arguments: offer);
  }

  Future<void> _respondToOffer(DateOffer offer) async {
    try {
      final user = await _authService.getCurrentUserProfile();
      final isPremium = _purchaseService.purchases.any(
        (purchase) =>
            purchase.status == PurchaseStatus.purchased &&
            purchase.productID.contains('premium'),
      );

      if (!isPremium) {
        showDialog(
          context: context,
          builder: (context) => PremiumPopup(feature: 'Respond to date offers'),
        );
        return;
      }

      await _dateOfferService.respondToOffer(
        offer.id,
        user.uid,
        user.name,
        user.profileImageUrl,
        user.gender,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Response sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to respond: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
              }, isSelected: true),
              _buildNavItem(Icons.favorite_border_outlined, 'Matches', () {
                Navigator.pushReplacementNamed(context, '/matches');
              }),
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
