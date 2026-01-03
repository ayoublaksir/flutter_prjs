// screens/provider/payment_settings_screen.dart
// Provider payment settings screen

import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final UserAPI _userAPI = UserAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  Map<String, dynamic> _paymentSettings = {};
  Map<String, dynamic> _bankDetails = {};

  @override
  void initState() {
    super.initState();
    _loadPaymentSettings();
  }

  Future<void> _loadPaymentSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final provider = await _userAPI.getProviderProfile(user.uid);
        if (provider != null) {
          setState(() {
            _paymentSettings = provider.pricingSettings;
            _bankDetails = provider.bankDetails;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading payment settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Settings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bank account section
                    const Text(
                      'Bank Account Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildBankDetailRow(
                              'Account Holder',
                              _bankDetails['accountName'] ?? 'Not set',
                            ),
                            const Divider(),
                            _buildBankDetailRow(
                              'Bank Name',
                              _bankDetails['bankName'] ?? 'Not set',
                            ),
                            const Divider(),
                            _buildBankDetailRow(
                              'Account Number',
                              _bankDetails['accountNumber'] ?? 'Not set',
                            ),
                            const Divider(),
                            _buildBankDetailRow(
                              'Routing Number',
                              _bankDetails['routingNumber'] ?? 'Not set',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment methods section
                    const Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Accept Credit Cards'),
                      subtitle: const Text(
                        'Allow customers to pay with credit cards',
                      ),
                      value: _paymentSettings['acceptCreditCards'] ?? false,
                      onChanged: (value) {
                        // Update payment settings
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Accept Cash'),
                      subtitle: const Text('Allow customers to pay with cash'),
                      value: _paymentSettings['acceptCash'] ?? true,
                      onChanged: (value) {
                        // Update payment settings
                      },
                    ),

                    const SizedBox(height: 24),

                    // Payout settings
                    const Text(
                      'Payout Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Payout Schedule'),
                      subtitle: Text(
                        _paymentSettings['payoutSchedule'] ?? 'Weekly',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Show payout schedule options
                      },
                    ),

                    const SizedBox(height: 24),

                    // Update button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Save payment settings
                        },
                        child: const Text('Update Payment Settings'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}
