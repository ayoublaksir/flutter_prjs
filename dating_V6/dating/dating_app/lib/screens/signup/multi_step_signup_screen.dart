import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/screens/main_navigation_screen.dart';
import 'dart:ui';

class MultiStepSignupScreen extends StatefulWidget {
  const MultiStepSignupScreen({Key? key}) : super(key: key);

  @override
  State<MultiStepSignupScreen> createState() => _MultiStepSignupScreenState();
}

class _MultiStepSignupScreenState extends State<MultiStepSignupScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentPage = 0;
  bool _isLoading = false;

  // User data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'Male';
  List<String> _interests = [];
  List<String> _preferredDateMoods = [];
  List<String> _preferredDateCategories = [];
  List<File> _selectedImages = [];

  // Available options
  final List<String> _availableInterests = [
    'Movies',
    'Music',
    'Sports',
    'Travel',
    'Food',
    'Art',
    'Reading',
    'Photography',
    'Dancing',
    'Hiking',
    'Gaming',
    'Cooking',
  ];

  final List<String> _availableDateMoods = [
    'Romantic',
    'Casual',
    'Adventurous',
    'Relaxed',
    'Intellectual',
    'Fun',
  ];

  final List<String> _availableDateCategories = [
    'Dinner',
    'Coffee',
    'Drinks',
    'Outdoor Activity',
    'Movie',
    'Concert',
    'Museum',
    'Park',
    'Beach',
    'Sports Event',
    'Cooking Class',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          if (_selectedImages.length < 6) {
            // Limit to 6 images total
            _selectedImages.add(File(image.path));
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ?? DateTime.now().subtract(Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _animationController.reset();
      _pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _animationController.forward();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _animationController.reset();
      _pageController.previousPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _animationController.forward();
    }
  }

  bool _validateAllSteps() {
    // Validate basic info
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _birthDate == null) {
      return false;
    }

    // Validate photos
    if (_selectedImages.isEmpty) {
      return false;
    }

    // Validate interests
    if (_interests.isEmpty) {
      return false;
    }

    // Validate date moods
    if (_preferredDateMoods.isEmpty) {
      return false;
    }

    // Validate date categories
    if (_preferredDateCategories.isEmpty) {
      return false;
    }

    return true;
  }

  Future<void> _submitRegistration() async {
    if (_formKey.currentState!.validate() && _validateAllSteps()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        await authService.registerWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
          _birthDate!,
          _gender,
          _bioController.text,
          _interests,
          _preferredDateMoods,
          _preferredDateCategories,
          _selectedImages,
        );

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header with progress indicator
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: _previousPage,
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / 5,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                // Page content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: NeverScrollableScrollPhysics(),
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        FadeTransition(
                          opacity: _animation,
                          child: _buildBasicInfoPage(),
                        ),
                        FadeTransition(
                          opacity: _animation,
                          child: _buildPhotosPage(),
                        ),
                        FadeTransition(
                          opacity: _animation,
                          child: _buildInterestsPage(),
                        ),
                        FadeTransition(
                          opacity: _animation,
                          child: _buildDateMoodsPage(),
                        ),
                        FadeTransition(
                          opacity: _animation,
                          child: _buildDateCategoriesPage(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom navigation
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                if (_currentPage == 4) {
                                  _submitRegistration();
                                } else {
                                  _nextPage();
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                _currentPage == 4 ? 'Create Account' : 'Next',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentPage) {
      case 0:
        return 'Tell us about yourself';
      case 1:
        return 'Add your photos';
      case 2:
        return 'What are your interests?';
      case 3:
        return 'What date moods do you prefer?';
      case 4:
        return 'What date activities do you enjoy?';
      default:
        return '';
    }
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 24),
          _buildInputField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildInputField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildInputField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock,
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
          _buildDateField(),
          SizedBox(height: 16),
          _buildGenderSelection(),
          SizedBox(height: 16),
          _buildInputField(
            controller: _bioController,
            label: 'Bio (Optional)',
            icon: Icons.edit_note,
            maxLines: 3,
            hint: 'Tell potential matches about yourself...',
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add your best photos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your first photo will be your profile picture',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          // Photo grid
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount:
                _selectedImages.length + (_selectedImages.length < 6 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                // Add photo button
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40,
                    ),
                  ),
                );
              } else {
                // Photo preview
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
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
                    if (index == 0)
                      Positioned(
                        bottom: 5,
                        left: 5,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Main',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
            },
          ),

          SizedBox(height: 24),

          // Add multiple photos button
          if (_selectedImages.length < 6)
            Center(
              child: OutlinedButton.icon(
                onPressed: _pickMultipleImages,
                icon: Icon(Icons.photo_library),
                label: Text('Add Multiple Photos'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

          SizedBox(height: 16),

          if (_selectedImages.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please add at least one photo to continue',
                      style: TextStyle(color: Colors.amber[800]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your interests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Choose at least 3 interests to help us find better matches for you',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          // Interests chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                _availableInterests.map((interest) {
                  final selected = _interests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _interests.add(interest);
                        } else {
                          _interests.remove(interest);
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
                          selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color:
                            selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
          ),

          SizedBox(height: 16),

          if (_interests.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please select at least one interest to continue',
                      style: TextStyle(color: Colors.amber[800]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateMoodsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What kind of dates do you prefer?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select the moods that match your dating style',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          // Date mood cards
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: _availableDateMoods.length,
            itemBuilder: (context, index) {
              final mood = _availableDateMoods[index];
              final selected = _preferredDateMoods.contains(mood);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _preferredDateMoods.remove(mood);
                    } else {
                      _preferredDateMoods.add(mood);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow:
                        selected
                            ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ]
                            : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getMoodIcon(mood),
                              size: 32,
                              color:
                                  selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[600],
                            ),
                            SizedBox(height: 8),
                            Text(
                              mood,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    selected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 16),

          if (_preferredDateMoods.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please select at least one date mood to continue',
                      style: TextStyle(color: Colors.amber[800]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateCategoriesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What activities do you enjoy?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select the types of date activities you prefer',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          // Date categories
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                _availableDateCategories.map((category) {
                  final selected = _preferredDateCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _preferredDateCategories.add(category);
                        } else {
                          _preferredDateCategories.remove(category);
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
                          selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color:
                            selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
          ),

          SizedBox(height: 16),

          if (_preferredDateCategories.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please select at least one date category to continue',
                      style: TextStyle(color: Colors.amber[800]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8.0),
            child: Text(
              'Gender',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Male'),
                  value: 'Male',
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Female'),
                  value: 'Female',
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Birth Date',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          child: Text(
            _birthDate == null
                ? 'Select your birth date'
                : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
            style: TextStyle(
              color: _birthDate == null ? Colors.grey.shade600 : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'romantic':
        return Icons.favorite;
      case 'casual':
        return Icons.coffee;
      case 'adventurous':
        return Icons.hiking;
      case 'relaxed':
        return Icons.spa;
      case 'intellectual':
        return Icons.psychology;
      case 'fun':
        return Icons.celebration;
      default:
        return Icons.mood;
    }
  }
}
