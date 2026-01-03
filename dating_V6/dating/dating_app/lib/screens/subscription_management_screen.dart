import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/services/purchase_service.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../widgets/modern_app_bar.dart';
import 'dart:io';
import '../models/subscription.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionManagementScreenState createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  bool _isLoading = true;
  List<Subscription> _subscriptionPlans = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
  }

  Future<void> _loadSubscriptionPlans() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final purchaseService = Provider.of<PurchaseService>(
        context,
        listen: false,
      );
      final plans = await purchaseService.getSubscriptionPlans();

      setState(() {
        _subscriptionPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subscription plans: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(title: 'Manage Subscription'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
              )
              : _subscriptionPlans.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No subscription plans available'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadSubscriptionPlans,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _subscriptionPlans.length,
                itemBuilder: (context, index) {
                  final plan = _subscriptionPlans[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(plan.name),
                      subtitle: Text('${plan.price} / ${plan.duration}'),
                      trailing: ElevatedButton(
                        onPressed: () => _subscribeToPlan(plan),
                        child: const Text('Subscribe'),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Future<void> _subscribeToPlan(Subscription plan) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final purchaseService = Provider.of<PurchaseService>(
        context,
        listen: false,
      );
      await purchaseService.purchaseSubscription(plan);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subscription successful!')));

      Navigator.pop(context, true); // Return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to subscribe: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    PurchaseDetails purchase,
    PurchaseService purchaseService,
    AuthService authService,
  ) {
    // Find the product details for this purchase
    final productDetails = purchaseService.products.firstWhere(
      (product) => product.id == purchase.productID,
      orElse:
          () => ProductDetails(
            id: purchase.productID,
            title: 'Premium Subscription',
            description: 'Your premium subscription',
            price: 'Active',
            rawPrice: 0,
            currencyCode: '',
          ),
    );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productDetails.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(productDetails.description),
            const SizedBox(height: 8),
            Text('Status: Active'),
            const SizedBox(height: 8),
            Text('Price: ${productDetails.price}'),
            if (purchase.transactionDate != null)
              Text('Purchased: ${_formatDate(purchase.transactionDate!)}'),
            const SizedBox(height: 16),
            if (productDetails.id.contains('monthly') &&
                purchaseService.products.any((p) => p.id.contains('yearly')))
              ElevatedButton(
                onPressed:
                    () =>
                        _showUpgradeOptions(context, purchase, purchaseService),
                child: const Text('Upgrade Subscription'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOptions(
    BuildContext context,
    PurchaseService purchaseService,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore Purchases'),
              onTap: () {
                purchaseService.restorePurchases();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restoring previous purchases...'),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Manage Subscription in Store'),
              subtitle: const Text('Cancel or change your subscription'),
              onTap: () {
                // Open the subscription management page in the store
                if (Platform.isAndroid) {
                  // Launch Google Play subscription management
                  // You would use url_launcher package here
                } else if (Platform.isIOS) {
                  // Launch App Store subscription management
                  // You would use url_launcher package here
                }
              },
            ),
            if (Platform.isIOS)
              ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: const Text('Redeem Code'),
                onTap: () {
                  purchaseService.presentCodeRedemptionSheet();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeOptions(
    BuildContext context,
    PurchaseDetails currentPurchase,
    PurchaseService purchaseService,
  ) {
    final yearlyProduct = purchaseService.products.firstWhere(
      (p) => p.id.contains('yearly'),
      orElse:
          () => ProductDetails(
            id: '',
            title: '',
            description: '',
            price: '',
            rawPrice: 0,
            currencyCode: '',
          ),
    );

    if (yearlyProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yearly subscription not available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Upgrade to Yearly'),
            content: Text(
              'Would you like to upgrade to the yearly plan? '
              'You\'ll be charged ${yearlyProduct.price} and your monthly subscription will be replaced.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  purchaseService.upgradeSubscription(
                    yearlyProduct,
                    currentPurchase,
                  );
                },
                child: const Text('Upgrade'),
              ),
            ],
          ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
