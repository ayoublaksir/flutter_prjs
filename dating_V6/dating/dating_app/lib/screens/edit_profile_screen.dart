import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_profile.dart';
import '../models/gender.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/modern_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _educationController = TextEditingController();

  // Profile image
  File? _profileImageFile;
  List<File> _additionalImageFiles = [];
  List<String> _existingAdditionalImages = [];

  // Interests
  List<String> _selectedInterests = [];
  final List<String> _availableInterests = [
    'Travel',
    'Music',
    'Movies',
    'Reading',
    'Sports',
    'Cooking',
    'Art',
    'Photography',
    'Dancing',
    'Hiking',
    'Gaming',
    'Fitness',
    'Technology',
    'Fashion',
    'Food',
    'Pets',
    'Yoga',
    'Writing',
    'Languages',
    'Volunteering',
    'Meditation',
    'Cycling',
    'Swimming',
  ];

  // Gender
  Gender _selectedGender = Gender.male;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final userProfile = await _authService.getCurrentUserProfile();

      if (userProfile != null) {
        setState(() {
          _userProfile = userProfile;

          // Set form values
          _nameController.text = userProfile.name;
          _bioController.text = userProfile.bio ?? '';
          _ageController.text = userProfile.age?.toString() ?? '';
          _cityController.text = userProfile.city ?? '';
          _jobTitleController.text = userProfile.jobTitle ?? '';
          _companyController.text = userProfile.company ?? '';
          _educationController.text = userProfile.education ?? '';

          // Set interests
          _selectedInterests = List<String>.from(userProfile.interests);

          // Set gender
          _selectedGender = userProfile.gender;

          // Set additional images
          if (userProfile.additionalImages != null) {
            _existingAdditionalImages = List<String>.from(
              userProfile.additionalImages!,
            );
          }
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImageFile = File(image.path);
      });
    }
  }

  Future<void> _pickAdditionalImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _additionalImageFiles.add(File(image.path));
      });
    }
  }

  Future<String?> _uploadImage(File imageFile, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateLocation() async {
    try {
      setState(() => _isSaving = true);

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? '';

        setState(() {
          _cityController.text = city;
        });
      }

      setState(() => _isSaving = false);
    } catch (e) {
      print('Error updating location: $e');
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating location: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload profile image if changed
      String? profileImageUrl = _userProfile?.profileImageUrl;
      if (_profileImageFile != null) {
        final userId = _userProfile?.uid ?? '';
        profileImageUrl = await _uploadImage(
          _profileImageFile!,
          'profile_images/$userId/profile.jpg',
        );
      }

      // Upload additional images if any
      List<String> additionalImages = List.from(_existingAdditionalImages);
      for (int i = 0; i < _additionalImageFiles.length; i++) {
        final userId = _userProfile?.uid ?? '';
        final imageUrl = await _uploadImage(
          _additionalImageFiles[i],
          'profile_images/$userId/additional_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        if (imageUrl != null) {
          additionalImages.add(imageUrl);
        }
      }

      // Get location from city if needed
      GeoPoint? location = _userProfile?.location;
      if (_cityController.text != _userProfile?.city) {
        try {
          List<Location> locations = await locationFromAddress(
            _cityController.text,
          );
          if (locations.isNotEmpty) {
            location = GeoPoint(
              locations.first.latitude,
              locations.first.longitude,
            );
          }
        } catch (e) {
          print('Error getting location from address: $e');
        }
      }

      // Create updated profile
      final updatedProfile = UserProfile(
        uid: _userProfile!.uid,
        name: _nameController.text,
        email: _userProfile!.email,
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        jobTitle:
            _jobTitleController.text.isEmpty ? null : _jobTitleController.text,
        company:
            _companyController.text.isEmpty ? null : _companyController.text,
        education:
            _educationController.text.isEmpty
                ? null
                : _educationController.text,
        profileImageUrl: profileImageUrl,
        additionalImages: additionalImages,
        interests: _selectedInterests,
        location: location,
        preferences: _userProfile!.preferences,
        isVerified: _userProfile!.isVerified,
        createdAt: _userProfile!.createdAt,
      );

      // Save to Firestore
      await _userService.updateUserProfile(updatedProfile);

      setState(() => _isSaving = false);

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      print('Error saving profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Edit Profile',
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Save',
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImageSection(),
            SizedBox(height: 24),
            _buildPersonalInfoSection(),
            SizedBox(height: 24),
            _buildBioSection(),
            SizedBox(height: 24),
            _buildInterestsSection(),
            SizedBox(height: 24),
            _buildAdditionalImagesSection(),
            SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _profileImageFile != null
                          ? FileImage(_profileImageFile!)
                          : (_userProfile?.profileImageUrl != null
                                  ? NetworkImage(_userProfile!.profileImageUrl!)
                                  : null)
                              as ImageProvider?,
                  child:
                      (_profileImageFile == null &&
                              _userProfile?.profileImageUrl == null)
                          ? Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap to change profile picture',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 18 || age > 120) {
                      return 'Enter a valid age (18-120)';
                    }
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<Gender>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                items:
                    Gender.values.map((gender) {
                      return DropdownMenuItem<Gender>(
                        value: gender,
                        child: Text(gender.toString().split('.').last),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGender = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.my_location),
              onPressed: _updateLocation,
              tooltip: 'Use current location',
            ),
          ],
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _jobTitleController,
          decoration: InputDecoration(
            labelText: 'Job Title',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _companyController,
          decoration: InputDecoration(
            labelText: 'Company',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _educationController,
          decoration: InputDecoration(
            labelText: 'Education',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school),
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Me',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            labelText: 'Bio',
            border: OutlineInputBorder(),
            hintText: 'Tell others about yourself...',
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Select your interests to help find better matches',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black87,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdditionalImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Photos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Add up to 5 photos to showcase your personality',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        SizedBox(height: 16),
        Container(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Existing images
              ..._existingAdditionalImages.map((imageUrl) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _existingAdditionalImages.remove(imageUrl);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // New images
              ..._additionalImageFiles.map((file) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _additionalImageFiles.remove(file);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Add button
              if (_existingAdditionalImages.length +
                      _additionalImageFiles.length <
                  5)
                GestureDetector(
                  onTap: _pickAdditionalImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              _isSaving
                  ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text('Save Profile', style: TextStyle(fontSize: 16)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
