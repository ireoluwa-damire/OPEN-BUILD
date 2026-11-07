import 'package:flutter/material.dart';

abstract final class SumiColors {
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF7F9FB);
  static const ink = Color(0xFF3D4654);
  static const muted = Color(0xFF737E8C);
  static const border = Color(0xFFE2E6EA);
  static const borderShadow = Color(0xFFD4D9DE);
  static const primary = Color(0xFF50C86A);
  static const primaryPressed = Color(0xFF3EA955);
  static const primaryShadow = Color(0xFF319248);
  static const primarySoft = Color(0xFFDDF7E4);
  static const sky = Color(0xFF2AA8E8);
  static const skyShadow = Color(0xFF1688C4);
  static const violet = Color(0xFFA86BE8);
  static const amber = Color(0xFFFFBE3F);
  static const coral = Color(0xFFFF6670);
  static const coralSoft = Color(0xFFFFE7EA);
  static const warning = Color(0xFFE99522);
  static const disabled = Color(0xFFE5E8EB);
  static const disabledText = Color(0xFFA7AFB8);
  static const focusRing = Color(0xFF2A8FD4);

  // DC §2.2 derived tokens.
  static const skySoft = Color(0xFFDDF2FC);
  static const amberSoft = Color(0xFFFFF4D6);
  static const violetSoft = Color(0xFFF1E7FC);
  static const violetShadow = Color(0xFF7E50AE);
  static const amberShadow = Color(0xFFBF8E2F);
  static const coralShadow = Color(0xFFBF4C54);
  static const successInk = Color(0xFF217744);
  static const errorInk = Color(0xFFB52D43);
  static const warningInk = Color(0xFF98600A);
  static const infoInk = Color(0xFF216998);
  static const violetInk = Color(0xFF6B3AA8);
  static const mutedStrong = Color(0xFF5E6977);
  static const unitTeal = Color(0xFF246F89);
  static const unitTealShadow = Color(0xFF1B5367);
  static const unitPlum = Color(0xFF87537D);
  static const unitPlumShadow = Color(0xFF653E5E);
  static const unitOlive = Color(0xFF58733C);
  static const unitOliveShadow = Color(0xFF42562D);
  static Color get scrim => ink.withValues(alpha: .4);

  // DC §2.4 high-contrast swaps.
  static const hcPrimary = Color(0xFF2B7D3E);
  static const hcSky = Color(0xFF137AB0);
  static const hcCoral = Color(0xFFC8303F);
  static const hcMuted = Color(0xFF5B6573);
  static const hcBorder = Color(0xFF8A939E);
}

/// DC §4.1 spacing scale.
abstract final class SumiSpace {
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s20 = 20.0;
  static const s24 = 24.0, s32 = 32.0, s40 = 40.0, s48 = 48.0;
}

/// DC §4.3 radii.
abstract final class SumiRadius {
  static const r8 = 8.0, r12 = 12.0, r16 = 16.0, r24 = 24.0, pill = 999.0;
}

/// DC §4.2 responsive gutter.
abstract final class SumiLayout {
  static double gutter(double width) => width < 360
      ? 16
      : width < 420
      ? 20
      : 24;
}

const sumiFontFamily = 'Nunito';
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData sumiTheme({bool highContrast = false}) => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: SumiColors.canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: SumiColors.primary,
    primary: highContrast ? SumiColors.hcPrimary : SumiColors.primary,
    surface: SumiColors.surface,
    onSurface: SumiColors.ink,
  ),
  fontFamily: sumiFontFamily,
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 30,
      height: 37 / 30,
      fontWeight: FontWeight.w800,
      color: SumiColors.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w800,
      color: SumiColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w800,
      color: SumiColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      height: 22 / 17,
      fontWeight: FontWeight.w700,
      color: SumiColors.ink,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      color: SumiColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: highContrast ? SumiColors.hcMuted : SumiColors.mutedStrong,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 18 / 14,
      fontWeight: FontWeight.w800,
      color: Colors.white,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w700,
      color: highContrast ? SumiColors.hcMuted : SumiColors.mutedStrong,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: .6,
      fontWeight: FontWeight.w700,
      color: highContrast ? SumiColors.hcMuted : SumiColors.mutedStrong,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: Size(48, 56),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      backgroundColor: SumiColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: TextStyle(
        fontFamily: sumiFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: Size(48, 52),
      side: BorderSide(
        color: highContrast ? SumiColors.hcBorder : SumiColors.border,
        width: 2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SumiColors.surfaceSoft,
    contentPadding: EdgeInsets.all(18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: SumiColors.border, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: SumiColors.border, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: SumiColors.focusRing, width: 3),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: SumiColors.surface,
    indicatorColor: SumiColors.primarySoft,
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: SumiColors.ink,
      ),
    ),
  ),
);
