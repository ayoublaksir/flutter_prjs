import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';

enum ButtonType { primary, secondary, outline, text }

enum ButtonSize { small, medium, large }

/// Custom button widget with various styles and animations
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final Color? color;
  final Color? textColor;
  final Gradient? gradient;
  final double? borderRadius;
  final EdgeInsets? padding;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.color,
    this.textColor,
    this.gradient,
    this.borderRadius,
    this.padding,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
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
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = _getButtonHeight();
    final horizontalPadding = _getHorizontalPadding();
    final fontSize = _getFontSize();

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: buttonHeight,
              width: widget.isFullWidth ? double.infinity : widget.width,
              constraints: BoxConstraints(
                minWidth: widget.isFullWidth
                    ? double.infinity
                    : AppDimensions.buttonMinWidth,
              ),
              decoration: _getButtonDecoration(),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? _getDefaultBorderRadius(),
                  ),
                  onTap: widget.isLoading ? null : widget.onPressed,
                  child: Padding(
                    padding: widget.padding ??
                        EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                    child: Center(
                      child: widget.isLoading
                          ? _buildLoadingIndicator()
                          : _buildButtonContent(fontSize),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.type == ButtonType.primary
              ? Colors.white
              : AppColors.primaryPink,
        ),
      ),
    );
  }

  Widget _buildButtonContent(double fontSize) {
    final hasIcon = widget.icon != null;
    final textWidget = Text(
      widget.text,
      style: _getTextStyle(fontSize),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!hasIcon) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.icon,
          size: fontSize + 4,
          color: _getTextColor(),
        ),
        SizedBox(
          width: ResponsiveUtil.instance.proportionateWidth(8),
        ),
        Flexible(child: textWidget),
      ],
    );
  }

  BoxDecoration _getButtonDecoration() {
    switch (widget.type) {
      case ButtonType.primary:
        return BoxDecoration(
          gradient: widget.gradient ??
              (widget.color != null ? null : AppColors.primaryGradient),
          color: widget.color,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? _getDefaultBorderRadius(),
          ),
          boxShadow: widget.onPressed != null
              ? [
                  BoxShadow(
                    color: (widget.color ?? AppColors.primaryPink)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );
      case ButtonType.secondary:
        return BoxDecoration(
          color: widget.color ?? AppColors.softRose,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? _getDefaultBorderRadius(),
          ),
        );
      case ButtonType.outline:
        return BoxDecoration(
          border: Border.all(
            color: widget.color ?? AppColors.primaryPink,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? _getDefaultBorderRadius(),
          ),
        );
      case ButtonType.text:
        return const BoxDecoration(
          color: Colors.transparent,
        );
    }
  }

  TextStyle _getTextStyle(double fontSize) {
    final baseStyle = AppTypography.buttonText.copyWith(
      fontSize: fontSize,
      color: _getTextColor(),
    );

    if (widget.onPressed == null) {
      return baseStyle.copyWith(
        color: baseStyle.color!.withOpacity(0.5),
      );
    }

    return baseStyle;
  }

  Color _getTextColor() {
    if (widget.textColor != null) {
      return widget.textColor!;
    }

    switch (widget.type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return AppColors.primaryPink;
      case ButtonType.outline:
      case ButtonType.text:
        return widget.color ?? AppColors.primaryPink;
    }
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return ResponsiveUtil.instance.proportionateHeight(
          AppDimensions.buttonHeightSmall,
        );
      case ButtonSize.medium:
        return ResponsiveUtil.instance.proportionateHeight(
          AppDimensions.buttonHeightMedium,
        );
      case ButtonSize.large:
        return ResponsiveUtil.instance.proportionateHeight(
          AppDimensions.buttonHeightLarge,
        );
    }
  }

  double _getHorizontalPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return ResponsiveUtil.instance.proportionateWidth(12);
      case ButtonSize.medium:
        return ResponsiveUtil.instance.proportionateWidth(16);
      case ButtonSize.large:
        return ResponsiveUtil.instance.proportionateWidth(20);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return ResponsiveUtil.instance.scaledFontSize(14);
      case ButtonSize.medium:
        return ResponsiveUtil.instance.scaledFontSize(16);
      case ButtonSize.large:
        return ResponsiveUtil.instance.scaledFontSize(18);
    }
  }

  double _getDefaultBorderRadius() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppDimensions.radiusSmall;
      case ButtonSize.medium:
        return AppDimensions.radiusMedium;
      case ButtonSize.large:
        return AppDimensions.radiusLarge;
    }
  }
}
