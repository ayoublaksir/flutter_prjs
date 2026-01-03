import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/payment_models.dart' as payment_models;
import '../../models/provider_models.dart' as provider_models;
import '../../services/api_services.dart';
import '../base_controller.dart';

class PaymentSettingsController extends BaseController {
  // Services via dependency injection
  final PaymentAPI _paymentAPI = Get.find<PaymentAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();

  // Reactive state
  final Rx<payment_models.PaymentMethod?> defaultPaymentMethod =
      Rx<payment_models.PaymentMethod?>(null);
  final RxList<payment_models.PaymentMethod> paymentMethods =
      <payment_models.PaymentMethod>[].obs;
  final Rx<provider_models.BankAccount?> bankAccount =
      Rx<provider_models.BankAccount?>(null);
  final Rx<provider_models.PricingSettings> pricingSettings =
      provider_models.PricingSettings(
        baseHourlyRate: 0,
        minimumServiceFee: 0,
        cancellationFee: 0,
        emergencyRate: 0,
        weekendRate: 0,
      ).obs;

  // Form controllers
  final hourlyRateController = TextEditingController();
  final minimumFeeController = TextEditingController();
  final cancellationFeeController = TextEditingController();
  final emergencyRateController = TextEditingController();
  final weekendRateController = TextEditingController();

  // Bank account form controllers
  final accountNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final routingNumberController = TextEditingController();
  final bankNameController = TextEditingController();

  // Form keys
  final pricingFormKey = GlobalKey<FormState>();
  final bankAccountFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadPaymentSettings();
  }

  @override
  void onClose() {
    // Dispose all controllers
    hourlyRateController.dispose();
    minimumFeeController.dispose();
    cancellationFeeController.dispose();
    emergencyRateController.dispose();
    weekendRateController.dispose();
    accountNameController.dispose();
    accountNumberController.dispose();
    routingNumberController.dispose();
    bankNameController.dispose();
    super.onClose();
  }

  /// Load payment settings
  Future<void> loadPaymentSettings() {
    return runWithLoading(() async {
      await Future.wait([
        _loadPricingSettings(),
        _loadPaymentMethods(),
        _loadBankAccount(),
      ]);
    });
  }

  /// Load pricing settings
  Future<void> _loadPricingSettings() async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      showError('User not authenticated');
      return;
    }

    final provider = await _userAPI.getProviderProfile(userId);
    if (provider != null && provider.pricingSettings != null) {
      pricingSettings.value = provider_models.PricingSettings.fromMap(
        provider.pricingSettings!,
      );

      // Update controllers
      hourlyRateController.text =
          pricingSettings.value.baseHourlyRate.toString();
      minimumFeeController.text =
          pricingSettings.value.minimumServiceFee.toString();
      cancellationFeeController.text =
          pricingSettings.value.cancellationFee.toString();
      emergencyRateController.text =
          pricingSettings.value.emergencyRate.toString();
      weekendRateController.text = pricingSettings.value.weekendRate.toString();
    }
  }

  /// Load payment methods
  Future<void> _loadPaymentMethods() async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      showError('User not authenticated');
      return;
    }

    final methods = await _paymentAPI.getPaymentMethods(userId);
    paymentMethods.value = methods;

    // Find default method
    final defaultMethod = methods.firstWhereOrNull(
      (method) => method.isDefault,
    );
    defaultPaymentMethod.value = defaultMethod;
  }

  /// Load bank account
  Future<void> _loadBankAccount() async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      showError('User not authenticated');
      return;
    }

    final account = await _paymentAPI.getBankAccount(userId);
    bankAccount.value = account;

    if (account != null) {
      // Update controllers
      accountNameController.text = account.accountName;
      accountNumberController.text = account.accountNumber;
      routingNumberController.text = account.routingNumber;
      bankNameController.text = account.bankName;
    }
  }

  /// Update pricing settings
  Future<void> updatePricingSettings() {
    if (!pricingFormKey.currentState!.validate()) {
      showError('Please correct the errors in the form');
      return Future.value();
    }

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Parse values
      final baseHourlyRate = double.tryParse(hourlyRateController.text) ?? 0;
      final minimumServiceFee = double.tryParse(minimumFeeController.text) ?? 0;
      final cancellationFee =
          double.tryParse(cancellationFeeController.text) ?? 0;
      final emergencyRate = double.tryParse(emergencyRateController.text) ?? 0;
      final weekendRate = double.tryParse(weekendRateController.text) ?? 0;

      // Create updated settings
      final updatedSettings = provider_models.PricingSettings(
        baseHourlyRate: baseHourlyRate,
        minimumServiceFee: minimumServiceFee,
        cancellationFee: cancellationFee,
        emergencyRate: emergencyRate,
        weekendRate: weekendRate,
      );

      // Update in database
      await _userAPI.updateProviderPricingSettings(userId, updatedSettings);

      // Update local state
      pricingSettings.value = updatedSettings;

      showSuccess('Pricing settings updated successfully');
    });
  }

  /// Add/update bank account
  Future<void> saveBankAccount() {
    if (!bankAccountFormKey.currentState!.validate()) {
      showError('Please correct the errors in the form');
      return Future.value();
    }

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Create bank account
      final account = provider_models.BankAccount(
        id:
            bankAccount.value?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        accountName: accountNameController.text,
        accountNumber: accountNumberController.text,
        routingNumber: routingNumberController.text,
        bankName: bankNameController.text,
        createdAt: bankAccount.value?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update in database
      await _paymentAPI.saveBankAccount(userId, account);

      // Update local state
      bankAccount.value = account;

      showSuccess('Bank account saved successfully');
    });
  }

  /// Add payment method (redirect to payment processor)
  Future<void> addPaymentMethod() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // For our mock, we'll just create a fake payment method

      final method = payment_models.PaymentMethod(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: payment_models.PaymentMethodType.creditCard,
        brand: 'Visa',
        holderName: 'John Doe',
        last4: '4242',
        expiryMonth: '12',
        expiryYear: '2025',
        isDefault: paymentMethods.isEmpty,
        provider: 'Visa',
        createdAt: DateTime.now(),
      );

      // Save in database
      await _paymentAPI.addPaymentMethod(userId, method);

      // Update local state
      if (method.isDefault) {
        defaultPaymentMethod.value = method;
      }

      paymentMethods.add(method);

      showSuccess('Payment method added successfully');
    });
  }

  /// Set default payment method
  Future<void> setDefaultPaymentMethod(String methodId) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      await _paymentAPI.setDefaultPaymentMethod(userId, methodId);

      // Update local state
      final updatedMethods =
          paymentMethods.map((method) {
            if (method.id == methodId) {
              return method.copyWith(isDefault: true);
            } else if (method.isDefault) {
              return method.copyWith(isDefault: false);
            }
            return method;
          }).toList();

      paymentMethods.value = updatedMethods;
      defaultPaymentMethod.value = updatedMethods.firstWhereOrNull(
        (m) => m.id == methodId,
      );

      showSuccess('Default payment method updated');
    });
  }

  /// Remove payment method
  Future<void> removePaymentMethod(String methodId) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Check if it's the default method
      final method = paymentMethods.firstWhereOrNull((m) => m.id == methodId);
      if (method != null && method.isDefault && paymentMethods.length > 1) {
        showError(
          'Cannot remove default payment method. Set another method as default first.',
        );
        return;
      }

      await _paymentAPI.removePaymentMethod(userId, methodId);

      // Update local state
      paymentMethods.removeWhere((m) => m.id == methodId);

      // If we removed the default method, update defaultPaymentMethod
      if (defaultPaymentMethod.value?.id == methodId) {
        defaultPaymentMethod.value = null;
      }

      showSuccess('Payment method removed');
    });
  }

  /// Format payment method display text
  String formatPaymentMethod(payment_models.PaymentMethod method) {
    switch (method.type) {
      case payment_models.PaymentMethodType.creditCard:
        return '${method.provider} ****${method.last4} (expires ${method.expiryMonth}/${method.expiryYear})';
      case payment_models.PaymentMethodType.bankAccount:
        return 'Bank Account (${method.bankName}) ****${method.last4}';
      case payment_models.PaymentMethodType.paypal:
        return 'PayPal (${method.email})';
      default:
        return 'Unknown payment method';
    }
  }

  /// Format currency
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Calculate hourly rate with surge pricing
  double calculateHourlyRate({
    bool isEmergency = false,
    bool isWeekend = false,
  }) {
    double rate = pricingSettings.value.baseHourlyRate;

    if (isEmergency) {
      rate += pricingSettings.value.emergencyRate;
    }

    if (isWeekend) {
      rate += pricingSettings.value.weekendRate;
    }

    return rate;
  }

  /// Validate numeric input
  String? validateNumericInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number < 0) {
      return 'Please enter a positive number';
    }

    return null;
  }

  /// Mask account number
  String maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;

    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '****$lastFour';
  }
}
