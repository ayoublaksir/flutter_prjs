import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/credit_models.dart';

class ReceiptScreen extends StatefulWidget {
  final String transactionId;
  final int credits;
  final double amount;
  final DateTime date;

  const ReceiptScreen({
    Key? key,
    required this.transactionId,
    required this.credits,
    required this.amount,
    required this.date,
  }) : super(key: key);

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final UserAPI _userAPI = UserAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isDownloading = false;

  String _providerName = '';
  String _providerEmail = '';
  String _providerBusinessName = '';

  @override
  void initState() {
    super.initState();
    _loadProviderDetails();
  }

  Future<void> _loadProviderDetails() async {
    setState(() => _isLoading = true);

    try {
      final providerId = _authService.currentUser?.uid;
      if (providerId == null) {
        throw Exception('User not authenticated');
      }

      final provider = await _userAPI.getProviderProfile(providerId);
      if (provider != null) {
        setState(() {
          _providerName = provider.name;
          _providerEmail = provider.email;
          _providerBusinessName =
              provider.businessName ?? 'Independent Provider';
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load provider details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadReceipt() async {
    setState(() => _isDownloading = true);

    try {
      // In a real implementation, you would:
      // 1. Generate a PDF using a library like pdf or flutter_html_to_pdf
      // 2. Save it to local storage
      // 3. Allow the user to share or open the file

      // For this example, we'll just simulate downloading and open the share dialog
      await Future.delayed(const Duration(seconds: 1));

      // For demonstration purposes, create a temporary file
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/receipt_${widget.transactionId}.txt',
      );

      // Write receipt content
      await file.writeAsString(_generateReceiptText());

      // Share the file
      await Share.shareFiles(
        [file.path],
        text: 'Your FixItNow credit purchase receipt',
        subject: 'Credit Purchase Receipt - ${widget.transactionId}',
      );

      Get.snackbar('Success', 'Receipt downloaded and shared');
    } catch (e) {
      Get.snackbar('Error', 'Failed to download receipt: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  String _generateReceiptText() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return '''
RECEIPT
FixItNow Credit Purchase

Transaction ID: ${widget.transactionId}
Date: ${dateFormat.format(widget.date)}
Time: ${timeFormat.format(widget.date)}

Provider: $_providerName
Business: $_providerBusinessName
Email: $_providerEmail

Credits Purchased: ${widget.credits}
Amount: ${currencyFormat.format(widget.amount)}

Thank you for your purchase!
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receipt')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isDownloading ? null : _downloadReceipt,
            tooltip: 'Share Receipt',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Receipt header
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'RECEIPT',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transaction ID: ${widget.transactionId}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${dateFormat.format(widget.date)} at ${timeFormat.format(widget.date)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 32),

                  // Provider details
                  const Text(
                    'Provider Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Name', _providerName),
                  _buildDetailRow('Business', _providerBusinessName),
                  _buildDetailRow('Email', _providerEmail),

                  const Divider(height: 32),

                  // Purchase details
                  const Text(
                    'Purchase Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Item', 'Credit Bundle'),
                  _buildDetailRow('Credits', widget.credits.toString()),

                  const Divider(height: 32),

                  // Payment details
                  const Text(
                    'Payment Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Payment Method', 'Credit Card'),
                  _buildDetailRow(
                    'Amount',
                    currencyFormat.format(widget.amount),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        currencyFormat.format(widget.amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Footer
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'Thank You For Your Purchase!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your credits have been added to your account.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'For support, contact support@fixitnow.app',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Download button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadReceipt,
                icon: const Icon(Icons.download),
                label:
                    _isDownloading
                        ? const Text('Downloading...')
                        : const Text('Download Receipt'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
