import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../models/gender.dart';

class MultiStepSignupScreen extends StatefulWidget {
  @override
  _MultiStepSignupScreenState createState() => _MultiStepSignupScreenState();
}

class _MultiStepSignupScreenState extends State<MultiStepSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Current step
  int _currentStep = 0;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _educationController = TextEditingController();

  // Selected gender
  Gender _selectedGender = Gender.male;

  // Selected interests
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
  ];

  // Loading state
  bool _isLoading = false;
  bool _isGettingLocation = false;

  // Location data
  GeoPoint? _location;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _cityController.text =
              place.locality ?? place.subAdministrativeArea ?? '';
          _location = GeoPoint(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Parse age
      int? age = int.tryParse(_ageController.text);
      if (age == null) {
        throw Exception('Please enter a valid age');
      }

      // Create user with additional profile data
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        userData: {
          'name': _nameController.text,
          'age': age,
          'gender': _selectedGender.toString().split('.').last,
          'city': _cityController.text,
          'bio': _bioController.text,
          'jobTitle': _jobTitleController.text,
          'company': _companyController.text,
          'education': _educationController.text,
          'location': _location,
          'interests': _selectedInterests,
          'createdAt': FieldValue.serverTimestamp(),
          'isVerified': false,
        },
      );

      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('Error signing up: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing up: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAccountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create your account',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 24),

        // Name field
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name*',
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

        // Email field
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email*',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Password field
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password*',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Confirm password field
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm Password*',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about yourself',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 24),

        // Age field (required)
        TextFormField(
          controller: _ageController,
          decoration: InputDecoration(
            labelText: 'Age*',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.cake),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your age';
            }
            int? age = int.tryParse(value);
            if (age == null || age < 18 || age > 120) {
              return 'Please enter a valid age (18-120)';
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Gender selection
        Text(
          'Gender*',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<Gender>(
                title: Text('Male'),
                value: Gender.male,
                groupValue: _selectedGender,
                onChanged: (Gender? value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),
            ),
            Expanded(
              child: RadioListTile<Gender>(
                title: Text('Female'),
                value: Gender.female,
                groupValue: _selectedGender,
                onChanged: (Gender? value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Location field with auto-detect
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isGettingLocation ? null : _getCurrentLocation,
              icon:
                  _isGettingLocation
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(Icons.my_location),
              label: Text('Detect'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Bio field (optional)
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            labelText: 'Bio (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Tell us a bit about yourself...',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional Information',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'All fields are optional',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 24),

        // Job title field
        TextFormField(
          controller: _jobTitleController,
          decoration: InputDecoration(
            labelText: 'Job Title (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
        ),
        SizedBox(height: 16),

        // Company field
        TextFormField(
          controller: _companyController,
          decoration: InputDecoration(
            labelText: 'Company (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
        ),
        SizedBox(height: 16),

        // Education field
        TextFormField(
          controller: _educationController,
          decoration: InputDecoration(
            labelText: 'Education (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Interests',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Select interests that define you',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 24),

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
                            : Colors.black,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which step content to show based on _currentStep
    Widget stepContent;
    switch (_currentStep) {
      case 0:
        stepContent = _buildAccountStep();
        break;
      case 1:
        stepContent = _buildPersonalInfoStep();
        break;
      case 2:
        stepContent = _buildProfessionalInfoStep();
        break;
      case 3:
        stepContent = _buildInterestsStep();
        break;
      default:
        stepContent = _buildAccountStep();
    }

    return Scaffold(
      appBar: AppBar(title: Text('Create Account'), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step indicator
                Row(
                  children: [
                    for (int i = 0; i < 4; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          color:
                              i <= _currentStep
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 24),

                // Step content
                stepContent,
                SizedBox(height: 32),

                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStep--;
                          });
                        },
                        child: Text('Back'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      )
                    else
                      SizedBox(), // Empty space if on first step

                    ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                if (_currentStep < 3) {
                                  // Validate current step before proceeding
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _currentStep++;
                                    });
                                  }
                                } else {
                                  // On last step, submit the form
                                  _signUp();
                                }
                              },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  _currentStep < 3 ? 'Next' : 'Create Account',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                // Login link
                if (_currentStep == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?'),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text('Log In'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
