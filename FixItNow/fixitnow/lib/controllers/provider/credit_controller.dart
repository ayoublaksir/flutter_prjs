import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/credit_models.dart';
import '../../services/credit_services.dart';
import '../base_controller.dart';

class ProviderCreditController extends BaseController {
  final CreditService _creditService = CreditService();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;
  final RxString errorMessage = ''.obs;

  // Credit account data
  final Rx<ProviderCreditAccount?> creditAccount = Rx<ProviderCreditAccount?>(
    null,
  );

  // Available bundles
  final RxList<CreditBundle> availableBundles = <CreditBundle>[].obs;

  // Transaction history with pagination
  final RxList<CreditTransaction> transactions = <CreditTransaction>[].obs;
  final RxBool hasMoreTransactions = true.obs;
  DocumentSnapshot? _lastTransactionDoc;

  // Selected bundle for purchase
  final Rx<CreditBundle?> selectedBundle = Rx<CreditBundle?>(null);

  @override
  void onInit() {
    super.onInit();
    loadCreditAccount();
    loadCreditBundles();
  }

  // Load provider's credit account
  Future<void> loadCreditAccount() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final account = await _creditService.getProviderCreditAccount();
      creditAccount.value = account;

      if (account != null && account.recentTransactions.isNotEmpty) {
        transactions.value = account.recentTransactions;
      }
    } catch (e) {
      errorMessage.value = 'Failed to load credit account: $e';
      print('Error loading credit account: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load available credit bundles
  Future<void> loadCreditBundles() async {
    try {
      final bundles = await _creditService.getCreditBundles();
      availableBundles.value = bundles;

      // Select the most popular bundle by default, or the first one
      final popularBundle = bundles.firstWhereOrNull(
        (bundle) => bundle.isPopular,
      );
      selectedBundle.value =
          popularBundle ?? (bundles.isNotEmpty ? bundles.first : null);
    } catch (e) {
      print('Error loading credit bundles: $e');
    }
  }

  // Load transaction history with pagination
  Future<void> loadMoreTransactions() async {
    if (!hasMoreTransactions.value || isLoading.value) return;

    try {
      isLoading.value = true;

      final user = currentUser;
      if (user == null) return;

      final newTransactions = await _creditService.getCreditTransactions(
        providerId: user.uid,
        startAfter: _lastTransactionDoc,
      );

      if (newTransactions.isEmpty) {
        hasMoreTransactions.value = false;
      } else {
        transactions.addAll(newTransactions);
        _lastTransactionDoc =
            null; // Would be set from the actual Firebase document
      }
    } catch (e) {
      print('Error loading more transactions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Select a bundle for purchase
  void selectBundle(CreditBundle bundle) {
    selectedBundle.value = bundle;
  }

  // Purchase the selected bundle
  Future<Map<String, dynamic>> purchaseCredits(String paymentMethodId) async {
    try {
      if (selectedBundle.value == null) {
        return {'success': false, 'message': 'Please select a credit bundle'};
      }

      isProcessing.value = true;
      errorMessage.value = '';

      final result = await _creditService.purchaseCredits(
        bundleId: selectedBundle.value!.id,
        paymentMethodId: paymentMethodId,
      );

      if (result['success']) {
        // Refresh the account data
        await loadCreditAccount();
      } else {
        errorMessage.value = result['message'] ?? 'Failed to purchase credits';
      }

      return result;
    } catch (e) {
      errorMessage.value = 'Error processing purchase: $e';
      print('Error purchasing credits: $e');
      return {'success': false, 'message': 'Error processing purchase: $e'};
    } finally {
      isProcessing.value = false;
    }
  }

  // Check if provider has enough credits for an action
  bool hasEnoughCreditsForAction(int requiredAmount) {
    final account = creditAccount.value;
    if (account == null) return false;
    return account.currentBalance >= requiredAmount;
  }

  // Calculate how many more credits a provider needs
  int calculateCreditsNeeded(int requiredAmount) {
    final account = creditAccount.value;
    if (account == null) return requiredAmount;

    final currentBalance = account.currentBalance;
    if (currentBalance >= requiredAmount) return 0;

    return requiredAmount - currentBalance;
  }

  // Get a recommended bundle to purchase based on needed credits
  CreditBundle? getRecommendedBundle(int neededCredits) {
    if (availableBundles.isEmpty) return null;

    // Find the smallest bundle that covers the needed credits
    final sortedBundles =
        availableBundles.toList()
          ..sort((a, b) => a.creditAmount.compareTo(b.creditAmount));

    for (final bundle in sortedBundles) {
      if (bundle.creditAmount >= neededCredits) {
        return bundle;
      }
    }

    // If no bundle is large enough, return the largest one
    return sortedBundles.last;
  }
}
