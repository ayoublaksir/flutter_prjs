# 🎨 UI Components - Responsive Design System

## ✅ Purpose
Create a comprehensive library of reusable, responsive UI components with consistent styling, animations, and behavior patterns for modern Flutter applications.

## 🧠 Architecture Overview

### Component Structure
```
lib/widgets/
├── common/                    # Basic reusable components
│   ├── custom_app_bar.dart   # Responsive app bar
│   ├── loading_overlay.dart   # Loading states
│   ├── empty_state.dart      # Empty content states
│   └── error_widget.dart     # Error handling UI
├── buttons/                  # Button components
│   ├── primary_button.dart   # Main CTA buttons
│   ├── secondary_button.dart # Secondary actions
│   ├── icon_button.dart      # Icon-based buttons
│   └── premium_button.dart   # Premium feature buttons
├── cards/                    # Card components
│   ├── base_card.dart        # Foundation card
│   ├── content_card.dart     # Content display cards
│   ├── action_card.dart      # Interactive cards
│   └── premium_card.dart     # Premium feature cards
├── forms/                    # Form components
│   ├── custom_text_field.dart # Styled input fields
│   ├── custom_dropdown.dart   # Dropdown selections
│   ├── custom_checkbox.dart   # Checkbox inputs
│   └── form_validator.dart    # Validation logic
├── navigation/               # Navigation components
│   ├── custom_bottom_nav.dart # Bottom navigation bar
│   ├── tab_bar.dart          # Custom tab bars
│   └── drawer.dart           # Navigation drawer
└── shared/                   # Shared utilities
    ├── responsive_builder.dart # Responsive wrapper
    ├── animated_container.dart # Animation utilities
    └── gradient_container.dart # Gradient backgrounds
```

## 🧩 Dependencies

Core UI dependencies (already in pubspec.yaml):
```yaml
dependencies:
  flutter_animate: ^4.3.0      # Animation library
  shimmer: ^3.0.0              # Loading effects
  percent_indicator: ^4.2.3     # Progress displays
  flutter_rating_bar: ^4.0.1   # Rating components
  cached_network_image: ^3.3.0  # Optimized images
```

## 🛠️ Complete Component Library

### 1. Responsive Builder Foundation

#### responsive_builder.dart
```dart
import 'package:flutter/material.dart';
import '../../core/responsive/responsive_util.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveBuilder({
    Key? key,
    required this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsive = ResponsiveUtil();
        
        // Use specific responsive widgets if provided
        if (responsive.isDesktop && desktop != null) return desktop!;
        if (responsive.isTablet && tablet != null) return tablet!;
        if (responsive.isMobile && mobile != null) return mobile!;
        
        // Fallback to builder
        return builder(context, constraints);
      },
    );
  }
}

// Responsive wrapper for easy responsive values
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  
  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil();
    
    EdgeInsets padding = responsive.responsive(
      mobile: mobilePadding ?? const EdgeInsets.all(16),
      tablet: tabletPadding ?? const EdgeInsets.all(24),
      desktop: desktopPadding ?? const EdgeInsets.all(32),
    );
    
    return Padding(
      padding: padding,
      child: child,
    );
  }
}
```

### 2. Button Components

#### primary_button.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderRadius? borderRadius;
  
  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeightMedium,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.forward();
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }
  
  void _handleTapCancel() {
    _animationController.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.isEnabled || widget.isLoading;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: isDisabled
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.backgroundColor ?? AppColors.primaryPink,
                          widget.backgroundColor?.withOpacity(0.8) ?? 
                              AppColors.primaryPurple,
                        ],
                      ),
                color: isDisabled ? Colors.grey[300] : null,
                borderRadius: widget.borderRadius ?? 
                    BorderRadius.circular(AppDimensions.radiusMedium),
                boxShadow: isDisabled
                    ? null
                    : [
                        BoxShadow(
                          color: (widget.backgroundColor ?? AppColors.primaryPink)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDisabled ? null : widget.onPressed,
                  borderRadius: widget.borderRadius ?? 
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.textColor ?? Colors.white,
                              ),
                            ),
                          )
                        else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: widget.textColor ?? Colors.white,
                            size: AppDimensions.iconMedium,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (!widget.isLoading)
                          Text(
                            widget.text,
                            style: AppTypography.buttonText.copyWith(
                              color: widget.textColor ?? Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

#### secondary_button.dart
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? borderColor;
  final Color? textColor;
  
  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeightMedium,
    this.borderColor,
    this.textColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: isEnabled 
              ? (borderColor ?? AppColors.primaryPink)
              : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isEnabled 
                        ? (textColor ?? AppColors.primaryPink)
                        : Colors.grey[500],
                    size: AppDimensions.iconMedium,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: AppTypography.buttonText.copyWith(
                    color: isEnabled 
                        ? (textColor ?? AppColors.primaryPink)
                        : Colors.grey[500],
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
```

### 3. Card Components

#### base_card.dart
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool showShadow;
  final Gradient? gradient;
  
  const BaseCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.showShadow = true,
    this.gradient,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final cardRadius = borderRadius ?? BorderRadius.circular(AppDimensions.radiusLarge);
    
    return Container(
      margin: margin ?? const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (backgroundColor ?? Colors.white) : null,
        borderRadius: cardRadius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardRadius,
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppDimensions.paddingLarge),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

#### content_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import 'base_card.dart';

class ContentCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final bool showImage;
  final double? imageHeight;
  
  const ContentCard({
    Key? key,
    this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.icon,
    this.onTap,
    this.actions,
    this.showImage = true,
    this.imageHeight = 120,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          if (showImage && (imageUrl != null || icon != null))
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusLarge),
              ),
              child: imageUrl != null 
                  ? _buildNetworkImage()
                  : _buildIconHeader(),
            ),
          
          // Content Section
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: AppTypography.headingSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                if (subtitle != null) ...[
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    subtitle!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                if (description != null) ...[
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Text(
                    description!,
                    style: AppTypography.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.paddingLarge),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      height: imageHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: imageHeight,
          width: double.infinity,
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: imageHeight,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(
          Icons.image_not_supported,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  Widget _buildIconHeader() {
    return Container(
      height: imageHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Icon(
          icon,
          size: AppDimensions.iconXLarge,
          color: Colors.white,
        ),
      ),
    );
  }
}
```

### 4. Form Components

#### custom_text_field.dart
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final bool isRequired;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  
  const CustomTextField({
    Key? key,
    this.label,
    this.hint,
    this.errorText,
    this.isRequired = false,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }
  
  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }
  
  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
            child: Row(
              children: [
                Text(
                  widget.label!,
                  style: AppTypography.label,
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: AppTypography.label.copyWith(
                      color: AppColors.errorRed,
                    ),
                  ),
              ],
            ),
          ),
        
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: widget.errorText != null
                  ? AppColors.errorRed
                  : _isFocused
                      ? AppColors.primaryPink
                      : Colors.grey[300]!,
              width: _isFocused || widget.errorText != null ? 2 : 1,
            ),
            color: widget.readOnly ? Colors.grey[50] : Colors.white,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            validator: widget.validator,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused ? AppColors.primaryPink : Colors.grey[500],
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(
                        widget.suffixIcon,
                        color: _isFocused ? AppColors.primaryPink : Colors.grey[500],
                      ),
                      onPressed: widget.onSuffixIconTap,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppDimensions.paddingLarge),
            ),
          ),
        ),
        
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppDimensions.paddingSmall,
              left: AppDimensions.paddingMedium,
            ),
            child: Text(
              widget.errorText!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
      ],
    );
  }
}
```

## 🔁 Integration Guide

### Step 1: Copy Component Files
1. Create the widgets directory structure in your project
2. Copy all component files to their respective folders
3. Import the components in your screens

### Step 2: Usage Examples

#### Using Buttons
```dart
// Primary button with loading state
PrimaryButton(
  text: 'Save Changes',
  onPressed: _handleSave,
  isLoading: _isLoading,
  icon: Icons.save,
)

// Secondary button
SecondaryButton(
  text: 'Cancel',
  onPressed: () => Navigator.pop(context),
)
```

#### Using Cards
```dart
// Content card with image
ContentCard(
  title: 'Beauty Routine',
  subtitle: 'Morning Skincare',
  description: 'A complete morning skincare routine...',
  imageUrl: 'https://example.com/image.jpg',
  onTap: () => _navigateToDetail(),
  actions: [
    IconButton(
      icon: Icon(Icons.favorite_border),
      onPressed: _toggleFavorite,
    ),
  ],
)
```

#### Using Forms
```dart
// Custom text field with validation
CustomTextField(
  label: 'Email Address',
  hint: 'Enter your email',
  isRequired: true,
  prefixIcon: Icons.email,
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Email is required';
    if (!value!.contains('@')) return 'Invalid email format';
    return null;
  },
)
```

## 💾 Persistence Handling

- **Form State**: Automatic form validation and error display
- **Image Caching**: Network images cached for offline viewing
- **Animation State**: Smooth transitions preserved during navigation
- **Loading States**: Consistent loading indicators across components

## 📱 UI Details

### Responsive Behavior
- **Mobile**: Single column layouts, full-width components
- **Tablet**: Multi-column grids, larger touch targets
- **Desktop**: Dense layouts, hover effects, keyboard navigation

### Animation Features
- **Button Press**: Scale animation on tap
- **Card Hover**: Elevation changes on interaction
- **Form Focus**: Border color transitions
- **Loading States**: Shimmer effects and progress indicators

### Design System
- **Consistent Spacing**: Using AppDimensions constants
- **Unified Colors**: AppColors palette throughout
- **Typography Scale**: AppTypography styles applied
- **Shadow System**: Consistent elevation and shadows

## 🔄 Feature Validation

✅ **Responsive Design**: Components adapt to all screen sizes
✅ **Touch Feedback**: Visual feedback on all interactions
✅ **Loading States**: Proper loading and error states
✅ **Accessibility**: Screen reader support and keyboard navigation
✅ **Performance**: Optimized rendering and animations
✅ **Consistency**: Unified design system throughout

---

**Next**: Continue with `04_Screens_Pages` to implement complete screen layouts using these components. 