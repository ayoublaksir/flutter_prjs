// import 'package:flutter/material.dart';
// import '../models/date_offer.dart';
// import 'home_screen.dart';
// import 'date_offers_feed_screen.dart';
// import 'my_offers_screen.dart';
// import 'notifications_screen.dart';
// import 'profile_screen.dart';
// import 'matches_screen.dart';
// import 'notifications_screen.dart';
// import 'date_recommendation_screen.dart';
// import '../services/date_offer_service.dart';
// import '../services/auth_service.dart';
// import '../widgets/enhanced_chip.dart';
// import '../widgets/enhanced_button.dart';
// import '../services/purchase_service.dart';
// import '../widgets/premium_popup.dart';
// import '../models/date_models.dart' as date_models;
// import '../models/relationship_stage.dart';
// import '../models/date_mood.dart';
// import '../models/date_category.dart';
// import '../widgets/premium_badge.dart';
// import 'chat_list_screen.dart';
// import '../models/user_preferences.dart';
// import 'package:provider/provider.dart';

// class MainNavigationScreen extends StatefulWidget {
//   final int initialIndex;

//   const MainNavigationScreen({Key? key, this.initialIndex = 0})
//     : super(key: key);

//   @override
//   _MainNavigationScreenState createState() => _MainNavigationScreenState();
// }

// class _MainNavigationScreenState extends State<MainNavigationScreen> {
//   late int _selectedIndex;
//   Stream<List<DateOffer>>? _nearbyOffersStream;
//   final DateOfferService _dateOfferService = DateOfferService();
//   final AuthService _authService = AuthService();
//   final PurchaseService _purchaseService = PurchaseService();

//   @override
//   void initState() {
//     super.initState();
//     _selectedIndex = widget.initialIndex;
//     _initializeOffers();
//   }

//   Future<void> _initializeOffers() async {
//     final userId = await _authService.getCurrentUserId();
//     if (userId != null) {
//       setState(() {
//         _nearbyOffersStream = _dateOfferService.getNearbyOffers(userId);
//       });
//     }
//   }

//   final List<Widget> _screens = [
//     HomeScreen(),
//     DateOffersFeedScreen(),
//     MatchesScreen(),
//     ChatListScreen(),
//     ProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: Offset(0, -5),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildNavItem(Icons.home_outlined, 0, 'Home'),
//                 _buildNavItem(Icons.explore_outlined, 1, 'Explore'),
//                 _buildNavItem(Icons.favorite_border, 2, 'Matches'),
//                 _buildNavItem(Icons.chat_outlined, 3, 'Messages'),
//                 _buildNavItem(Icons.person_outline, 4, 'Profile'),
//               ],
//             ),
//           ),
//         ),
//       ),
//       floatingActionButton: Consumer<PurchaseService>(
//         builder: (context, purchaseService, child) {
//           return FutureBuilder<bool>(
//             future: purchaseService.isPremiumUser(),
//             builder: (context, snapshot) {
//               final isPremium = snapshot.data ?? false;

//               if (isPremium) return SizedBox.shrink(); // Hide for premium users

//               return FloatingActionButton(
//                 onPressed: () => Navigator.pushNamed(context, '/premium'),
//                 backgroundColor: Colors.pink,
//                 child: Icon(Icons.star, color: Colors.white),
//                 tooltip: 'Upgrade to Premium',
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildNavItem(IconData icon, int index, String label) {
//     final isSelected = _selectedIndex == index;
//     return InkWell(
//       onTap: () {
//         if (_selectedIndex == index) return;

//         setState(() {
//           _selectedIndex = index;
//         });

//         // Update navigation history for back button
//         switch (index) {
//           case 0:
//             Navigator.pushReplacementNamed(context, '/home');
//             break;
//           case 1:
//             Navigator.pushReplacementNamed(context, '/offers-feed');
//             break;
//           case 2:
//             Navigator.pushReplacementNamed(context, '/matches');
//             break;
//           case 3:
//             Navigator.pushReplacementNamed(context, '/chat-list');
//             break;
//           case 4:
//             Navigator.pushReplacementNamed(context, '/profile');
//             break;
//         }
//       },
//       borderRadius: BorderRadius.circular(16),
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color:
//                   isSelected
//                       ? Theme.of(context).colorScheme.primary
//                       : Colors.grey,
//               size: 24,
//             ),
//             SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 color:
//                     isSelected
//                         ? Theme.of(context).colorScheme.primary
//                         : Colors.grey,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNearbyOffers() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: EdgeInsets.all(16),
//           child: Text(
//             'Nearby Date Offers',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//           ),
//         ),
//         StreamBuilder<List<DateOffer>>(
//           stream: _nearbyOffersStream,
//           builder: (context, snapshot) {
//             if (snapshot.hasError) return _buildErrorState();
//             if (!snapshot.hasData) return _buildLoadingState();

//             final offers = snapshot.data!;
//             if (offers.isEmpty) return _buildEmptyState();

//             return Container(
//               height: 280,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 padding: EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: offers.length,
//                 itemBuilder: (context, index) {
//                   final offer = offers[index];
//                   return Container(
//                     width: 160,
//                     margin: EdgeInsets.only(right: 16),
//                     child: Card(
//                       clipBehavior: Clip.antiAlias,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: InkWell(
//                         onTap:
//                             () => Navigator.pushNamed(
//                               context,
//                               '/offer-details',
//                               arguments: offer,
//                             ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Image
//                             Container(
//                               height: 160,
//                               decoration: BoxDecoration(
//                                 image: DecorationImage(
//                                   image:
//                                       offer.creatorImageUrl != null
//                                           ? NetworkImage(offer.creatorImageUrl!)
//                                           : AssetImage(
//                                                 'assets/images/placeholder.jpg',
//                                               )
//                                               as ImageProvider,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                             ),
//                             // Name and Age
//                             Padding(
//                               padding: EdgeInsets.all(8),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     offer.creatorName,
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   Text(
//                                     '${offer.creatorAge} years',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                   // Interests
//                                   SizedBox(height: 8),
//                                   if (offer.interests.isNotEmpty)
//                                     Container(
//                                       height: 32,
//                                       child: ListView.builder(
//                                         scrollDirection: Axis.horizontal,
//                                         itemCount: offer.interests.length,
//                                         itemBuilder: (context, i) {
//                                           return Padding(
//                                             padding: EdgeInsets.only(right: 4),
//                                             child: EnhancedChip(
//                                               label: offer.interests[i],
//                                               backgroundColor: Theme.of(context)
//                                                   .colorScheme
//                                                   .secondary
//                                                   .withOpacity(0.1),
//                                               labelColor:
//                                                   Theme.of(
//                                                     context,
//                                                   ).colorScheme.primary,
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                   SizedBox(height: 8),
//                                   EnhancedButton(
//                                     onPressed: () => _respondToOffer(offer),
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Icon(Icons.favorite_border, size: 16),
//                                         SizedBox(width: 4),
//                                         Text('Interested'),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   Future<void> _respondToOffer(DateOffer offer) async {
//     try {
//       final user = await _authService.getCurrentUserProfile();
//       final subscription = await _purchaseService.getCurrentSubscription(
//         user.uid,
//       );

//       if (subscription.isValid == null || subscription.isValid == false) {
//         showDialog(
//           context: context,
//           builder: (context) => PremiumPopup(feature: 'Respond to date offers'),
//         );
//         return;
//       }

//       await _dateOfferService.respondToOffer(
//         offer.id,
//         user.uid,
//         user.name,
//         user.profileImageUrl,
//         user.gender,
//       );

//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Response sent successfully!')));
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to respond: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Widget _buildLoadingState() => Center(child: CircularProgressIndicator());
//   Widget _buildErrorState() => Center(child: Text('Error loading offers'));
//   Widget _buildEmptyState() => Center(child: Text('No offers found'));
// }
