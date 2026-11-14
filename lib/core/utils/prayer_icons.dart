import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Provides icons, colors, and gradients specifically mapped for each prayer.
class PrayerIcons {
  PrayerIcons._();

  // ---------------------------------------------------------------------------
  // Material Icon Data Mapping
  // ---------------------------------------------------------------------------

  static IconData getIcon(String prayerKey) {
    switch (prayerKey.toLowerCase()) {
      case AppConstants.prayerFajr:
        return Icons.nights_stay_rounded; // Crescent/night for Fajr
      case AppConstants.prayerSunrise:
        return Icons.wb_twilight_rounded; // Horizon sun for Sunrise
      case AppConstants.prayerDhuhr:
        return Icons.wb_sunny_rounded; // High noon sun for Dhuhr
      case AppConstants.prayerAsr:
        return Icons.light_mode_outlined; // Afternoon sun for Asr
      case AppConstants.prayerMaghrib:
        return Icons.wb_twilight_outlined; // Sunset glow for Maghrib
      case AppConstants.prayerIsha:
        return Icons.bedtime_rounded; // Full dark night for Isha
      default:
        return Icons.access_time_filled_rounded;
    }
  }

  // ---------------------------------------------------------------------------
  // Prayer Accent Color
  // ---------------------------------------------------------------------------

  static Color getAccentColor(String prayerKey, {bool isDark = true}) {
    switch (prayerKey.toLowerCase()) {
      case AppConstants.prayerFajr:
        return isDark ? const Color(0xFF6B9AC4) : const Color(0xFF386B94); // Cool Dawn Blue
      case AppConstants.prayerSunrise:
        return isDark ? const Color(0xFFE89B5F) : const Color(0xFFC76D2B); // Warm Orange Sunrise
      case AppConstants.prayerDhuhr:
        return isDark ? const Color(0xFFE8C85A) : const Color(0xFFB59320); // Golden Noon
      case AppConstants.prayerAsr:
        return isDark ? const Color(0xFF5FB59B) : const Color(0xFF2F7F69); // Emerald Afternoon
      case AppConstants.prayerMaghrib:
        return isDark ? const Color(0xFFE07A5F) : const Color(0xFFB84D31); // Terracotta Sunset
      case AppConstants.prayerIsha:
        return isDark ? const Color(0xFF7E8CE0) : const Color(0xFF4C5BB3); // Indigo Night
      default:
        return isDark ? AppColors.nightPrimary : AppColors.dayPrimary;
    }
  }

  // ---------------------------------------------------------------------------
  // Gradient for Prayer Cards / Hero Banner
  // ---------------------------------------------------------------------------

  static List<Color> getCardGradient(String prayerKey, {bool isDark = true}) {
    if (isDark) {
      switch (prayerKey.toLowerCase()) {
        case AppConstants.prayerFajr:
          return const [Color(0xFF142436), Color(0xFF0E1514)];
        case AppConstants.prayerSunrise:
          return const [Color(0xFF2E1F14), Color(0xFF0E1514)];
        case AppConstants.prayerDhuhr:
          return const [Color(0xFF282412), Color(0xFF0E1514)];
        case AppConstants.prayerAsr:
          return const [Color(0xFF132A22), Color(0xFF0E1514)];
        case AppConstants.prayerMaghrib:
          return const [Color(0xFF2A1616), Color(0xFF0E1514)];
        case AppConstants.prayerIsha:
          return const [Color(0xFF171A36), Color(0xFF0E1514)];
        default:
          return const [Color(0xFF16211F), Color(0xFF0E1514)];
      }
    } else {
      switch (prayerKey.toLowerCase()) {
        case AppConstants.prayerFajr:
          return const [Color(0xFFE3EDF7), Color(0xFFFFFFFF)];
        case AppConstants.prayerSunrise:
          return const [Color(0xFFFBF0E6), Color(0xFFFFFFFF)];
        case AppConstants.prayerDhuhr:
          return const [Color(0xFFFBF8E6), Color(0xFFFFFFFF)];
        case AppConstants.prayerAsr:
          return const [Color(0xFFE4F4EE), Color(0xFFFFFFFF)];
        case AppConstants.prayerMaghrib:
          return const [Color(0xFFFBECE6), Color(0xFFFFFFFF)];
        case AppConstants.prayerIsha:
          return const [Color(0xFFE8EBF8), Color(0xFFFFFFFF)];
        default:
          return const [Color(0xFFF6F4EE), Color(0xFFFFFFFF)];
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Arabic Display Name
  // ---------------------------------------------------------------------------

  static String getArabicName(String prayerKey) {
    switch (prayerKey.toLowerCase()) {
      case AppConstants.prayerFajr:
        return 'الفجر';
      case AppConstants.prayerSunrise:
        return 'الشروق';
      case AppConstants.prayerDhuhr:
        return 'الظهر';
      case AppConstants.prayerAsr:
        return 'العصر';
      case AppConstants.prayerMaghrib:
        return 'المغرب';
      case AppConstants.prayerIsha:
        return 'العشاء';
      default:
        return prayerKey;
    }
  }

  // ---------------------------------------------------------------------------
  // English Display Name
  // ---------------------------------------------------------------------------

  static String getEnglishName(String prayerKey) {
    switch (prayerKey.toLowerCase()) {
      case AppConstants.prayerFajr:
        return 'Fajr';
      case AppConstants.prayerSunrise:
        return 'Sunrise';
      case AppConstants.prayerDhuhr:
        return 'Dhuhr';
      case AppConstants.prayerAsr:
        return 'Asr';
      case AppConstants.prayerMaghrib:
        return 'Maghrib';
      case AppConstants.prayerIsha:
        return 'Isha';
      default:
        return prayerKey;
    }
  }
}
