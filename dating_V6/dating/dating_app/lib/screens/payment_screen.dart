import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:dating_app/services/purchase_service.dart';
import 'package:dating_app/services/auth_service.dart';
import 'subscription_management_screen.dart';

class PaymentScreen extends StatefulWidget {
  final ProductDetails product;

  const PaymentScreen({Key? key, required this.product}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _processingPayment = false;

  @override
  Widget build(BuildContext context) {
    final purchaseService = Provider.of<PurchaseService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium Features')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium badge/banner
              GestureDetector(
                onTap: () => _navigateToSubscriptionScreen(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade300, Colors.purple.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 30),
                          SizedBox(width: 8),
                          Text(
                            purchaseService.hasPremiumSubscription
                                ? 'Premium Active'
                                : 'Upgrade to Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        purchaseService.hasPremiumSubscription
                            ? 'Enjoy your premium benefits!'
                            : 'Unlock all features and enhance your experience',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 12),
                      if (!purchaseService.hasPremiumSubscription)
                        ElevatedButton(
                          onPressed:
                              () => _navigateToSubscriptionScreen(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                          ),
                          child: Text('Get Premium Now'),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Premium features list
              Text(
                'Premium Features',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              _buildFeatureItem(
                icon: Icons.visibility,
                title: 'See who liked you',
                description:
                    'Discover all users who have shown interest in your profile',
                isPremium: true,
                isUnlocked: purchaseService.hasPremiumSubscription,
              ),

              _buildFeatureItem(
                icon: Icons.flash_on,
                title: 'Unlimited swipes',
                description:
                    'No daily limit on the number of profiles you can view',
                isPremium: true,
                isUnlocked: purchaseService.hasPremiumSubscription,
              ),

              _buildFeatureItem(
                icon: Icons.location_on,
                title: 'Global search',
                description: 'Connect with people from anywhere in the world',
                isPremium: true,
                isUnlocked: purchaseService.hasPremiumSubscription,
              ),

              _buildFeatureItem(
                icon: Icons.undo,
                title: 'Rewind feature',
                description:
                    'Change your mind? Go back to profiles you passed on',
                isPremium: true,
                isUnlocked: purchaseService.hasPremiumSubscription,
              ),

              SizedBox(height: 24),

              if (!purchaseService.hasPremiumSubscription)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToSubscriptionScreen(context),
                    icon: Icon(Icons.star),
                    label: Text('Subscribe Now'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isPremium,
    required bool isUnlocked,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isPremium && !isUnlocked
                      ? Colors.grey.shade200
                      : Colors.purple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isPremium && !isUnlocked ? Colors.grey : Colors.purple,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isPremium && !isUnlocked
                                ? Colors.grey
                                : Colors.black,
                      ),
                    ),
                    if (isPremium)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.star,
                          color: isUnlocked ? Colors.amber : Colors.grey,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color:
                        isPremium && !isUnlocked ? Colors.grey : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToSubscriptionScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubscriptionManagementScreen()),
    );

    if (result == true) {
      // Subscription was successful, you might want to refresh the UI
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('You are now a premium member!')));
    }
  }
}
