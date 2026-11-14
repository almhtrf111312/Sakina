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
  static const Color nightBackground = Color(0xFF0E1514);

  /// Slightly lighter surface / card background
  static const Color nightSurface = Color(0xFF16211F);

  /// Elevated / dialog background
  static const Color nightElevated = Color(0xFF1D2B28);

  /// Teal-green accent
  static const Color nightPrimary = Color(0xFF5FB59B);

  /// Gold accent
  static const Color nightSecondary = Color(0xFFC9A86A);

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
  static const Color dayPrimary = Color(0xFF2F7F69);

  /// Warm gold secondary
  static const Color daySecondary = Color(0xFFA9884A);

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
