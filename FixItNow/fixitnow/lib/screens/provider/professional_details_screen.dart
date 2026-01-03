import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/user_models.dart';
import '../../routes.dart';

class ProfessionalDetailsScreen extends StatefulWidget {
  const ProfessionalDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalDetailsScreen> createState() =>
      _ProfessionalDetailsScreenState();
}

class _ProfessionalDetailsScreenState extends State<ProfessionalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserAPI _userAPI = UserAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  List<String>? _selectedCategories;

  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _addressController = TextEditingController();

  List<String> _certificates = [];
  Map<String, dynamic> _availability = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _selectedCategories = args['selectedCategories'] as List<String>?;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfessionalDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final provider = ServiceProvider(
          role: 'provider',
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          phone: '',
          profileImage: user.photoURL ?? '',
          createdAt: DateTime.now(),
          businessName: _businessNameController.text,
          description: _descriptionController.text,
          services: _selectedCategories ?? [],
          certificates: _certificates,
          businessAddress: _addressController.text,
          workingHours: {},
          vacationDays: [],
          pricingSettings: {},
          bankDetails: {},
        );

        await _userAPI.updateProviderProfile(provider);

        if (mounted) {
          Navigator.pushNamed(context, AppRoutes.availabilitySettings);
        }
      }
    } catch (e) {
      print('Error saving professional details: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving details')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Professional Details')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Business Description',
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
              const SizedBox(height: 16),

              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your years of experience';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Business Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your business address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Certificates section
              Text(
                'Certificates & Licenses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ..._certificates.map(
                    (cert) => Chip(
                      label: Text(cert),
                      onDeleted: () {
                        setState(() {
                          _certificates.remove(cert);
                        });
                      },
                    ),
                  ),
                  ActionChip(
                    label: const Text('Add'),
                    onPressed: _addCertificate,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfessionalDetails,
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addCertificate() async {
    final textController = TextEditingController();

    final certificate = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Certificate'),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Enter certificate name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, textController.text);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );

    if (certificate != null && certificate.isNotEmpty) {
      setState(() {
        _certificates.add(certificate);
      });
    }

    textController.dispose();
  }
}
