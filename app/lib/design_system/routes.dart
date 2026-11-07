import 'package:flutter/material.dart';
import 'motion.dart';

/// Full-screen slide from the right (DC §6.1 `slide`, PTH-11/12, LES-08).
/// Reduced motion falls back to an instant change.
Route<T> slideRoute<T>(WidgetBuilder builder, {bool reducedMotion = false}) =>
    PageRouteBuilder<T>(
      transitionDuration: reducedMotion ? Duration.zero : SumiMotion.slide,
      reverseTransitionDuration: reducedMotion
          ? Duration.zero
          : SumiMotion.slide,
      pageBuilder: (context, _, _) => builder(context),
      transitionsBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: SumiMotion.slideInCurve,
            reverseCurve: SumiMotion.slideOutCurve,
          ),
        ),
        child: child,
      ),
    );
