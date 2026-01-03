import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../services/storage_services.dart';
import '../../models/user_models.dart';
import '../../routes.dart';

class ProviderProfileSettingsScreen extends StatefulWidget {
  const ProviderProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProviderProfileSettingsScreen> createState() =>
      _ProviderProfileSettingsScreenState();
}

class _ProviderProfileSettingsScreenState
    extends State<ProviderProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserAPI _userAPI = UserAPI();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  ServiceProvider? _profile;
  String? _profileImageUrl;
  List<String> _certificates = [];

  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _userAPI.getProviderProfile(user.uid);
        if (profile != null) {
          setState(() {
            _profile = profile;
            _profileImageUrl = profile.profileImage;
            _businessNameController.text = profile.businessName;
            _descriptionController.text = profile.description;
            _phoneController.text = profile.phone;
            _addressController.text = profile.businessAddress;
            _websiteController.text = profile.website ?? '';
            _certificates = List.from(profile.certificates);
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null && _profile != null) {
        final updatedProfile = _profile!.copyWith(
          businessName: _businessNameController.text,
          description: _descriptionController.text,
          phone: _phoneController.text,
          businessAddress: _addressController.text,
          website: _websiteController.text,
          certificates: _certificates,
          profileImage: _profileImageUrl,
        );

        await _userAPI.updateProviderProfile(updatedProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error updating profile')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final url = await _storageService.uploadProfileImage(user.uid, image);
        setState(() => _profileImageUrl = url);
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error uploading image')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile image
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  _profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : null,
                              child:
                                  _profileImageUrl == null
                                      ? const Icon(Icons.person, size: 50)
                                      : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt),
                                  color: Colors.white,
                                  onPressed: _pickProfileImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

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
                            return 'Please enter your business description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
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
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Website (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
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
                      const SizedBox(height: 24),

                      // Additional settings
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Availability Settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.availabilitySettings,
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.payment),
                        title: const Text('Payment Settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.paymentSettings,
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notification Settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.notificationSettings,
                          );
                        },
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
