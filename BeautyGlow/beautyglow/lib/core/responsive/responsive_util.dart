import 'package:flutter/material.dart';

/// Responsive utility for adaptive layout and sizing
class ResponsiveUtil {
  static final ResponsiveUtil instance = ResponsiveUtil._internal();
  factory ResponsiveUtil() => instance;
  ResponsiveUtil._internal();

  late MediaQueryData _mediaQueryData;
  late double screenWidth;
  late double screenHeight;
  late double defaultSize;
  late Orientation orientation;
  late bool isTablet;
  late bool isMobile;

  // Base dimensions for scaling (based on iPhone 12 Pro)
  static const double baseWidth = 390;
  static const double baseHeight = 844;

  bool _isInitialized = false;

  /// Initialize responsive utility with context
  void init(BuildContext context) {
    if (!_isInitialized) {
      _mediaQueryData = MediaQuery.of(context);
      screenWidth = _mediaQueryData.size.width;
      screenHeight = _mediaQueryData.size.height;
      orientation = _mediaQueryData.orientation;

      // Device type detection
      isTablet = screenWidth >= 600;
      isMobile = screenWidth < 600;

      // Initialize default size based on orientation
      defaultSize = orientation == Orientation.landscape
          ? screenHeight * 0.024
          : screenWidth * 0.024;

      _isInitialized = true;
    }
  }

  /// Proportional width (maintains aspect ratio)
  double proportionateWidth(double inputWidth) {
    return (inputWidth / baseWidth) * screenWidth;
  }

  /// Proportional height (maintains aspect ratio)
  double proportionateHeight(double inputHeight) {
    return (inputHeight / baseHeight) * screenHeight;
  }

  /// Scaled font size (responsive typography)
  double scaledFontSize(double fontSize) {
    double scale = isMobile ? 1.0 : 1.2;
    return fontSize * scale * (screenWidth / baseWidth);
  }

  /// Adaptive padding
  EdgeInsets adaptivePadding({
    double horizontal = 16.0,
    double vertical = 16.0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: proportionateWidth(horizontal),
      vertical: proportionateHeight(vertical),
    );
  }

  /// Adaptive margin
  EdgeInsets adaptiveMargin({
    double horizontal = 16.0,
    double vertical = 16.0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: proportionateWidth(horizontal),
      vertical: proportionateHeight(vertical),
    );
  }

  /// Adaptive padding with individual values
  EdgeInsets adaptivePaddingOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) {
    return EdgeInsets.only(
      left: proportionateWidth(left),
      top: proportionateHeight(top),
      right: proportionateWidth(right),
      bottom: proportionateHeight(bottom),
    );
  }

  /// Grid columns (responsive grid layout)
  int getGridColumns(BuildContext context) {
    if (ResponsiveBreakpoints.isMobile(context)) return 2;
    if (ResponsiveBreakpoints.isTablet(context)) return 3;
    return 4; // Desktop
  }

  /// Get adaptive icon size
  double getIconSize(double baseSize) {
    return proportionateWidth(baseSize);
  }

  /// Get adaptive button height
  double getButtonHeight(double baseHeight) {
    return proportionateHeight(baseHeight);
  }

  /// Get adaptive card height
  double getCardHeight(double baseHeight) {
    return proportionateHeight(baseHeight);
  }

  // Get responsive value based on screen width
  T getResponsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (screenWidth >= 1200 && desktop != null) {
      return desktop;
    }
    if (screenWidth >= 600 && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  // Get responsive padding
  EdgeInsets getResponsivePadding({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    double padding = getResponsiveValue(
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );
    return EdgeInsets.all(padding);
  }

  // Get number of grid columns based on screen size
  int getResponsiveGridCount({
    required int mobile,
    int? tablet,
    int? desktop,
  }) {
    return getResponsiveValue(
      mobile: mobile,
      tablet: tablet ?? mobile + 1,
      desktop: desktop ?? mobile + 2,
    );
  }

  // Get responsive height for containers
  double getResponsiveHeight({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getResponsiveValue(
      mobile: proportionateHeight(mobile),
      tablet: proportionateHeight(tablet ?? mobile * 1.2),
      desktop: proportionateHeight(desktop ?? mobile * 1.5),
    );
  }
}

/// Responsive breakpoints for different screen sizes
class ResponsiveBreakpoints {
  // Screen size categories
  static const double mobileSmall = 360; // iPhone SE, small Androids
  static const double mobileLarge = 414; // iPhone Pro Max, large phones
  static const double tabletSmall = 768; // iPad Mini, compact tablets
  static const double tabletLarge = 1024; // iPad Pro, large tablets
  static const double desktop = 1200; // Desktop displays

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletSmall;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletSmall && width < desktop;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Check if device is small mobile
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= mobileSmall;
  }

  /// Check if device is large mobile
  static bool isLargeMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileSmall && width <= mobileLarge;
  }
}
