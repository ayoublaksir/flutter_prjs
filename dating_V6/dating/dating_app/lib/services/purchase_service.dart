import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show ProrationMode, GooglePlayPurchaseParam, ChangeSubscriptionParam;
import 'package:dating_app/services/auth_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating_app/models/subscription.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseService with ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;
  final AuthService _authService = AuthService();
  String? _activeSubscriptionId;

  // Define your product IDs here
  static const Set<String> _productIds = {
    'premium_monthly',
    'premium_yearly',
    'boost_pack',
  };

  // Subscription product IDs
  final Set<String> _subscriptionProductIds = {
    'premium_monthly',
    'premium_yearly',
    'premium_quarterly',
  };

  PurchaseService() {
    _init();
  }

  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  bool get loading => _loading;
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  String? get queryProductError => _queryProductError;
  bool get hasPremiumSubscription => _activeSubscriptionId != null;
  String? get activeSubscriptionId => _activeSubscriptionId;

  Future<void> _init() async {
    _loading = true;
    notifyListeners();

    // Check if the store is available
    final isAvailable = await _inAppPurchase.isAvailable();
    _isAvailable = isAvailable;

    if (isAvailable) {
      // Set up the purchase stream listener
      final purchaseUpdated = _inAppPurchase.purchaseStream;
      purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: _updateStreamOnDone,
        onError: _updateStreamOnError,
      );

      // Load the product details
      await _loadProducts();

      // Restore previous purchases
      await restorePurchases();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_subscriptionProductIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
        // For development, create mock products when real ones aren't available
        if (response.productDetails.isEmpty) {
          _products = _createMockProducts();
        } else {
          _products = response.productDetails;
        }
      } else {
        _products = response.productDetails;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading products: $e');
      // Create mock products on error for development
      _products = _createMockProducts();
      notifyListeners();
    }
  }

  List<ProductDetails> _createMockProducts() {
    return [
      ProductDetails(
        id: 'premium_monthly',
        title: 'Premium Monthly (Test)',
        description: 'Monthly premium subscription for testing',
        price: '\$9.99',
        rawPrice: 9.99,
        currencyCode: 'USD',
      ),
      ProductDetails(
        id: 'premium_yearly',
        title: 'Premium Yearly (Test)',
        description: 'Yearly premium subscription for testing',
        price: '\$99.99',
        rawPrice: 99.99,
        currencyCode: 'USD',
      ),
    ];
  }

  Future<List<Subscription>> getSubscriptionPlans() async {
    if (_products.isEmpty) {
      await _loadProducts();
    }

    return _products.map((product) {
      // Parse duration from product ID
      String duration = 'month';
      if (product.id.contains('yearly')) {
        duration = 'year';
      } else if (product.id.contains('quarterly')) {
        duration = '3 months';
      }

      return Subscription(
        id: product.id,
        name: product.title,
        description: product.description,
        price: product.price,
        duration: duration,
        productDetails: product,
      );
    }).toList();
  }

  Future<void> purchaseSubscription(Subscription subscription) async {
    if (!_isAvailable) {
      throw Exception('Store is not available');
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: subscription.productDetails!,
      applicationUserName: null,
    );

    try {
      // Start the purchase flow
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      throw Exception('Failed to initiate purchase: $e');
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        print('Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase
        try {
          await completePurchase(purchaseDetails);

          // Deliver product
          if (purchaseDetails.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchaseDetails);
          }
        } catch (e) {
          print('Error processing purchase: $e');
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('Error purchasing: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        print('Purchase canceled');
      }
    }

    // Update purchases list
    _purchases = purchaseDetailsList;
    notifyListeners();
  }

  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    // Here you would typically verify the purchase with your backend
    // For now, we'll just consider it valid

    if (_subscriptionProductIds.contains(purchaseDetails.productID)) {
      _activeSubscriptionId = purchaseDetails.productID;
      notifyListeners();

      // Save the subscription status to persistent storage
      // This is where you'd update your backend or local storage
    }
  }

  void _updateStreamOnDone() {
    _subscription = null;
    print('Purchase stream closed');
  }

  void _updateStreamOnError(dynamic error) {
    print('Error in purchase stream: $error');
  }

  Future<void> _queryProducts() async {
    final response = await _inAppPurchase.queryProductDetails(_productIds);

    if (response.error != null) {
      _queryProductError = response.error!.message;
      _products = [];
      notifyListeners();
      return;
    }

    if (response.productDetails.isEmpty) {
      _queryProductError = 'No products found';
      _products = [];
      notifyListeners();
      return;
    }

    _products = response.productDetails;
    _queryProductError = null;
    notifyListeners();
  }

  Future<void> _getPastPurchases() async {
    if (Platform.isAndroid) {
      final androidAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final queryPurchaseDetailsResponse =
          await androidAddition.queryPastPurchases();
      _purchases = queryPurchaseDetailsResponse.pastPurchases;
    }

    // Check if user has premium subscription
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      final hasPremium = _purchases.any(
        (purchase) =>
            purchase.status == PurchaseStatus.purchased &&
            purchase.productID.contains('premium'),
      );

      if (hasPremium) {
        await _authService.updatePremiumStatus(userId, true);
      }
    }

    notifyListeners();
  }

  Future<void> buyProduct(ProductDetails product) async {
    try {
      // For development/testing, simulate successful purchase
      if (product.id.contains('test') || !_isAvailable) {
        print('Simulating purchase for ${product.id}');

        // Create a mock purchase
        final purchase = PurchaseDetails(
          productID: product.id,
          verificationData: PurchaseVerificationData(
            localVerificationData: 'test',
            serverVerificationData: 'test',
            source: 'test',
          ),
          transactionDate: DateTime.now().toIso8601String(),
          status: PurchaseStatus.purchased,
        );

        // Process the mock purchase
        await completePurchase(purchase);
        notifyListeners();
        return;
      }

      // Real purchase flow
      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );

      if (product.id.contains('premium')) {
        // This is a subscription
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // This is a consumable product
        await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      print('Error buying product: $e');
      rethrow;
    }
  }

  // Add method to upgrade/downgrade subscription
  Future<void> upgradeSubscription(
    ProductDetails newProduct,
    PurchaseDetails oldPurchase,
  ) async {
    try {
      if (Platform.isAndroid) {
        final purchaseParam = GooglePlayPurchaseParam(
          productDetails: newProduct,
          changeSubscriptionParam: ChangeSubscriptionParam(
            oldPurchaseDetails: oldPurchase as GooglePlayPurchaseDetails,
          ),
        );
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // On iOS, just purchase the new subscription
        await buyProduct(newProduct);
      }
    } catch (e) {
      print('Error upgrading subscription: $e');
      rethrow;
    }
  }

  // Update this method in the PurchaseService class
  void presentCodeRedemptionSheet() {
    if (Platform.isIOS) {
      // This is an iOS-specific feature
      try {
        // Use the iOS-specific platform addition
        final iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        iosPlatformAddition.presentCodeRedemptionSheet();
      } catch (e) {
        print('Error presenting code redemption sheet: $e');
      }
    } else {
      // For non-iOS platforms, we can show a message or do nothing
      print('Code redemption is only available on iOS');
    }
  }

  // Add this method to the PurchaseService class
  Future<Subscription> getCurrentSubscription(String userId) async {
    try {
      // Check if user has any active premium purchases
      final hasPremium = _purchases.any(
        (purchase) =>
            purchase.status == PurchaseStatus.purchased &&
            purchase.productID.contains('premium'),
      );

      if (hasPremium) {
        // Find the specific premium product
        final premiumPurchase = _purchases.firstWhere(
          (purchase) =>
              purchase.status == PurchaseStatus.purchased &&
              purchase.productID.contains('premium'),
        );

        // Determine subscription type
        SubscriptionType type = SubscriptionType.free;
        if (premiumPurchase.productID.contains('monthly')) {
          type = SubscriptionType.monthly;
        } else if (premiumPurchase.productID.contains('yearly')) {
          type = SubscriptionType.yearly;
        }

        return Subscription(
          id: premiumPurchase.productID,
          name: "Premium Subscription",
          description: "Full access to premium features",
          price: "Purchased",
          duration: type == SubscriptionType.monthly ? "1 month" : "1 year",
          userId: userId,
          isValid: true,
          expiryDate: DateTime.now().add(Duration(days: 30)), // Placeholder
          type: type,
          purchaseDate:
              premiumPurchase.transactionDate != null
                  ? DateTime.parse(premiumPurchase.transactionDate!)
                  : DateTime.now(),
        );
      }

      // Return free subscription if no premium found
      return Subscription(
        id: "free_subscription",
        name: "Free Plan",
        description: "Basic access",
        price: "Free",
        duration: "Unlimited",
        userId: userId,
        isValid: false,
        type: SubscriptionType.free,
      );
    } catch (e) {
      print('Error getting subscription: $e');
      // Return default free subscription on error
      return Subscription(
        id: "free_subscription",
        name: "Free Plan",
        description: "Basic access",
        price: "Free",
        duration: "Unlimited",
        userId: userId,
        isValid: false,
        type: SubscriptionType.free,
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // Update the initialize method to handle errors better
  Future<void> initialize() async {
    try {
      // Check if the store is available
      final isAvailable = await _inAppPurchase.isAvailable();
      _isAvailable = isAvailable;

      if (isAvailable) {
        // Set up the purchase stream listener
        final purchaseUpdated = _inAppPurchase.purchaseStream;
        _subscription = purchaseUpdated.listen(
          _onPurchaseUpdate,
          onDone: _updateStreamOnDone,
          onError: _updateStreamOnError,
        );

        // Load the product details
        try {
          await _loadProducts();
        } catch (e) {
          print('Error loading products: $e');
          // Continue even if product loading fails
        }

        // Restore previous purchases
        try {
          await restorePurchases();
        } catch (e) {
          print('Error restoring purchases: $e');
          // Continue even if restore fails
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error initializing purchase service: $e');
      // Don't rethrow, allow app to continue
    }
  }

  // Check if user has premium
  Future<bool> isPremiumUser() async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) return false;

      final subscription = await getCurrentSubscription(userId);
      return subscription.isValid ?? false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  // Complete purchase and update Firestore
  Future<Subscription> completePurchase(PurchaseDetails purchase) async {
    try {
      // Verify the purchase first
      if (purchase.status != PurchaseStatus.purchased) {
        throw Exception('Purchase not completed');
      }

      final userId = await _authService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // Determine subscription type
      SubscriptionType type = SubscriptionType.free;
      if (purchase.productID.contains('monthly')) {
        type = SubscriptionType.monthly;
      } else if (purchase.productID.contains('yearly')) {
        type = SubscriptionType.yearly;
      }

      // Calculate expiry date
      final now = DateTime.now();
      final expiryDate =
          type == SubscriptionType.monthly
              ? now.add(Duration(days: 30))
              : now.add(Duration(days: 365));

      // Create subscription object
      final subscription = Subscription(
        id: purchase.productID,
        name:
            type == SubscriptionType.monthly
                ? "Monthly Premium"
                : "Yearly Premium",
        description: "Full access to premium features",
        price: "Purchased",
        duration: type == SubscriptionType.monthly ? "1 month" : "1 year",
        userId: userId,
        isValid: true,
        expiryDate: expiryDate,
        type: type,
        purchaseDate: now,
      );

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(userId)
          .set({
            'userId': userId,
            'productId': purchase.productID,
            'isValid': true,
            'expiryDate': expiryDate,
            'type': type.toString().split('.').last,
            'purchaseDate': now,
          });

      // Notify listeners
      notifyListeners();

      return subscription;
    } catch (e) {
      print('Error completing purchase: $e');
      rethrow;
    }
  }

  // Add this method to your PurchaseService class
  Future<List<ProductDetails>> getProducts() async {
    if (_products.isEmpty) {
      await _loadProducts();
    }
    return _products;
  }
}
