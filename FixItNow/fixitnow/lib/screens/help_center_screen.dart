import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/support_models.dart';
import '../services/api_services.dart';
import '../services/auth_services.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final SupportAPI _supportAPI = SupportAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  List<FaqCategory> _faqCategories = [];
  List<FaqItem> _popularFaqs = [];

  final TextEditingController _searchController = TextEditingController();
  List<FaqItem> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadHelpCenterData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHelpCenterData() async {
    setState(() => _isLoading = true);

    try {
      // Load FAQ categories and popular questions
      final categories = await _supportAPI.getFaqCategories();
      final popularFaqs = await _supportAPI.getPopularFaqs();

      setState(() {
        _faqCategories = categories;
        _popularFaqs = popularFaqs;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load help center data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _searchFaqs(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final allFaqs = <FaqItem>[];
    for (final category in _faqCategories) {
      allFaqs.addAll(category.faqs);
    }

    final results =
        allFaqs.where((faq) {
          return faq.question.toLowerCase().contains(query.toLowerCase()) ||
              faq.answer.toLowerCase().contains(query.toLowerCase());
        }).toList();

    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  Future<void> _contactSupport() async {
    final email = 'support@fixitnow.app';
    final subject = 'Support Request';
    final body = 'Hello, I need assistance with...';

    final url =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar('Error', 'Could not launch email app');
    }
  }

  Future<void> _startChat() async {
    // Navigate to chat screen or launch chat support
    Get.snackbar('Chat Support', 'Live chat support will be available soon!');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Help Center')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for help',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchFaqs('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchFaqs,
            ),
          ),

          // Support contact options
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _contactSupport,
                      icon: const Icon(Icons.email),
                      label: const Text('Email Support'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _startChat,
                      icon: const Icon(Icons.chat),
                      label: const Text('Live Chat'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // FAQ content
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildFaqCategories(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try different keywords or contact support',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _contactSupport,
              icon: const Icon(Icons.email),
              label: const Text('Contact Support'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final faq = _searchResults[index];
        return _buildFaqItem(faq);
      },
    );
  }

  Widget _buildFaqCategories() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular questions
          if (_popularFaqs.isNotEmpty) ...[
            Text(
              'Popular Questions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Column(
              children: _popularFaqs.map((faq) => _buildFaqItem(faq)).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Categories
          Text(
            'Help Categories',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Column(
            children:
                _faqCategories.map((category) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      leading: Icon(
                        _getCategoryIcon(category.name),
                        color: Theme.of(context).primaryColor,
                      ),
                      children: [
                        ...category.faqs
                            .map((faq) => _buildFaqItem(faq))
                            .toList(),
                      ],
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 24),

          // Additional help resources
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Resources',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.video_library, size: 32),
                          SizedBox(height: 8),
                          Text('Tutorial Videos'),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.article, size: 32),
                          SizedBox(height: 8),
                          Text('User Guide'),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.phone, size: 32),
                          SizedBox(height: 8),
                          Text('Call Center'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(FaqItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(faq.question),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(faq.answer, style: const TextStyle(fontSize: 16)),
                if (faq.links.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...faq.links.map((link) {
                    return TextButton.icon(
                      icon: const Icon(Icons.link),
                      label: Text(link.title),
                      onPressed: () async {
                        if (await canLaunch(link.url)) {
                          await launch(link.url);
                        }
                      },
                    );
                  }).toList(),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Was this helpful?'),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.thumb_up),
                      label: const Text('Yes'),
                      onPressed: () {
                        Get.snackbar(
                          'Thank You',
                          'We\'re glad this was helpful!',
                        );
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.thumb_down),
                      label: const Text('No'),
                      onPressed: () {
                        _contactSupport();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'account':
        return Icons.account_circle;
      case 'bookings':
        return Icons.calendar_today;
      case 'payments':
        return Icons.payment;
      case 'services':
        return Icons.home_repair_service;
      case 'provider':
        return Icons.business;
      case 'technical':
        return Icons.desktop_windows;
      default:
        return Icons.help;
    }
  }
}

// Mock implementation until SupportAPI is fully implemented
class SupportAPI {
  Future<List<FaqCategory>> getFaqCategories() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      FaqCategory(
        id: '1',
        name: 'Account',
        faqs: [
          FaqItem(
            id: '101',
            question: 'How do I create an account?',
            answer:
                'To create an account, tap the "Sign Up" button on the welcome screen and follow the instructions. You\'ll need to provide your email, create a password, and verify your phone number.',
            links: [
              FaqLink(
                title: 'Sign Up Process',
                url: 'https://fixitnow.app/signup-guide',
              ),
            ],
          ),
          FaqItem(
            id: '102',
            question: 'How do I reset my password?',
            answer:
                'To reset your password, tap "Forgot Password" on the login screen. Enter your email address, and we\'ll send you a link to create a new password.',
            links: [],
          ),
        ],
      ),
      FaqCategory(
        id: '2',
        name: 'Bookings',
        faqs: [
          FaqItem(
            id: '201',
            question: 'How do I book a service?',
            answer:
                'To book a service, browse through available services or search for a specific service. Select the service you want, choose your preferred date and time, and confirm your booking details before submitting.',
            links: [
              FaqLink(
                title: 'Booking Guide',
                url: 'https://fixitnow.app/booking-guide',
              ),
            ],
          ),
          FaqItem(
            id: '202',
            question: 'How do I cancel a booking?',
            answer:
                'To cancel a booking, go to your Booking History, select the booking you want to cancel, and tap the "Cancel Booking" button. Please note that cancellation policies may apply depending on how close the cancellation is to the scheduled service time.',
            links: [],
          ),
        ],
      ),
      FaqCategory(
        id: '3',
        name: 'Payments',
        faqs: [
          FaqItem(
            id: '301',
            question: 'What payment methods are accepted?',
            answer:
                'We accept major credit and debit cards, including Visa, MasterCard, and American Express. In some regions, we also support digital wallets such as Apple Pay and Google Pay.',
            links: [],
          ),
          FaqItem(
            id: '302',
            question: 'How do refunds work?',
            answer:
                'If you cancel a booking before the service provider is en route, you will receive a full refund. For cancellations after the provider has started traveling to your location, a partial refund may apply. If you\'re unsatisfied with a completed service, please contact our support team to discuss refund options.',
            links: [
              FaqLink(
                title: 'Refund Policy',
                url: 'https://fixitnow.app/refund-policy',
              ),
            ],
          ),
        ],
      ),
      FaqCategory(
        id: '4',
        name: 'Provider',
        faqs: [
          FaqItem(
            id: '401',
            question: 'How do I become a service provider?',
            answer:
                'To become a service provider, sign up and select the "Service Provider" role. You\'ll need to complete your profile, select your service categories, set your pricing, and undergo our verification process before you can start accepting bookings.',
            links: [
              FaqLink(
                title: 'Provider Guidelines',
                url: 'https://fixitnow.app/provider-guidelines',
              ),
            ],
          ),
          FaqItem(
            id: '402',
            question: 'How does the credit system work for providers?',
            answer:
                'As a provider, you\'ll need credits to interact with customer requests. Credits are used when you make offers or respond to service requests. You only pay credits when your offer is accepted, ensuring you only invest in real opportunities.',
            links: [
              FaqLink(
                title: 'Credit System Explained',
                url: 'https://fixitnow.app/credit-system',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  Future<List<FaqItem>> getPopularFaqs() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      FaqItem(
        id: '101',
        question: 'How do I create an account?',
        answer:
            'To create an account, tap the "Sign Up" button on the welcome screen and follow the instructions. You\'ll need to provide your email, create a password, and verify your phone number.',
        links: [],
      ),
      FaqItem(
        id: '201',
        question: 'How do I book a service?',
        answer:
            'To book a service, browse through available services or search for a specific service. Select the service you want, choose your preferred date and time, and confirm your booking details before submitting.',
        links: [],
      ),
      FaqItem(
        id: '402',
        question: 'How does the credit system work for providers?',
        answer:
            'As a provider, you\'ll need credits to interact with customer requests. Credits are used when you make offers or respond to service requests. You only pay credits when your offer is accepted, ensuring you only invest in real opportunities.',
        links: [],
      ),
    ];
  }
}

// Model classes for FAQs
class FaqCategory {
  final String id;
  final String name;
  final List<FaqItem> faqs;

  FaqCategory({required this.id, required this.name, required this.faqs});
}

class FaqItem {
  final String id;
  final String question;
  final String answer;
  final List<FaqLink> links;

  FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.links = const [],
  });
}

class FaqLink {
  final String title;
  final String url;

  FaqLink({required this.title, required this.url});
}
