import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/date_offer.dart';
import '../models/date_mood.dart';
import '../models/date_category.dart';
import '../models/relationship_stage.dart';
import '../models/date_models.dart';
import 'package:dating_app/screens/date_recommendation_screen.dart';
import 'package:dating_app/screens/nearby_users_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/date_offer_service.dart';
import '../widgets/enhanced_button.dart';
import '../widgets/enhanced_chip.dart';
import '../services/purchase_service.dart';
import '../widgets/premium_popup.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/premium_badge.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final DateOfferService _dateOfferService = DateOfferService();
  final PurchaseService _purchaseService = PurchaseService();
  UserProfile? _userProfile;
  Stream<List<DateOffer>>? _nearbyOffersStream;
  bool _isLoading = true;
  int _currentIndex = 0;
  final List<Widget> _screens = [];

  // User preferences
  RelationshipStage _selectedRelationshipStage = RelationshipStage.firstDate;
  List<DateMood> _selectedMoods = [];
  double _budget = 100.0;
  List<DateCategory> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      setState(() {
        _userProfile = user;
        _nearbyOffersStream = _dateOfferService.getNearbyDateOffers(
          user.uid,
          user.gender,
          user.location ?? const GeoPoint(0, 0),
          user.city ?? 'Unknown',
          radius: 10, // 10km radius
          limit: 5, // Show only 5 nearby offers
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing home: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        //title: Text('Dating App'),
        automaticallyImplyLeading: false, // Remove back button
        actions: _buildHeaderActions(context),
      ),
      body: Column(
        children: [
          // Quick action buttons row
          //_buildQuickActionButtons(context),

          // Rest of your home screen content
          Expanded(
            child:
                isLoggedIn
                    ? _buildLoggedInContent(context)
                    : _buildLoggedOutContent(context),
          ),
        ],
      ),
      // ONLY ONE bottom navigation bar here
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  List<Widget> _buildHeaderActions(BuildContext context) {
    return [
      // Premium badge
      Consumer<PurchaseService>(
        builder: (context, purchaseService, child) {
          return FutureBuilder<bool>(
            future: purchaseService.isPremiumUser(),
            builder: (context, snapshot) {
              final isPremium = snapshot.data ?? false;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: PremiumBadge(
                  mini: true,
                  onTap: () {
                    if (isPremium) {
                      Navigator.pushNamed(context, '/subscription-management');
                    } else {
                      Navigator.pushNamed(context, '/premium');
                    }
                  },
                ),
              );
            },
          );
        },
      ),

      // Messages button
      IconButton(
        icon: Icon(Icons.message),
        tooltip: 'Messages',
        onPressed: () {
          print('Navigating to messages');
          Navigator.pushNamed(context, '/chat-list');
        },
      ),

      // Notifications button
      IconButton(
        icon: Icon(Icons.notifications),
        tooltip: 'Notifications',
        onPressed: () {
          print('Navigating to notifications');
          Navigator.pushNamed(context, '/notifications');
        },
      ),

      // Settings/Profile button
      IconButton(
        icon: Icon(Icons.person),
        tooltip: 'Profile',
        onPressed: () {
          print('Navigating to profile');
          Navigator.pushNamed(context, '/profile');
        },
      ),
    ];
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            context,
            icon: Icons.favorite,
            label: 'Matches',
            onTap: () {
              Navigator.pushNamed(context, '/matches');
            },
          ),
          _buildQuickActionButton(
            context,
            icon: Icons.lightbulb,
            label: 'Ideas',
            onTap: () {
              Navigator.pushNamed(context, '/recommendations');
            },
          ),
          _buildQuickActionButton(
            context,
            icon: Icons.add_circle,
            label: 'Create',
            onTap: () {
              Navigator.pushNamed(context, '/create-offer');
            },
          ),
          _buildQuickActionButton(
            context,
            icon: Icons.location_on,
            label: 'Nearby',
            onTap: () {
              Navigator.pushNamed(context, '/nearby-users');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInContent(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _initializeHome,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildQuickActions(),
            _buildNearbyDateOffers(),
            // No bottomNavigationBar here
            SizedBox(height: 24), // Space at the bottom
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutContent(BuildContext context) {
    // Content for users who aren't logged in
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Please log in to continue'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: Text('Log In'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Your Perfect Date',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Discover date offers near you',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/find-dates'),
                  icon: Icon(Icons.explore),
                  label: Text('Explore All Dates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 15),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/create-offer'),
                icon: Icon(Icons.add),
                label: Text('Create'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyDateOffers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Date Offers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/offers-feed');
                },
                child: Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child:
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<DateOffer>>(
                    stream: _nearbyOffersStream,
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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No nearby date offers found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: offers.length,
                        itemBuilder: (context, index) {
                          return _buildNearbyOfferCard(offers[index]);
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildNearbyOfferCard(DateOffer offer) {
    return Container(
      width: 220,
      margin: EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator info with avatar
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        offer.creatorImageUrl != null
                            ? NetworkImage(offer.creatorImageUrl!)
                            : null,
                    child:
                        offer.creatorImageUrl == null
                            ? Text(offer.creatorName[0])
                            : null,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.creatorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${offer.creatorAge} • ${offer.creatorGender.toString().split('.').last}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Date offer details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    offer.place,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${offer.dateTime.day}/${offer.dateTime.month}/${offer.dateTime.year}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Spacer(),

            // Action button
            Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _respondToOffer(offer),
                  child: Text('Interested'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    textStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended for You',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to date recommendations screen with user preferences
                  Navigator.pushNamed(
                    context,
                    '/date_recommendation',
                    arguments: _userProfile?.preferences,
                  );
                },
                child: Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        // Placeholder for recommendations
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Personalized recommendations coming soon!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularPlacesSection() {
    // Implementation for popular places section
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Date Spots',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/map'),
                child: Text('See Map'),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Placeholder for popular places
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Discover popular date spots near you',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionItem(
            icon: Icons.chat,
            label: 'Messages',
            onTap: () => Navigator.pushNamed(context, '/chat-list'),
          ),
          _buildQuickActionItem(
            icon: Icons.favorite,
            label: 'Date Ideas',
            onTap: () => Navigator.pushNamed(context, '/date_recommendation'),
          ),
          _buildQuickActionItem(
            icon: Icons.search,
            label: 'Find Dates',
            onTap: () => Navigator.pushNamed(context, '/offers-feed'),
          ),
          _buildQuickActionItem(
            icon: Icons.list_alt,
            label: 'My Offers',
            onTap: () => Navigator.pushNamed(context, '/my-offers'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
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

  // Add this method to build the bottom navigation bar
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
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Add this helper method for navigation items
  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    final isSelected = label.toLowerCase() == 'home'; // Current screen is Home

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

// Helper method to format enum strings
String _formatEnumString(dynamic enumValue) {
  return StringExtension(
    enumValue
        .toString()
        .split('.')
        .last
        .replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' '),
  ).capitalize();
}

// Extension method to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
