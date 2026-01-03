import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/support_models.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final SupportAPI _supportAPI = SupportAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  List<FAQCategory> _faqCategories = [];
  List<SupportTicket> _activeTickets = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final results = await Future.wait([
          _supportAPI.getFAQCategories(),
          _supportAPI.getUserTickets(user.uid),
        ]);

        setState(() {
          _faqCategories = results[0] as List<FAQCategory>;
          _activeTickets = results[1] as List<SupportTicket>;
        });
      }
    } catch (e) {
      print('Error loading support data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading support data')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createSupportTicket() async {
    final result = await showDialog<SupportTicket>(
      context: context,
      builder: (context) => const CreateTicketDialog(),
    );

    if (result != null) {
      setState(() => _activeTickets.insert(0, result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search FAQs...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.contact_support,
                            title: 'Contact Support',
                            onTap: _createSupportTicket,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.chat,
                            title: 'Live Chat',
                            onTap: () {
                              // Implement live chat
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // FAQ Categories
                    Text(
                      'FAQ Categories',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _faqCategories.length,
                      itemBuilder: (context, index) {
                        final category = _faqCategories[index];
                        return ExpansionTile(
                          leading: Icon(category.icon),
                          title: Text(category.name),
                          children:
                              category.faqs.map((faq) {
                                return ExpansionTile(
                                  title: Text(faq.question),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(faq.answer),
                                    ),
                                  ],
                                );
                              }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Active Support Tickets
                    if (_activeTickets.isNotEmpty) ...[
                      Text(
                        'Active Support Tickets',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activeTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = _activeTickets[index];
                          return Card(
                            child: ListTile(
                              title: Text('#${ticket.id} - ${ticket.subject}'),
                              subtitle: Text(
                                'Status: ${ticket.status.capitalize()}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // Navigate to ticket details
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSupportTicket,
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateTicketDialog extends StatefulWidget {
  const CreateTicketDialog({Key? key}) : super(key: key);

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'General';

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Support Ticket'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items:
                  ['General', 'Technical', 'Billing', 'Other']
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a subject';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
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
              Navigator.pop(
                context,
                SupportTicket(
                  id: DateTime.now().toString(),
                  subject: _subjectController.text,
                  description: _descriptionController.text,
                  category: _selectedCategory,
                  status: 'open',
                  createdAt: DateTime.now(),
                ),
              );
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
