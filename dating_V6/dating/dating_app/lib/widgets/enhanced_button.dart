import 'package:flutter/material.dart';

// Create a new reusable enhanced button widget
class EnhancedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final bool isOutlined;
  final double elevation;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final bool isLoading;
  final bool fullWidth;

  const EnhancedButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.isOutlined = false,
    this.elevation = 2,
    this.borderRadius,
    this.padding,
    this.isLoading = false,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: Material(
        color:
            isOutlined
                ? Colors.transparent
                : (backgroundColor ?? Theme.of(context).colorScheme.primary),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: Container(
            padding:
                padding ?? EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration:
                isOutlined
                    ? BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                      borderRadius: borderRadius ?? BorderRadius.circular(16),
                    )
                    : null,
            child: Center(
              child:
                  isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOutlined
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                          ),
                        ),
                      )
                      : DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              isOutlined
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white,
                        ),
                        child: child,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
