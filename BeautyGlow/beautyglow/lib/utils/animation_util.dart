import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Utility class for animations
class AnimationUtil {
  AnimationUtil._();

  // Standard durations
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);

  // Standard curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;

  /// Fade in animation effect
  static List<Effect> fadeIn({
    Duration? delay,
    Duration? duration,
    Curve? curve,
  }) {
    return [
      FadeEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? mediumDuration,
        curve: curve ?? defaultCurve,
        begin: 0.0,
        end: 1.0,
      ),
    ];
  }

  /// Slide up animation effect
  static List<Effect> slideUp({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double offset = 20,
  }) {
    return [
      SlideEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? mediumDuration,
        curve: curve ?? defaultCurve,
        begin: Offset(0, offset),
        end: Offset.zero,
      ),
      FadeEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? mediumDuration,
        curve: curve ?? defaultCurve,
        begin: 0.0,
        end: 1.0,
      ),
    ];
  }

  /// Scale animation effect
  static List<Effect> scale({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double begin = 0.8,
  }) {
    return [
      ScaleEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? mediumDuration,
        curve: curve ?? bounceCurve,
        begin: Offset(begin, begin),
        end: const Offset(1.0, 1.0),
      ),
      FadeEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? mediumDuration,
        curve: curve ?? defaultCurve,
        begin: 0.0,
        end: 1.0,
      ),
    ];
  }

  /// Shimmer loading effect
  static List<Effect> shimmer({
    Duration? delay,
    Duration? duration,
    Color? color,
  }) {
    return [
      ShimmerEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? const Duration(milliseconds: 1500),
        color: color ?? Colors.white.withOpacity(0.3),
      ),
    ];
  }

  /// Bounce animation effect
  static List<Effect> bounce({
    Duration? delay,
    Duration? duration,
    double height = 10,
  }) {
    return [
      SlideEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        begin: Offset(0, -height),
        end: Offset.zero,
      ),
    ];
  }

  /// List item stagger animation
  static List<Effect> listItemAnimation(int index) {
    return [
      FadeEffect(
        delay: Duration(milliseconds: 100 * index),
        duration: mediumDuration,
        begin: 0.0,
        end: 1.0,
      ),
      SlideEffect(
        delay: Duration(milliseconds: 100 * index),
        duration: mediumDuration,
        curve: smoothCurve,
        begin: const Offset(0, 10),
        end: Offset.zero,
      ),
    ];
  }

  /// Achievement unlock animation
  static List<Effect> achievementUnlock() {
    return [
      ScaleEffect(
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        begin: const Offset(0.0, 0.0),
        end: const Offset(1.0, 1.0),
      ),
      RotateEffect(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        begin: 0.5,
        end: 0.0,
      ),
    ];
  }

  /// Card press animation
  static List<Effect> cardPress() {
    return [
      ScaleEffect(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeIn,
        begin: const Offset(1.0, 1.0),
        end: const Offset(0.95, 0.95),
      ),
    ];
  }

  /// Page transition animation
  static Widget pageTransition({
    required Widget child,
    bool reverse = false,
  }) {
    return child
        .animate()
        .fade(
          duration: mediumDuration,
          begin: reverse ? 1.0 : 0.0,
          end: reverse ? 0.0 : 1.0,
        )
        .slideX(
          duration: mediumDuration,
          begin: reverse ? 0.0 : 0.1,
          end: reverse ? -0.1 : 0.0,
          curve: smoothCurve,
        );
  }

  /// Loading dots animation
  static Widget loadingDots({
    Color? color,
    double size = 10,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: size,
          height: size,
          margin: EdgeInsets.symmetric(horizontal: size / 4),
          decoration: BoxDecoration(
            color: color ?? Colors.grey,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
            )
            .scale(
              delay: Duration(milliseconds: index * 200),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
            )
            .then()
            .scale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              begin: const Offset(1.2, 1.2),
              end: const Offset(0.8, 0.8),
            );
      }),
    );
  }

  /// Success checkmark animation
  static Widget successCheckmark({
    double size = 100,
    Color? color,
  }) {
    return Icon(
      Icons.check_circle,
      size: size,
      color: color ?? Colors.green,
    ).animate().scale(
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.0, 1.0),
        );
  }

  /// Custom animated container
  static Widget animatedContainer({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return AnimatedContainer(
      duration: duration ?? mediumDuration,
      curve: curve ?? defaultCurve,
      child: child,
    );
  }
}
