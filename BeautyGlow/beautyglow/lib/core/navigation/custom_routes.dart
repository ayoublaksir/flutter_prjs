import 'package:flutter/material.dart';

/// Slide transition for primary navigation
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideRightRoute({required this.page, required this.duration})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
}

/// Fade transition for smooth screen changes
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadeRoute({required this.page, required this.duration})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Scale transition for modal dialogs
class ScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ScaleRoute({required this.page, required this.duration})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.elasticOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var scaleAnimation = animation.drive(tween);

            return ScaleTransition(scale: scaleAnimation, child: child);
          },
        );
}

/// Slide up transition for bottom sheets
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideUpRoute({required this.page, required this.duration})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
}

/// Combined slide and fade transition
class SlideFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideFadeRoute({required this.page, required this.duration})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const slideBegin = Offset(0.0, 0.1);
            const slideEnd = Offset.zero;
            const fadeBegin = 0.0;
            const fadeEnd = 1.0;
            const curve = Curves.easeInOut;

            var slideTween = Tween(begin: slideBegin, end: slideEnd)
                .chain(CurveTween(curve: curve));
            var fadeTween = Tween(begin: fadeBegin, end: fadeEnd)
                .chain(CurveTween(curve: curve));

            var slideAnimation = animation.drive(slideTween);
            var fadeAnimation = animation.drive(fadeTween);

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}
