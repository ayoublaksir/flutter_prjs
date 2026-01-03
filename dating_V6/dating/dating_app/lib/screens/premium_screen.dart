import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/services/purchase_service.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/enhanced_button.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  _PremiumScreenState createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = true;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final purchaseService = Provider.of<PurchaseService>(
      context,
      listen: false,
    );
    final products = await purchaseService.getProducts();

    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(title: 'Premium Membership', showBackButton: true),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _products.isEmpty
              ? _buildEmptyState()
              : _buildSubscriptionOptions(),
      floatingActionButton: ElevatedButton(
        onPressed: () {
          final purchaseService = Provider.of<PurchaseService>(
            context,
            listen: false,
          );
          purchaseService.restorePurchases();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restoring previous purchases...')),
          );
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
        child: Text('Restore Purchases'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No subscription plans available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Please try again later or contact support',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 30),
          EnhancedButton(
            onPressed: () {
              _loadProducts(); // Try loading again
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.star, color: Colors.white, size: 60),
          SizedBox(height: 16),
          Text(
            'Upgrade to Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Unlock all features and enhance your dating experience',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.favorite,
        'title': 'Unlimited Matches',
        'description': 'Connect with as many people as you want',
      },
      {
        'icon': Icons.visibility,
        'title': 'See Who Likes You',
        'description': 'Know who\'s interested before you swipe',
      },
      {
        'icon': Icons.star,
        'title': 'Priority Profile',
        'description': 'Get more visibility in search results',
      },
      {
        'icon': Icons.message,
        'title': 'Advanced Messaging',
        'description': 'Send photos and voice messages',
      },
      {
        'icon': Icons.location_on,
        'title': 'Global Search',
        'description': 'Find matches anywhere in the world',
      },
    ];

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Premium Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...features.map(
            (feature) => _buildFeatureItem(
              icon: feature['icon'] as IconData,
              title: feature['title'] as String,
              description: feature['description'] as String,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOptions() {
    if (_products.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No subscription options available at the moment',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Plan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ..._products.map((product) => _buildSubscriptionOption(product)),
          SizedBox(height: 24),
          Text(
            'Subscriptions will automatically renew unless canceled at least 24 hours before the end of the current period. You can manage your subscriptions in your account settings.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption(ProductDetails product) {
    final isMonthly = product.id.contains('monthly');
    final purchaseService = Provider.of<PurchaseService>(
      context,
      listen: false,
    );

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isMonthly
                  ? Colors.grey.withOpacity(0.3)
                  : Theme.of(context).colorScheme.primary,
          width: isMonthly ? 1 : 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isMonthly ? 'Monthly' : 'Yearly',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                if (!isMonthly)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'SAVE 50%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              product.price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              isMonthly ? 'per month' : 'per year',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            EnhancedButton(
              onPressed: () async {
                try {
                  await purchaseService.buyProduct(product);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: Text(
                'Subscribe Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              backgroundColor:
                  isMonthly
                      ? Theme.of(context).colorScheme.primary
                      : Colors.pink,
            ),
          ],
        ),
      ),
    );
  }
}
