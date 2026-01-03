import 'package:flutter/material.dart';
import 'custom_routes.dart';

enum TransitionType { slide, fade, scale, none }

/// Navigation manager for handling app navigation
class NavigationManager {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navigation with custom transitions
  static Future<T?> pushWithTransition<T>(
    BuildContext context,
    Widget screen, {
    TransitionType transition = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    Route<T> route;

    switch (transition) {
      case TransitionType.slide:
        route = SlideRightRoute<T>(page: screen, duration: duration);
        break;
      case TransitionType.fade:
        route = FadeRoute<T>(page: screen, duration: duration);
        break;
      case TransitionType.scale:
        route = ScaleRoute<T>(page: screen, duration: duration);
        break;
      case TransitionType.none:
        route = MaterialPageRoute<T>(builder: (_) => screen);
        break;
    }

    return Navigator.of(context).push(route);
  }

  /// Push replacement with custom transitions
  static Future<T?> pushReplacementWithTransition<T, TO>(
    BuildContext context,
    Widget screen, {
    TransitionType transition = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    TO? result,
  }) {
    Route<T> route;

    switch (transition) {
      case TransitionType.slide:
        route = SlideRightRoute<T>(page: screen, duration: duration);
        break;
      case TransitionType.fade:
        route = FadeRoute<T>(page: screen, duration: duration);
        break;
      case TransitionType.scale:
        route = ScaleRoute<T>(page: screen, duration: duration);
        break;
      case TransitionType.none:
        route = MaterialPageRoute<T>(builder: (_) => screen);
        break;
    }

    return Navigator.of(context).pushReplacement(route, result: result);
  }

  /// Push and remove until
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    Widget screen,
    RoutePredicate predicate, {
    TransitionType transition = TransitionType.fade,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    Route<T> route;

    switch (transition) {
      case TransitionType.slide:
        route = SlideRightRoute<T>(page: screen, duration: duration);
        break;
      case TransitionType.fade:
        route = FadeRoute<T>(page: screen, duration: duration);
        break;
      case TransitionType.scale:
        route = ScaleRoute<T>(page: screen, duration: duration);
        break;
      case TransitionType.none:
        route = MaterialPageRoute<T>(builder: (_) => screen);
        break;
    }

    return Navigator.of(context).pushAndRemoveUntil(route, predicate);
  }

  /// Bottom sheet navigation (for quick actions)
  static Future<T?> showBottomSheet<T>(
    BuildContext context,
    Widget content, {
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor ?? Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: content,
      ),
    );
  }

  /// Show dialog with custom animation
  static Future<T?> showCustomDialog<T>(
    BuildContext context,
    Widget dialog, {
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: '',
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => dialog,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: child,
        );
      },
    );
  }

  /// Pop with result
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  /// Can pop
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  /// Pop until first
  static void popUntilFirst(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
