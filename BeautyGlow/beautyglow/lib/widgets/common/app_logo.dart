import 'package:flutter/material.dart';

/// A reusable widget for displaying the BeautyGlow app logo
class AppLogo extends StatelessWidget {
  /// The size of the logo container
  final double size;

  /// Whether to show a background behind the logo
  final bool showBackground;

  /// Optional background color, defaults to transparent
  final Color backgroundColor;

  /// Optional callback when logo is tapped
  final VoidCallback? onTap;

  /// Optional padding around the logo
  final EdgeInsetsGeometry? padding;

  const AppLogo({
    Key? key,
    this.size = 100.0,
    this.showBackground = false,
    this.backgroundColor = Colors.transparent,
    this.onTap,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget logo = Container(
      width: size,
      height: size,
      padding: padding ??
          EdgeInsets.all(size * 0.1), // Default padding of 10% of size
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
        ),
      ),
    );

    if (onTap != null) {
      logo = GestureDetector(
        onTap: onTap,
        child: logo,
      );
    }

    return logo;
  }
}
