import 'package:flutter/material.dart';

/// All color constants for Sakina's three themes.
///
/// Usage:
///   Theme.of(context).colorScheme.primary  — preferred for most UI
///   AppColors.nightPrimary                 — when you need a bare Color value
abstract final class AppColors {
  // -------------------------------------------------------------------------
  // Night theme
  // -------------------------------------------------------------------------

  /// Tinted dark background (pure black in AMOLED mode)
  static Color get nightBackground => AppPalette.tone('bg', dark: true);

  /// Card / surface
  static Color get nightSurface => AppPalette.tone('surface', dark: true);

  /// Elevated / dialog background
  static Color get nightElevated => AppPalette.tone('elevated', dark: true);

  /// Chips, inputs, subtle fills
  static Color get nightChip => AppPalette.tone('chip', dark: true);

  /// Stronger fills / dividers
  static Color get nightChipStrong => AppPalette.tone('chipStrong', dark: true);

  /// Accent
  static Color get nightPrimary => AppPalette.primaryDark;

  /// Secondary accent
  static Color get nightSecondary => AppPalette.secondaryDark;

  /// Primary text
  static Color get nightTextPrimary => AppPalette.tone('text', dark: true);

  /// Secondary / muted text
  static Color get nightTextSecondary => AppPalette.tone('textMuted', dark: true);

  // -------------------------------------------------------------------------
  // Day theme
  // -------------------------------------------------------------------------

  static Color get dayBackground => AppPalette.tone('bg', dark: false);

  /// Card / surface
  static Color get daySurface => AppPalette.tone('surface', dark: false);

  static Color get dayChip => AppPalette.tone('chip', dark: false);

  static Color get dayChipStrong => AppPalette.tone('chipStrong', dark: false);

  /// Deeper primary
  static Color get dayPrimary => AppPalette.primaryLight;

  /// Secondary
  static Color get daySecondary => AppPalette.secondaryLight;

  static Color get dayTextPrimary => AppPalette.tone('text', dark: false);

  static Color get dayTextSecondary => AppPalette.tone('textMuted', dark: false);

  // -------------------------------------------------------------------------
  // AMOLED theme
  // -------------------------------------------------------------------------

  /// Pure black background
  static Color get amoledBackground => const Color(0xFF000000);

  /// Very dark card surface
  static Color get amoledSurface => AppPalette.tone('surface', dark: true, amoled: true);

  /// Slightly elevated (dialogs, sheets)
  static Color get amoledElevated => AppPalette.tone('elevated', dark: true, amoled: true);

  // AMOLED re-uses night primary/secondary/text colours.

  // -------------------------------------------------------------------------
  // Shared semantic colours
  // -------------------------------------------------------------------------

  /// Error / danger
  static const Color error = Color(0xFFCF6679);

  /// Success / valid
  static const Color success = Color(0xFF4CAF88);

  /// Warning / caution
  static const Color warning = Color(0xFFE8B45A);

  /// Information
  static const Color info = Color(0xFF5B9BD5);

  // -------------------------------------------------------------------------
  // Prayer time card gradients (night)
  // -------------------------------------------------------------------------

  static const List<Color> fajrGradient = [
    Color(0xFF1A2A3A),
    Color(0xFF0E1514),
  ];

  static const List<Color> sunriseGradient = [
    Color(0xFF2C1E0E),
    Color(0xFF0E1514),
  ];

  static const List<Color> dhuhrGradient = [
    Color(0xFF1A2A1E),
    Color(0xFF0E1514),
  ];

  static const List<Color> asrGradient = [
    Color(0xFF1A2420),
    Color(0xFF0E1514),
  ];

  static const List<Color> maghribGradient = [
    Color(0xFF2A1E14),
    Color(0xFF0E1514),
  ];

  static const List<Color> ishaGradient = [
    Color(0xFF101A28),
    Color(0xFF0E1514),
  ];

  // -------------------------------------------------------------------------
  // Prayer time card gradients (day)
  // -------------------------------------------------------------------------

  static const List<Color> fajrGradientDay = [
    Color(0xFFD6E8F0),
    Color(0xFFF6F4EE),
  ];

  static const List<Color> sunriseGradientDay = [
    Color(0xFFF0E5D0),
    Color(0xFFF6F4EE),
  ];

  static const List<Color> dhuhrGradientDay = [
    Color(0xFFD8EDE5),
    Color(0xFFF6F4EE),
  ];

  static const List<Color> asrGradientDay = [
    Color(0xFFDAEDE7),
    Color(0xFFF6F4EE),
  ];

  static const List<Color> maghribGradientDay = [
    Color(0xFFF0DDD0),
    Color(0xFFF6F4EE),
  ];

  static const List<Color> ishaGradientDay = [
    Color(0xFFD0D8E8),
    Color(0xFFF6F4EE),
  ];

  // -------------------------------------------------------------------------
  // Qibla compass colours
  // -------------------------------------------------------------------------

  static const Color compassNeedle = Color(0xFF5FB59B);
  static const Color compassNeedleSouth = Color(0xFFCF6679);
  static const Color compassRing = Color(0xFF1D2B28);
  static const Color compassRingDay = Color(0xFFEBE9E3);

  // -------------------------------------------------------------------------
  // Tasbih colours
  // -------------------------------------------------------------------------

  static const Color tasbihBead = Color(0xFF5FB59B);
  static const Color tasbihBeadDay = Color(0xFF2F7F69);
  static const Color tasbihCounter = Color(0xFFE8EFEC);
  static const Color tasbihCounterDay = Color(0xFF1B2A27);

  // -------------------------------------------------------------------------
  // Utility helpers
  // -------------------------------------------------------------------------

  /// Semi-transparent black overlay.
  static Color overlay(double opacity) => Colors.black.withOpacity(opacity);

  /// Semi-transparent white overlay.
  static Color overlayWhite(double opacity) =>
      Colors.white.withOpacity(opacity);
}


/// Runtime palette switches (AMOLED + accent colour). Set from the app root
/// before the themes are built, so every `AppColors.night*` / `day*` read
/// follows the user's choice.
abstract final class AppPalette {
  static bool amoled = false;

  static double get _hue {
    switch (accent) {
      case 'gold':
        return 40;
      case 'white':
        return 200;
      case 'blue':
        return 212;
      case 'teal':
        return 178;
      case 'purple':
        return 262;
      case 'rose':
        return 335;
      case 'orange':
        return 28;
      case 'red':
        return 2;
      case 'lime':
        return 82;
      default:
        return 160;
    }
  }

  /// Coherent surface/text tones derived from the accent hue.
  static Color tone(String role, {required bool dark, bool? amoled}) {
    final h = _hue;
    final am = amoled ?? AppPalette.amoled;
    // Neutral accent keeps the tint very low.
    final k = accent == 'white' ? 0.35 : 1.0;
    Color hsl(double s, double l) =>
        HSLColor.fromAHSL(1, h, (s * k).clamp(0.0, 1.0), l).toColor();
    if (dark) {
      if (am) {
        switch (role) {
          case 'bg':
            return const Color(0xFF000000);
          case 'surface':
            return hsl(0.22, 0.05);
          case 'elevated':
            return hsl(0.20, 0.08);
          case 'chip':
            return hsl(0.18, 0.11);
          case 'chipStrong':
            return hsl(0.16, 0.16);
        }
      } else {
        switch (role) {
          case 'bg':
            return hsl(0.22, 0.075);
          case 'surface':
            return hsl(0.20, 0.115);
          case 'elevated':
            return hsl(0.19, 0.155);
          case 'chip':
            return hsl(0.18, 0.20);
          case 'chipStrong':
            return hsl(0.16, 0.26);
        }
      }
      return role == 'text' ? hsl(0.25, 0.93) : hsl(0.14, 0.68);
    }
    switch (role) {
      case 'bg':
        return hsl(0.30, 0.955);
      case 'surface':
        return hsl(0.45, 0.99);
      case 'chip':
        return hsl(0.30, 0.925);
      case 'chipStrong':
        return hsl(0.26, 0.88);
      case 'elevated':
        return hsl(0.45, 0.99);
    }
    return role == 'text' ? hsl(0.40, 0.12) : hsl(0.14, 0.38);
  }

  /// green | gold | white | blue | teal | purple | rose | orange | red | lime
  static String accent = 'green';

  static Color get primaryDark {
    switch (accent) {
      case 'gold':
        return const Color(0xFFD9B46A);
      case 'white':
        return const Color(0xFFE8EFEC);
      case 'blue':
        return const Color(0xFF6FA8DC);
      case 'teal':
        return const Color(0xFF4DD0C8);
      case 'purple':
        return const Color(0xFFB39DDB);
      case 'rose':
        return const Color(0xFFF28DB2);
      case 'orange':
        return const Color(0xFFF0A15A);
      case 'red':
        return const Color(0xFFE57373);
      case 'lime':
        return const Color(0xFFB5D96B);
      default:
        return const Color(0xFF5FB59B);
    }
  }

  static Color get primaryLight {
    switch (accent) {
      case 'gold':
        return const Color(0xFFA9843F);
      case 'white':
        return const Color(0xFF3B4A46);
      case 'blue':
        return const Color(0xFF3F78B5);
      case 'teal':
        return const Color(0xFF1F8A84);
      case 'purple':
        return const Color(0xFF6A4FB0);
      case 'rose':
        return const Color(0xFFC2477A);
      case 'orange':
        return const Color(0xFFC9702A);
      case 'red':
        return const Color(0xFFB83A3A);
      case 'lime':
        return const Color(0xFF6E9A1F);
      default:
        return const Color(0xFF2F7F69);
    }
  }

  // When the accent is gold, the former primary green takes the gold's place.
  static Color get secondaryDark =>
      accent == 'gold' ? const Color(0xFF5FB59B) : const Color(0xFFC9A86A);

  static Color get secondaryLight =>
      accent == 'gold' ? const Color(0xFF2F7F69) : const Color(0xFFA9884A);
}
