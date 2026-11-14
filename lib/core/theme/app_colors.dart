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

  /// Dark green-black background
  static Color get nightBackground => AppPalette.amoled ? const Color(0xFF000000) : const Color(0xFF0E1514);

  /// Slightly lighter surface / card background
  static Color get nightSurface => AppPalette.amoled ? const Color(0xFF0A0D0C) : const Color(0xFF16211F);

  /// Elevated / dialog background
  static Color get nightElevated => AppPalette.amoled ? const Color(0xFF131917) : const Color(0xFF1D2B28);

  /// Teal-green accent
  static Color get nightPrimary => AppPalette.primaryDark;

  /// Gold accent
  static Color get nightSecondary => AppPalette.secondaryDark;

  /// Primary text
  static const Color nightTextPrimary = Color(0xFFE8EFEC);

  /// Secondary / muted text
  static const Color nightTextSecondary = Color(0xFF9DB0AA);

  // -------------------------------------------------------------------------
  // Day theme
  // -------------------------------------------------------------------------

  /// Warm off-white background
  static const Color dayBackground = Color(0xFFF6F4EE);

  /// Pure white card/surface
  static const Color daySurface = Color(0xFFFFFFFF);

  /// Deeper teal primary
  static Color get dayPrimary => AppPalette.primaryLight;

  /// Warm gold secondary
  static Color get daySecondary => AppPalette.secondaryLight;

  /// Dark green-grey text
  static const Color dayTextPrimary = Color(0xFF1B2A27);

  /// Muted warm grey secondary text
  static const Color dayTextSecondary = Color(0xFF607068);

  // -------------------------------------------------------------------------
  // AMOLED theme
  // -------------------------------------------------------------------------

  /// Pure black background
  static const Color amoledBackground = Color(0xFF000000);

  /// Very dark card surface
  static const Color amoledSurface = Color(0xFF0A0F0E);

  /// Slightly elevated (dialogs, sheets)
  static const Color amoledElevated = Color(0xFF111918);

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
