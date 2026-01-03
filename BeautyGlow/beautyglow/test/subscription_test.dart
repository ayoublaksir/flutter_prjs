import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../lib/models/subscription_status.dart';
import '../lib/services/subscription_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mockito/mockito.dart';

// Simple mocks
class MockPathProvider extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => './test/tmp';
}

class MockInAppPurchase extends Mock implements InAppPurchase {
  final _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseController.stream;

  void simulatePurchase(PurchaseDetails purchase) {
    _purchaseController.add([purchase]);
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    return ProductDetailsResponse(
      productDetails: [],
      notFoundIDs: [],
      error: null,
    );
  }

  void dispose() {
    _purchaseController.close();
  }
}

class MockPurchaseDetails implements PurchaseDetails {
  @override
  final String productId;
  @override
  final String? purchaseID;
  @override
  final PurchaseStatus status;
  @override
  final IAPError? error;
  @override
  bool pendingCompletePurchase = false;

  MockPurchaseDetails({
    required this.productId,
    this.purchaseID,
    required this.status,
    this.error,
  });

  @override
  String get productID => productId;

  @override
  PurchaseVerificationData get verificationData => PurchaseVerificationData(
        localVerificationData: 'test_verification_data',
        serverVerificationData: 'test_server_data',
        source: 'test',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestSubscriptionStatus extends SubscriptionStatus {
  TestSubscriptionStatus({
    required bool isPremium,
    required bool isLifetimePurchase,
    DateTime? subscriptionEndDate,
  }) : super(
          isPremium: isPremium,
          isLifetimePurchase: isLifetimePurchase,
          subscriptionEndDate: subscriptionEndDate,
          lastUpdated: DateTime.now(),
        );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Box<SubscriptionStatus> subscriptionBox;

  setUpAll(() async {
    // Set up path_provider mock
    PathProviderPlatform.instance = MockPathProvider();

    // Initialize Hive
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(SubscriptionStatusAdapter());
    }
  });

  setUp(() async {
    // Open the subscription box with the same name as in SubscriptionService
    subscriptionBox =
        await Hive.openBox<SubscriptionStatus>('subscription_box');
  });

  tearDown(() async {
    await subscriptionBox.clear();
    await subscriptionBox.close();
  });

  group('SubscriptionStatus Tests', () {
    test('Lifetime subscription should always be valid', () {
      final status = TestSubscriptionStatus(
        isPremium: true,
        isLifetimePurchase: true,
      );
      expect(status.isValid, true);
    });

    test('Monthly subscription should be valid before expiry', () {
      final status = TestSubscriptionStatus(
        isPremium: true,
        isLifetimePurchase: false,
        subscriptionEndDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(status.isValid, true);
    });

    test('Monthly subscription should be invalid after expiry', () {
      final status = TestSubscriptionStatus(
        isPremium: true,
        isLifetimePurchase: false,
        subscriptionEndDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(status.isValid, false);
    });

    test('Non-premium status should be invalid', () {
      final status = TestSubscriptionStatus(
        isPremium: false,
        isLifetimePurchase: false,
      );
      expect(status.isValid, false);
    });
  });

  group('Purchase Flow Tests', () {
    late MockInAppPurchase mockIAP;

    setUp(() {
      mockIAP = MockInAppPurchase();
    });

    tearDown(() {
      mockIAP.dispose();
    });

    test('Monthly subscription purchase should be processed', () async {
      final service = SubscriptionService(iapInstance: mockIAP);
      await service.init();

      // Simulate successful monthly purchase
      final purchase = MockPurchaseDetails(
        productId: 'beautyglow.sub.monthly',
        status: PurchaseStatus.purchased,
        purchaseID: 'test_purchase_id',
      );

      mockIAP.simulatePurchase(purchase);

      // Wait for purchase to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify subscription is active
      final status = subscriptionBox.get('current_subscription');
      expect(status?.isPremium, true);
      expect(status?.isLifetimePurchase, false);
      expect(status?.subscriptionEndDate?.isAfter(DateTime.now()), true);
    });

    test('Lifetime subscription purchase should be processed', () async {
      final service = SubscriptionService(iapInstance: mockIAP);
      await service.init();

      // Simulate successful lifetime purchase
      final purchase = MockPurchaseDetails(
        productId: 'beautyglow.lifetime',
        status: PurchaseStatus.purchased,
        purchaseID: 'test_purchase_id',
      );

      mockIAP.simulatePurchase(purchase);

      // Wait for purchase to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify subscription is active
      final status = subscriptionBox.get('current_subscription');
      expect(status?.isPremium, true);
      expect(status?.isLifetimePurchase, true);
      expect(status?.subscriptionEndDate, null);
    });
  });

  group('Restore Purchases Tests', () {
    late MockInAppPurchase mockIAP;

    setUp(() {
      mockIAP = MockInAppPurchase();
    });

    tearDown(() {
      mockIAP.dispose();
    });

    test('Should restore lifetime purchase', () async {
      final service = SubscriptionService(iapInstance: mockIAP);
      await service.init();

      // Simulate successful restore of lifetime purchase
      final purchase = MockPurchaseDetails(
        productId: 'beautyglow.lifetime',
        status: PurchaseStatus.restored,
        purchaseID: 'test_purchase_id',
      );

      mockIAP.simulatePurchase(purchase);

      // Trigger restore
      await service.restorePurchases();

      // Wait for restore to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify subscription is restored
      final status = subscriptionBox.get('current_subscription');
      expect(status?.isPremium, true);
      expect(status?.isLifetimePurchase, true);
    });

    test('Should restore monthly subscription', () async {
      final service = SubscriptionService(iapInstance: mockIAP);
      await service.init();

      // Simulate successful restore of monthly subscription
      final purchase = MockPurchaseDetails(
        productId: 'beautyglow.sub.monthly',
        status: PurchaseStatus.restored,
        purchaseID: 'test_purchase_id',
      );

      mockIAP.simulatePurchase(purchase);

      // Trigger restore
      await service.restorePurchases();

      // Wait for restore to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify subscription is restored
      final status = subscriptionBox.get('current_subscription');
      expect(status?.isPremium, true);
      expect(status?.isLifetimePurchase, false);
      expect(status?.subscriptionEndDate?.isAfter(DateTime.now()), true);
    });
  });

  group('Auto-Renewal Tests', () {
    late MockInAppPurchase mockIAP;

    setUp(() {
      mockIAP = MockInAppPurchase();
    });

    tearDown(() {
      mockIAP.dispose();
    });

    test('Should attempt renewal before subscription expires', () async {
      final service = SubscriptionService(iapInstance: mockIAP);
      await service.init();

      // Set up an active subscription that's close to expiry
      final expiryDate = DateTime.now().add(const Duration(hours: 1));
      final status = TestSubscriptionStatus(
        isPremium: true,
        isLifetimePurchase: false,
        subscriptionEndDate: expiryDate,
      );

      await subscriptionBox.put('current_subscription', status);

      // Verify auto-renewal is scheduled
      expect(service.subscriptionEndDate, expiryDate);

      // Simulate time passing and renewal purchase
      final renewalPurchase = MockPurchaseDetails(
        productId: 'beautyglow.sub.monthly',
        status: PurchaseStatus.purchased,
        purchaseID: 'renewal_purchase_id',
      );

      mockIAP.simulatePurchase(renewalPurchase);

      // Wait for renewal to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify subscription is renewed
      final renewedStatus = subscriptionBox.get('current_subscription');
      expect(renewedStatus?.isPremium, true);
      expect(renewedStatus?.isLifetimePurchase, false);
      expect(renewedStatus?.subscriptionEndDate?.isAfter(expiryDate), true);
    });

    test('Should not attempt renewal for lifetime purchase', () async {
      final service = SubscriptionService(iapInstance: mockIAP);
      await service.init();

      // Set up a lifetime subscription
      final status = TestSubscriptionStatus(
        isPremium: true,
        isLifetimePurchase: true,
      );

      await subscriptionBox.put('current_subscription', status);

      // Verify no auto-renewal is scheduled
      expect(service.subscriptionEndDate, null);
    });
  });
}
