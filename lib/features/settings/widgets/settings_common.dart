// lib/features/settings/widgets/settings_common.dart
// Shared helpers and layout pieces used by the settings main page and the
// per-category settings pages.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/prayer/prayer_calculator.dart';
import '../../../data/settings/settings_repository.dart';

// ─── Display names ───────────────────────────────────────────────────────────

String methodName(CalculationMethod m) {
  switch (m) {
    case CalculationMethod.mwl:
      return 'رابطة العالم الإسلامي';
    case CalculationMethod.ummAlQura:
      return 'أم القرى (مكة المكرمة)';
    case CalculationMethod.egyptian:
      return 'الهيئة المصرية للمساحة';
    case CalculationMethod.karachi:
      return 'جامعة كراتشي';
    case CalculationMethod.isna:
      return 'أمريكا الشمالية (ISNA)';
    case CalculationMethod.diyanet:
      return 'الشؤون الدينية التركية';
    case CalculationMethod.dubai:
      return 'دبي (الإمارات)';
    case CalculationMethod.kuwait:
      return 'الكويت (تقويم العجيري)';
    case CalculationMethod.qatar:
      return 'وزارة الأوقاف القطرية';
    case CalculationMethod.singapore:
      return 'سنغافورة (MUIS)';
    case CalculationMethod.tehran:
      return 'جامعة طهران';
    case CalculationMethod.custom:
      return 'تخصيص يدوي';
  }
}

String madhabName(Madhab m) {
  switch (m) {
    case Madhab.shafi:
      return 'الشافعي، المالكي، الحنبلي (الظل = ١)';
    case Madhab.hanafi:
      return 'الحنفي (الظل = ٢)';
  }
}

String highLatName(HighLatitudeRule r) {
  switch (r) {
    case HighLatitudeRule.middleOfNight:
      return 'منتصف الليل (Middle of Night)';
    case HighLatitudeRule.seventhOfNight:
      return 'سُبع الليل (One Seventh)';
    case HighLatitudeRule.angleBased:
      return 'الحساب المبني على الزاوية (Angle-Based)';
  }
}

String themeName(AppThemeMode m) {
  switch (m) {
    case AppThemeMode.night:
      return 'ليلي هادئ (Dark Teal)';
    case AppThemeMode.day:
      return 'نهاري نقي (Light)';
    case AppThemeMode.amoled:
      return 'أسود فاحم (AMOLED)';
    case AppThemeMode.systemAuto:
      return 'تلقائي حسب النظام';
    case AppThemeMode.sunriseAuto:
      return 'تلقائي مع الشروق والغروب';
  }
}

String accentName(AccentColor c) {
  switch (c) {
    case AccentColor.green:
      return 'زمردي';
    case AccentColor.gold:
      return 'ذهبي إسلامي';
    case AccentColor.white:
      return 'أبيض نقي';
    case AccentColor.blue:
      return 'أزرق سماوي';
    case AccentColor.teal:
      return 'تركوازي';
    case AccentColor.purple:
      return 'بنفسجي';
    case AccentColor.rose:
      return 'وردي';
    case AccentColor.orange:
      return 'برتقالي';
    case AccentColor.red:
      return 'أحمر';
    case AccentColor.lime:
      return 'أخضر ليموني';
  }
}

Color accentColorValue(AccentColor c) {
  switch (c) {
    case AccentColor.green:
      return AppColors.nightPrimary;
    case AccentColor.gold:
      return const Color(0xFFD9B46A);
    case AccentColor.white:
      return AppColors.nightTextPrimary;
    case AccentColor.blue:
      return const Color(0xFF6FA8DC);
    case AccentColor.teal:
      return const Color(0xFF4DD0C8);
    case AccentColor.purple:
      return const Color(0xFFB39DDB);
    case AccentColor.rose:
      return const Color(0xFFF28DB2);
    case AccentColor.orange:
      return const Color(0xFFF0A15A);
    case AccentColor.red:
      return const Color(0xFFE57373);
    case AccentColor.lime:
      return const Color(0xFFB5D96B);
  }
}

String notificationModeName(NotificationMode m) {
  switch (m) {
    case NotificationMode.shortBeep:
      return 'أذان';
    case NotificationMode.silent:
      return 'إشعار صامت';
    case NotificationMode.vibrate:
      return 'اهتزاز فقط';
    case NotificationMode.off:
      return 'معطل';
  }
}

IconData notificationModeIcon(NotificationMode m) {
  switch (m) {
    case NotificationMode.shortBeep:
      return Icons.notifications_active_outlined;
    case NotificationMode.silent:
      return Icons.notifications_none_outlined;
    case NotificationMode.vibrate:
      return Icons.vibration_rounded;
    case NotificationMode.off:
      return Icons.volume_off_rounded;
  }
}

String prayerArabic(String key) {
  switch (key) {
    case 'Fajr':
      return 'الفجر';
    case 'Sunrise':
      return 'الشروق';
    case 'Dhuhr':
      return 'الظهر';
    case 'Asr':
      return 'العصر';
    case 'Maghrib':
      return 'المغرب';
    case 'Isha':
      return 'العشاء';
    default:
      return key;
  }
}

// ─── Layout pieces ───────────────────────────────────────────────────────────

Widget buildSettingsCard({required Widget child, required bool isDark}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: isDark ? AppColors.nightSurface : AppColors.daySurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
      ),
    ),
    child: child,
  );
}

Widget settingsDivider(bool isDark) {
  return Divider(
    height: 1,
    thickness: 1,
    indent: 16,
    endIndent: 16,
    color: isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05),
  );
}

/// Scaffold shared by every settings category page.
class SettingsPageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsPageScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.nightBackground : AppColors.dayBackground,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.nightSurface : AppColors.daySurface,
          elevation: 0,
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.nightTextPrimary
                  : AppColors.dayTextPrimary,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            ...children,
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
