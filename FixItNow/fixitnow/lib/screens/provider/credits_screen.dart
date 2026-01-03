import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/provider/credit_controller.dart';
import '../../models/credit_models.dart';
import '../../theme.dart';
import '../../widgets/cards.dart';

class ProviderCreditsScreen extends StatelessWidget {
  const ProviderCreditsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final ProviderCreditController controller = Get.put(
      ProviderCreditController(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Credits'), elevation: 0),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.creditAccount.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadCreditAccount(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCreditSummary(controller),
                  const SizedBox(height: 24),
                  _buildCreditBundles(controller),
                  const SizedBox(height: 24),
                  _buildTransactionHistory(controller),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCreditSummary(ProviderCreditController controller) {
    final account = controller.creditAccount.value;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Credit Balance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                if (account != null)
                  Text(
                    '${account.currentBalance}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            if (account != null)
              Column(
                children: [
                  _buildStatRow('Total Purchased', '${account.totalPurchased}'),
                  const SizedBox(height: 8),
                  _buildStatRow('Total Used', '${account.totalUsed}'),
                  if (account.lastPurchaseDate != null) ...[
                    const SizedBox(height: 8),
                    _buildStatRow(
                      'Last Purchase',
                      DateFormat.yMMMd().format(account.lastPurchaseDate!),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.toNamed('/provider/credits/purchase'),
                child: const Text('Buy More Credits'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCreditBundles(ProviderCreditController controller) {
    if (controller.availableBundles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Credit Packages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.availableBundles.length,
            itemBuilder: (context, index) {
              final bundle = controller.availableBundles[index];
              return _buildBundleCard(bundle, controller);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBundleCard(
    CreditBundle bundle,
    ProviderCreditController controller,
  ) {
    final isSelected = controller.selectedBundle.value?.id == bundle.id;

    return GestureDetector(
      onTap: () => controller.selectBundle(bundle),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? appTheme.primaryColor.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? appTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${bundle.creditAmount}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              bundle.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${bundle.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appTheme.primaryColor,
              ),
            ),
            if (bundle.discountPercentage != null) ...[
              const SizedBox(height: 4),
              Text(
                'Save ${bundle.discountPercentage}%',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(ProviderCreditController controller) {
    final transactions = controller.transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No transactions yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                transactions.length +
                (controller.hasMoreTransactions.value ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == transactions.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: controller.loadMoreTransactions,
                      child: const Text('Load More'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ),
                );
              }

              return _buildTransactionItem(transactions[index]);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionItem(CreditTransaction transaction) {
    final isCredit =
        transaction.type == 'purchase' || transaction.type == 'refund';
    final transactionColor = isCredit ? Colors.green : Colors.red;

    IconData iconData;
    switch (transaction.type) {
      case 'purchase':
        iconData = Icons.add_circle;
        break;
      case 'refund':
        iconData = Icons.replay;
        break;
      case 'used':
        iconData = Icons.remove_circle;
        break;
      case 'expired':
        iconData = Icons.timer_off;
        break;
      case 'bonus':
        iconData = Icons.card_giftcard;
        break;
      default:
        iconData = Icons.swap_horiz;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: transactionColor.withOpacity(0.1),
        child: Icon(iconData, color: transactionColor),
      ),
      title: Text(
        transaction.description ?? _getTypeLabel(transaction.type),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        DateFormat.yMMMd().add_jm().format(transaction.timestamp),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'}${transaction.amount}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: transactionColor,
          fontSize: 16,
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'purchase':
        return 'Credit Purchase';
      case 'refund':
        return 'Refunded Credits';
      case 'used':
        return 'Credits Used';
      case 'expired':
        return 'Credits Expired';
      case 'bonus':
        return 'Bonus Credits';
      default:
        return 'Credit Transaction';
    }
  }
}

class CreditPurchaseScreen extends StatelessWidget {
  const CreditPurchaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProviderCreditController controller =
        Get.find<ProviderCreditController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Credits')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              if (controller.errorMessage.value.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[900]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text(
                'Select Credit Package',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Credit bundles grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: controller.availableBundles.length,
                itemBuilder: (context, index) {
                  final bundle = controller.availableBundles[index];
                  final isSelected =
                      controller.selectedBundle.value?.id == bundle.id;

                  return GestureDetector(
                    onTap: () => controller.selectBundle(bundle),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? appTheme.primaryColor.withOpacity(0.1)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? appTheme.primaryColor
                                  : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (bundle.isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Most Popular',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          Text(
                            '${bundle.creditAmount}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bundle.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${bundle.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: appTheme.primaryColor,
                            ),
                          ),
                          if (bundle.discountPercentage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Save ${bundle.discountPercentage}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Mock payment methods - in a real app, integrate with payment provider
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPaymentMethodItem(
                    icon: Icons.credit_card,
                    title: 'Credit Card',
                    subtitle: '**** **** **** 1234',
                    isSelected: true,
                  ),
                  _buildPaymentMethodItem(
                    icon: Icons.account_balance,
                    title: 'Bank Account',
                    subtitle: '**** 5678',
                    isSelected: false,
                  ),
                  _buildPaymentMethodItem(
                    icon: Icons.payment,
                    title: 'PayPal',
                    subtitle: 'example@email.com',
                    isSelected: false,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Summary and purchase button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Selected Package',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          controller.selectedBundle.value?.name ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Credits', style: TextStyle(fontSize: 14)),
                        Text(
                          '${controller.selectedBundle.value?.creditAmount ?? 0}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${controller.selectedBundle.value?.price.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      controller.isProcessing.value
                          ? null
                          : () => _handlePurchase(controller, context),
                  child:
                      controller.isProcessing.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Complete Purchase',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'Your payment information is securely processed.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPaymentMethodItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? appTheme.primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        secondary: Icon(icon),
        value: isSelected,
        groupValue: true,
        onChanged: (value) {
          // In a real app, this would change the selected payment method
        },
        activeColor: appTheme.primaryColor,
      ),
    );
  }

  Future<void> _handlePurchase(
    ProviderCreditController controller,
    BuildContext context,
  ) async {
    if (controller.selectedBundle.value == null) {
      Get.snackbar(
        'Error',
        'Please select a credit package',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    // In a real app, you would validate payment information here

    final result = await controller.purchaseCredits('payment-method-1234');

    if (result['success']) {
      Get.back(); // Return to credits screen
      Get.snackbar(
        'Success',
        result['message'],
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
    }
  }
}
