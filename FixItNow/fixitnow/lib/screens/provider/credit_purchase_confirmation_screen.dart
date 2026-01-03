import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/credit_models.dart';
import '../../models/payment_models.dart';
import '../../services/credit_services.dart';
import '../../controllers/provider/credit_controller.dart';

// Helper extensions to add missing properties
extension CreditBundleProperties on CreditBundle {
  int get credits => creditAmount;
  int get bonus => 0; // Default value
}

extension PaymentMethodProperties on PaymentMethod {
  String get lastFourDigits => last4;
  String get cardholderName => holderName;
  String get cardType => brand;
}

// API class to interact with credit service
class CreditAPI {
  final CreditService _service = CreditService();

  Future<Map<String, dynamic>> addCreditsToProvider(
    int creditAmount,
    String transactionId,
    double price,
  ) async {
    // Implementation would call _service methods
    return {
      'success': true,
      'message': 'Credits added successfully',
      'transactionId': transactionId,
    };
  }
}

// API class to interact with payment service
class PaymentAPI {
  Future<PaymentResult> processPayment({
    required double amount,
    String? paymentMethodId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
    return PaymentResult(
      success: true,
      transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
      message: 'Payment processed successfully',
    );
  }
}

class PaymentResult {
  final bool success;
  final String transactionId;
  final String message;

  PaymentResult({
    required this.success,
    required this.transactionId,
    required this.message,
  });
}

class CreditPurchaseConfirmationScreen extends StatefulWidget {
  final CreditBundle creditBundle;
  final PaymentMethod? selectedPaymentMethod;

  const CreditPurchaseConfirmationScreen({
    Key? key,
    required this.creditBundle,
    this.selectedPaymentMethod,
  }) : super(key: key);

  @override
  State<CreditPurchaseConfirmationScreen> createState() =>
      _CreditPurchaseConfirmationScreenState();
}

class _CreditPurchaseConfirmationScreenState
    extends State<CreditPurchaseConfirmationScreen> {
  final CreditAPI _creditAPI = CreditAPI();
  final PaymentAPI _paymentAPI = PaymentAPI();

  bool _isProcessing = false;
  bool _useExistingPaymentMethod = false;

  // Credit card form fields
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameOnCardController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _useExistingPaymentMethod = widget.selectedPaymentMethod != null;

    // Pre-fill form if payment method is selected
    if (_useExistingPaymentMethod && widget.selectedPaymentMethod != null) {
      final method = widget.selectedPaymentMethod!;
      _cardNumberController.text = '•••• •••• •••• ${method.lastFourDigits}';
      _nameOnCardController.text = method.cardholderName;
      _expiryDateController.text =
          '${method.expiryMonth}/${method.expiryYear.toString().substring(2)}';
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _nameOnCardController.dispose();
    super.dispose();
  }

  Future<void> _completePurchase() async {
    // Validate form if not using existing payment method
    if (!_useExistingPaymentMethod) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      // Process payment
      final paymentResult = await _paymentAPI.processPayment(
        amount: widget.creditBundle.price,
        paymentMethodId:
            _useExistingPaymentMethod && widget.selectedPaymentMethod != null
                ? widget.selectedPaymentMethod!.id
                : null,
        paymentDetails:
            !_useExistingPaymentMethod
                ? {
                  'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
                  'expiryDate': _expiryDateController.text,
                  'cvv': _cvvController.text,
                  'nameOnCard': _nameOnCardController.text,
                }
                : null,
      );

      if (paymentResult.success) {
        // Add credits to provider account
        await _creditAPI.addCreditsToProvider(
          widget.creditBundle.credits,
          paymentResult.transactionId,
          widget.creditBundle.price,
        );

        // Show success message and navigate back
        Get.snackbar(
          'Purchase Successful',
          'Your credits have been added to your account',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate to receipt screen
        Get.offNamed(
          '/provider/credits/receipt',
          arguments: {
            'transactionId': paymentResult.transactionId,
            'credits': widget.creditBundle.credits,
            'amount': widget.creditBundle.price,
            'date': DateTime.now(),
          },
        );
      } else {
        throw Exception('Payment failed: ${paymentResult.message}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to complete purchase: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Purchase')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.creditBundle.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          currencyFormat.format(widget.creditBundle.price),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${widget.creditBundle.credits} credits'),
                    if (widget.creditBundle.bonus > 0)
                      Text(
                        '+ ${widget.creditBundle.bonus} bonus credits',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Text('Total')),
                        Text(
                          currencyFormat.format(widget.creditBundle.price),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment method section
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Existing payment method card
            if (_useExistingPaymentMethod &&
                widget.selectedPaymentMethod != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _getCardIcon(widget.selectedPaymentMethod!.cardType),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '**** **** **** ${widget.selectedPaymentMethod!.lastFourDigits}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  widget.selectedPaymentMethod!.cardholderName,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _useExistingPaymentMethod = false;
                              });
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // New payment method form
            if (!_useExistingPaymentMethod)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card number field
                        TextFormField(
                          controller: _cardNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Card Number',
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your card number';
                            }
                            if (value.replaceAll(' ', '').length != 16) {
                              return 'Please enter a valid card number';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // Format card number in groups of 4
                            final newText = value.replaceAll(' ', '');
                            if (newText.length > 16) {
                              _cardNumberController.text = value.substring(
                                0,
                                value.length - 1,
                              );
                              _cardNumberController
                                  .selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: _cardNumberController.text.length,
                                ),
                              );
                              return;
                            }

                            final formattedText = <String>[];
                            for (var i = 0; i < newText.length; i += 4) {
                              final end =
                                  i + 4 < newText.length
                                      ? i + 4
                                      : newText.length;
                              formattedText.add(newText.substring(i, end));
                            }

                            final formatted = formattedText.join(' ');
                            if (formatted != value) {
                              _cardNumberController.text = formatted;
                              _cardNumberController
                                  .selection = TextSelection.fromPosition(
                                TextPosition(offset: formatted.length),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Name on card field
                        TextFormField(
                          controller: _nameOnCardController,
                          decoration: const InputDecoration(
                            labelText: 'Name on Card',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the name on the card';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Expiry date and CVV fields
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _expiryDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Expiry Date (MM/YY)',
                                  prefixIcon: Icon(Icons.date_range),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter expiry date';
                                  }
                                  if (!RegExp(
                                    r'^\d{2}/\d{2}$',
                                  ).hasMatch(value)) {
                                    return 'Use format MM/YY';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // Format expiry date as MM/YY
                                  final newText = value.replaceAll('/', '');
                                  if (newText.length > 4) {
                                    _expiryDateController.text = value
                                        .substring(0, value.length - 1);
                                    _expiryDateController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset:
                                            _expiryDateController.text.length,
                                      ),
                                    );
                                    return;
                                  }

                                  if (newText.length >= 2 &&
                                      !value.contains('/')) {
                                    _expiryDateController.text =
                                        '${newText.substring(0, 2)}/${newText.substring(2)}';
                                    _expiryDateController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset:
                                            _expiryDateController.text.length,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _cvvController,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  prefixIcon: Icon(Icons.security),
                                ),
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter CVV';
                                  }
                                  if (value.length < 3 || value.length > 4) {
                                    return 'Invalid CVV';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  if (value.length > 4) {
                                    _cvvController.text = value.substring(0, 4);
                                    _cvvController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(offset: 4),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Save payment method checkbox
                        CheckboxListTile(
                          title: const Text(
                            'Save this payment method for future use',
                          ),
                          value: true,
                          onChanged: (value) {
                            // Always save payment method for now
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Purchase button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _completePurchase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child:
                    _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Complete Purchase - ${currencyFormat.format(widget.creditBundle.price)}',
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms and conditions
            const Center(
              child: Text(
                'By proceeding, you agree to our Terms & Conditions',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCardIcon(String cardType) {
    IconData icon;
    Color color;

    switch (cardType.toLowerCase()) {
      case 'visa':
        icon = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'mastercard':
        icon = Icons.credit_card;
        color = Colors.deepOrange;
        break;
      case 'amex':
        icon = Icons.credit_card;
        color = Colors.purple;
        break;
      default:
        icon = Icons.credit_card;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
