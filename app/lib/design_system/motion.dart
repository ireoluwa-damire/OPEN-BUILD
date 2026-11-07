import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// DC §6.1 motion tokens (MOT-01) and the loop guard (MOT-04).
abstract final class SumiMotion {
  static const press = Duration(milliseconds: 100);
  static const micro = Duration(milliseconds: 160);
  static const card = Duration(milliseconds: 200);
  static const screen = Duration(milliseconds: 220);
  static const sheet = Duration(milliseconds: 240);
  static const slide = Duration(milliseconds: 280);
  static const pathReveal = Duration(milliseconds: 420);
  static const celebrationSmall = Duration(milliseconds: 650);
  static const nodeEvent = Duration(milliseconds: 800);
  static const celebrationLarge = Duration(milliseconds: 1200);
  static const breath = Duration(milliseconds: 1600);
  static const tabSwitch = Duration(milliseconds: 120);
  static const reducedFade = Duration(milliseconds: 120);

  static const pressCurve = Curves.easeOut;
  static const microCurve = Curves.easeOut;
  static const cardCurve = Curves.easeOutCubic;
  static const screenCurve = Curves.easeInOut;
  static const sheetCurve = Curves.decelerate;
  static const slideInCurve = Curves.easeOutCubic;
  static const slideOutCurve = Curves.easeInCubic;

  /// Looping animations never run under `flutter test`, so `pumpAndSettle`
  /// always completes. Tests may flip this explicitly.
  static bool loopsEnabled = !_underTest();

  static bool _underTest() {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }
}

/// True when the learner or the platform asked for reduced motion.
bool reduceMotion(BuildContext context, {bool learnerSetting = false}) =>
    learnerSetting || MediaQuery.maybeDisableAnimationsOf(context) == true;

/// Loops run only when enabled, motion is not reduced and tickers are on.
bool loopsAllowed(BuildContext context, {bool learnerSetting = false}) =>
    SumiMotion.loopsEnabled &&
    !reduceMotion(context, learnerSetting: learnerSetting) &&
    TickerMode.valuesOf(context).enabled;
