import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/payment_models.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentAPI _paymentAPI = PaymentAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  List<PaymentMethod> _paymentMethods = [];
  String? _defaultPaymentMethodId;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final methods = await _paymentAPI.getPaymentMethods(user.uid);
        final defaultId = await _paymentAPI.getDefaultPaymentMethod(user.uid);
        setState(() {
          _paymentMethods = methods;
          _defaultPaymentMethodId = defaultId;
        });
      }
    } catch (e) {
      print('Error loading payment methods: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading payment methods')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPaymentMethod() async {
    // This would typically integrate with a payment gateway like Stripe
    final result = await showDialog<PaymentMethod>(
      context: context,
      builder: (context) => const AddPaymentMethodDialog(),
    );

    if (result != null) {
      setState(() => _paymentMethods.add(result));
    }
  }

  Future<void> _setDefaultPaymentMethod(String methodId) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _paymentAPI.setDefaultPaymentMethod(user.uid, methodId);
        setState(() => _defaultPaymentMethodId = methodId);
      }
    } catch (e) {
      print('Error setting default payment method: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating default payment method')),
      );
    }
  }

  Future<void> _removePaymentMethod(String methodId) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _paymentAPI.removePaymentMethod(user.uid, methodId);
        setState(() {
          _paymentMethods.removeWhere((method) => method.id == methodId);
          if (_defaultPaymentMethodId == methodId) {
            _defaultPaymentMethodId =
                _paymentMethods.isNotEmpty ? _paymentMethods.first.id : null;
          }
        });
      }
    } catch (e) {
      print('Error removing payment method: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error removing payment method')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _paymentMethods.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No payment methods added'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _addPaymentMethod,
                      child: const Text('Add Payment Method'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  final isDefault = method.id == _defaultPaymentMethodId;

                  return Card(
                    child: ListTile(
                      leading: Icon(_getCardIcon(method.brand)),
                      title: Text('•••• ${method.last4}'),
                      subtitle: Text(
                        '${method.brand} - Expires ${method.expiryMonth}/${method.expiryYear}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDefault)
                            Chip(
                              label: const Text('Default'),
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              labelStyle: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            )
                          else
                            TextButton(
                              onPressed:
                                  () => _setDefaultPaymentMethod(method.id),
                              child: const Text('Set Default'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removePaymentMethod(method.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPaymentMethod,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getCardIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
}

class AddPaymentMethodDialog extends StatefulWidget {
  const AddPaymentMethodDialog({Key? key}) : super(key: key);

  @override
  State<AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<AddPaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Payment Method'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter card number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'MM/YY',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name on Card',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter name on card';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // This would typically integrate with a payment gateway
              Navigator.pop(
                context,
                PaymentMethod(
                  id: DateTime.now().toString(),
                  userId: _authService.currentUser?.uid ?? '',
                  type: PaymentMethodType.creditCard,
                  holderName: _nameController.text,
                  brand: 'Visa',
                  last4: _cardNumberController.text.substring(
                    _cardNumberController.text.length - 4,
                  ),
                  expiryMonth: _expiryController.text.split('/')[0],
                  expiryYear: _expiryController.text.split('/')[1],
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
