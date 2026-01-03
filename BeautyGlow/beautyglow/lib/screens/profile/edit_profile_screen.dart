import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';
import '../../data/storage_service.dart';
import '../../models/beauty_data.dart';
import '../../models/user_profile.dart';
import '../../utils/validation_util.dart';

class EditProfileScreen extends StatefulWidget {
  final BeautyData userData;

  const EditProfileScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final StorageService _storageService = StorageService();

  String _selectedSkinType = 'normal';
  List<String> _selectedConcerns = [];
  String _selectedRoutineTime = 'both';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final profile = widget.userData.userProfile;
    _nameController.text = profile.name;
    _selectedSkinType = profile.skinType;
    _selectedConcerns = List.from(profile.skinConcerns);
    _selectedRoutineTime = profile.preferredRoutineTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated profile
      final updatedProfile = widget.userData.userProfile.copyWith(
        name: _nameController.text.trim(),
        skinType: _selectedSkinType,
        skinConcerns: _selectedConcerns,
        preferredRoutineTime: _selectedRoutineTime,
      );

      // Update user data
      final updatedUserData = widget.userData.copyWith(
        userProfile: updatedProfile,
      );

      // Save to storage
      await _storageService.saveUserData(updatedUserData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryPink,
                      ),
                    ),
                  )
                : Text(
                    'Save',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            ResponsiveUtil.instance
                .proportionateWidth(AppDimensions.paddingLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.userData.userProfile.initials,
                          style: AppTypography.headingLarge.copyWith(
                            color: AppColors.primaryPink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().scale(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                        ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(32)),

              // Name Field
              Text(
                'Basic Information',
                style: AppTypography.headingSmall,
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

              TextFormField(
                controller: _nameController,
                validator: ValidationUtil.validateName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Skin Type Selection
              Text(
                'Skin Profile',
                style: AppTypography.headingSmall,
              ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

              Text(
                'What\'s your skin type?',
                style: AppTypography.labelLarge,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),
              DropdownButtonFormField<String>(
                value: _selectedSkinType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.face_outlined),
                ),
                items: [
                  'Normal',
                  'Dry',
                  'Oily',
                  'Combination',
                  'Sensitive',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value.toLowerCase(),
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSkinType = newValue ?? 'normal';
                  });
                },
              ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Skin Concerns
              Text(
                'What are your skin concerns?',
                style: AppTypography.labelLarge,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Acne',
                  'Aging',
                  'Dark Spots',
                  'Dryness',
                  'Dullness',
                  'Fine Lines',
                  'Pores',
                  'Redness',
                  'Sensitivity',
                  'Uneven Texture',
                ].map((concern) {
                  final isSelected =
                      _selectedConcerns.contains(concern.toLowerCase());
                  return FilterChip(
                    label: Text(concern),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedConcerns.add(concern.toLowerCase());
                        } else {
                          _selectedConcerns.remove(concern.toLowerCase());
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primaryPink.withOpacity(0.1),
                    checkmarkColor: AppColors.primaryPink,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryPink
                          : AppColors.textPrimary,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryPink
                          : AppColors.dividerGray,
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: const Duration(milliseconds: 500)),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Preferred Routine Time
              Text(
                'Routine Preferences',
                style: AppTypography.headingSmall,
              ).animate().fadeIn(delay: const Duration(milliseconds: 600)),

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

              Text(
                'When do you prefer to do your routine?',
                style: AppTypography.labelLarge,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeOption(
                      value: 'morning',
                      label: 'Morning',
                      icon: Icons.wb_sunny_outlined,
                    ),
                  ),
                  SizedBox(
                      width: ResponsiveUtil.instance.proportionateWidth(12)),
                  Expanded(
                    child: _buildTimeOption(
                      value: 'evening',
                      label: 'Evening',
                      icon: Icons.nights_stay_outlined,
                    ),
                  ),
                  SizedBox(
                      width: ResponsiveUtil.instance.proportionateWidth(12)),
                  Expanded(
                    child: _buildTimeOption(
                      value: 'both',
                      label: 'Both',
                      icon: Icons.autorenew_rounded,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRoutineTime == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRoutineTime = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(
          ResponsiveUtil.instance.proportionateWidth(12),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : AppColors.dividerGray,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primaryPink,
              size: 24,
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(4)),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
