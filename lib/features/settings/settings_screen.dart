import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/alarm_bridge.dart';
import '../../data/prayer/prayer_calculator.dart';
import '../../data/settings/settings_repository.dart';
import '../aod/aod_settings_screen.dart';
import 'widgets/calculation_method_selector.dart';
import 'widgets/permission_check_screen.dart';
import 'widgets/sound_selector_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isTestingAudio = false;

  @override
  void dispose() {
    if (_isTestingAudio) {
      AlarmBridge.stopTestAdhan();
    }
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _methodName(CalculationMethod m) {
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

  String _madhabName(Madhab m) {
    switch (m) {
      case Madhab.shafi:
        return 'الشافعي، المالكي، الحنبلي (الظل = ١)';
      case Madhab.hanafi:
        return 'الحنفي (الظل = ٢)';
    }
  }

  String _highLatName(HighLatitudeRule r) {
    switch (r) {
      case HighLatitudeRule.middleOfNight:
        return 'منتصف الليل (Middle of Night)';
      case HighLatitudeRule.seventhOfNight:
        return 'سُبع الليل (One Seventh)';
      case HighLatitudeRule.angleBased:
        return 'الحساب المبني على الزاوية (Angle-Based)';
    }
  }

  String _themeName(AppThemeMode m) {
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

  String _accentName(AccentColor c) {
    switch (c) {
      case AccentColor.green:
        return 'زمردي سكينة';
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

  Color _accentColorValue(AccentColor c) {
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

  String _notificationModeName(NotificationMode m) {
    switch (m) {
      case NotificationMode.fullAdhan:
        return 'أذان كامل';
      case NotificationMode.shortBeep:
        return 'تنبيه قصير';
      case NotificationMode.silent:
        return 'إشعار صامت';
      case NotificationMode.vibrate:
        return 'اهتزاز فقط';
      case NotificationMode.off:
        return 'معطل';
    }
  }

  IconData _notificationModeIcon(NotificationMode m) {
    switch (m) {
      case NotificationMode.fullAdhan:
        return Icons.volume_up_rounded;
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

  String _prayerArabic(String key) {
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

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showPrayerAdjustmentDialog(
      BuildContext context, AppSettings settings, WidgetRef ref) {
    final prayers = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final tempAdjustments = Map<String, int>.from(settings.prayerAdjustments);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primary = Theme.of(context).colorScheme.primary;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor:
                  isDark ? AppColors.nightSurface : AppColors.daySurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                'تعديل دقائق الصلوات (-30 إلى +30)',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.nightTextPrimary
                      : AppColors.dayTextPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: prayers.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final pKey = prayers[index];
                    final current = tempAdjustments[pKey] ?? 0;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _prayerArabic(pKey),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.nightTextPrimary
                                : AppColors.dayTextPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: isDark
                                  ? AppColors.nightTextSecondary
                                  : AppColors.dayTextSecondary,
                              onPressed: current > -30
                                  ? () {
                                      setDialogState(() {
                                        tempAdjustments[pKey] = current - 1;
                                      });
                                    }
                                  : null,
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                current > 0
                                    ? '+$current د'
                                    : (current < 0 ? '$current د' : '0 د'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: current != 0
                                      ? primary
                                      : (isDark
                                          ? AppColors.nightTextSecondary
                                          : AppColors.dayTextSecondary),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: isDark
                                  ? AppColors.nightTextSecondary
                                  : AppColors.dayTextSecondary,
                              onPressed: current < 30
                                  ? () {
                                      setDialogState(() {
                                        tempAdjustments[pKey] = current + 1;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    for (final entry in tempAdjustments.entries) {
                      ref
                          .read(settingsNotifierProvider.notifier)
                          .setPrayerAdjustment(entry.key, entry.value);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ',
                      style: TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNotificationModePicker(
      BuildContext context, String prayerKey, NotificationMode current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurface : AppColors.daySurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'نوع تنبيه صلاة ${_prayerArabic(prayerKey)}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.nightTextPrimary
                      : AppColors.dayTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...NotificationMode.values.map((mode) {
                final isSelected = mode == current;
                return ListTile(
                  leading: Icon(
                    _notificationModeIcon(mode),
                    color: isSelected
                        ? primary
                        : (isDark
                            ? AppColors.nightTextSecondary
                            : AppColors.dayTextSecondary),
                  ),
                  title: Text(
                    _notificationModeName(mode),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? primary
                          : (isDark
                              ? AppColors.nightTextPrimary
                              : AppColors.dayTextPrimary),
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: primary)
                      : null,
                  onTap: () {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .setPrayerNotification(prayerKey, mode);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

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
            'الإعدادات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.nightTextPrimary
                  : AppColors.dayTextPrimary,
            ),
          ),
          actions: [
            // Quick permissions shortcut
            IconButton(
              icon: Icon(
                Icons.security_outlined,
                color: isDark
                    ? AppColors.nightSecondary
                    : AppColors.daySecondary,
              ),
              tooltip: 'فحص الأذونات',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PermissionCheckScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // ─── قسم الموقع والحساب ─────────────────────────────────────────
            _buildSectionHeader('الموقع وحساب المواقيت', Icons.public_outlined),

            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  // Calculation Method
                  ListTile(
                    title: const Text('طريقة الحساب الفلكي',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: Text(
                      _methodName(settings.calculationMethod),
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: primary,
                          fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final selected = await CalculationMethodSelector.show(
                        context,
                        selectedMethod: settings.calculationMethod,
                      );
                      if (selected != null) {
                        notifier.setCalculationMethod(selected);
                      }
                    },
                  ),
                  _divider(isDark),

                  // Madhab
                  ListTile(
                    title: const Text('المذهب الفقهي لحساب صلاة العصر',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: Text(
                      _madhabName(settings.madhab),
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: isDark
                              ? AppColors.nightTextSecondary
                              : AppColors.dayTextSecondary),
                    ),
                    trailing: DropdownButton<Madhab>(
                      value: settings.madhab,
                      underline: const SizedBox.shrink(),
                      dropdownColor: isDark
                          ? AppColors.nightElevated
                          : AppColors.daySurface,
                      items: Madhab.values.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            m == Madhab.shafi ? 'شافعي / مالكي' : 'حنفي',
                            style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) notifier.setMadhab(val);
                      },
                    ),
                  ),
                  _divider(isDark),

                  // High Latitude Rule
                  ListTile(
                    title: const Text('قاعدة خطوط العرض العليا',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: Text(
                      _highLatName(settings.highLatitudeRule),
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isDark
                              ? AppColors.nightTextSecondary
                              : AppColors.dayTextSecondary),
                    ),
                    trailing: DropdownButton<HighLatitudeRule>(
                      value: settings.highLatitudeRule,
                      underline: const SizedBox.shrink(),
                      dropdownColor: isDark
                          ? AppColors.nightElevated
                          : AppColors.daySurface,
                      items: HighLatitudeRule.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(
                            r == HighLatitudeRule.middleOfNight
                                ? 'منتصف الليل'
                                : (r == HighLatitudeRule.seventhOfNight
                                    ? 'سُبع الليل'
                                    : 'بالزاوية'),
                            style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) notifier.setHighLatitudeRule(val);
                      },
                    ),
                  ),
                  _divider(isDark),

                  // Per-prayer minute adjustments
                  ListTile(
                    title: const Text('تعديل دقائق الصلوات',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'إضافة أو خصم دقائق لمطابقة أذان المسجد المجاور',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    trailing: const Icon(Icons.tune, size: 20),
                    onTap: () =>
                        _showPrayerAdjustmentDialog(context, settings, ref),
                  ),
                  _divider(isDark),

                  // Hijri date adjustment (-2 to +2)
                  ListTile(
                    title: const Text('تعديل التقويم الهجري',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: Text(
                      'الإزاحة الحالية: ${settings.hijriOffset > 0 ? '+${settings.hijriOffset}' : settings.hijriOffset} يوم',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isDark
                              ? AppColors.nightTextSecondary
                              : AppColors.dayTextSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 22),
                          onPressed: settings.hijriOffset > -2
                              ? () => notifier
                                  .setHijriOffset(settings.hijriOffset - 1)
                              : null,
                        ),
                        Text(
                          '${settings.hijriOffset}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 22),
                          onPressed: settings.hijriOffset < 2
                              ? () => notifier
                                  .setHijriOffset(settings.hijriOffset + 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── قسم التنبيهات والأذان ─────────────────────────────────────
            _buildSectionHeader('التنبيهات والأذان', Icons.notifications_active_outlined),

            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  // Dedicated Permissions Screen entry
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified_user_outlined,
                          color: primary, size: 22),
                    ),
                    title: const Text(
                      'فحص أذونات الأذان والعمل في الخلفية',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'التأكد من دقة المنبه وعدم إيقاف النظام للأذان',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PermissionCheckScreen(),
                        ),
                      );
                    },
                  ),
                  _divider(isDark),

                  // Per-prayer notification mode
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'نوع التنبيه لكل صلاة:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.nightSecondary
                              : AppColors.daySecondary,
                        ),
                      ),
                    ),
                  ),

                  ...['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']
                      .map((pKey) {
                    final currentMode = settings.prayerNotifications[pKey] ??
                        NotificationMode.fullAdhan;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        _notificationModeIcon(currentMode),
                        color: currentMode == NotificationMode.off
                            ? (isDark
                                ? AppColors.nightTextSecondary
                                : AppColors.dayTextSecondary)
                            : primary,
                        size: 20,
                      ),
                      title: Text(
                        _prayerArabic(pKey),
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.nightElevated
                              : const Color(0xFFF0EFEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _notificationModeName(currentMode),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: currentMode == NotificationMode.off
                                ? (isDark
                                    ? AppColors.nightTextSecondary
                                    : AppColors.dayTextSecondary)
                                : primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => _showNotificationModePicker(
                          context, pKey, currentMode),
                    );
                  }),
                  _divider(isDark),

                  // Adhan sound selection
                  ListTile(
                    title: const Text('صوت الأذان',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: Text(
                      adhanSoundName(settings.selectedAdhanSound),
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: primary,
                          fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.music_note, size: 20),
                    onTap: () async {
                      final selected = await SoundSelectorSheet.show(
                        context,
                        selectedSoundId: settings.selectedAdhanSound,
                        initialVolume: settings.adhanVolume,
                      );
                      if (selected != null) {
                        notifier.setAdhanSound(selected);
                      }
                    },
                  ),
                  _divider(isDark),

                  // Volume slider
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('مستوى صوت الأذان',
                                style: TextStyle(
                                    fontFamily: 'Cairo', fontSize: 15)),
                            Text('${(settings.adhanVolume * 100).toInt()}%',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primary)),
                          ],
                        ),
                        Slider(
                          value: settings.adhanVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          activeColor: primary,
                          inactiveColor: isDark
                              ? AppColors.nightElevated
                              : const Color(0xFFE2EBE7),
                          onChanged: (v) => notifier.setAdhanVolume(v),
                        ),
                      ],
                    ),
                  ),
                  _divider(isDark),

                  // Gradual volume option
                  SwitchListTile(
                    title: const Text('تصاعد صوت الأذان تدريجياً',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'يبدأ الصوت منخفضاً ثم يرتفع برفق لمنع الإفزاع',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.gradualVolume,
                    activeColor: primary,
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(gradualVolume: v)),
                  ),
                  _divider(isDark),

                  // Pre-adhan reminder
                  ListTile(
                    title: const Text('تنبيه ما قبل الأذان',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: Text(
                      settings.preAdhanReminderMinutes == 0
                          ? 'معطل'
                          : 'قبل الأذان بـ ${settings.preAdhanReminderMinutes} دقائق',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isDark
                              ? AppColors.nightTextSecondary
                              : AppColors.dayTextSecondary),
                    ),
                    trailing: DropdownButton<int>(
                      value: settings.preAdhanReminderMinutes,
                      underline: const SizedBox.shrink(),
                      dropdownColor: isDark
                          ? AppColors.nightElevated
                          : AppColors.daySurface,
                      items: const [0, 5, 10, 15, 20, 30].map((mins) {
                        return DropdownMenuItem(
                          value: mins,
                          child: Text(
                            mins == 0 ? 'معطل' : '$mins دقائق',
                            style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          notifier.update(
                              (s) => s.copyWith(preAdhanReminderMinutes: val));
                        }
                      },
                    ),
                  ),
                  _divider(isDark),

                  // Iqama reminder
                  SwitchListTile(
                    title: const Text('تذكير موعد الإقامة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'تنبيه لطيف بعد الأذان بحوالي ١٥ دقيقة',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.iqamaReminder,
                    activeColor: primary,
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(iqamaReminder: v)),
                  ),
                  _divider(isDark),

                  // Morning & Evening Azkar reminders
                  SwitchListTile(
                    title: const Text('تذكير أذكار الصباح',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text('بعد طلوع الفجر والشروق',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    value: settings.morningAzkarReminder,
                    activeColor: primary,
                    onChanged: (v) => notifier
                        .update((s) => s.copyWith(morningAzkarReminder: v)),
                  ),
                  _divider(isDark),

                  SwitchListTile(
                    title: const Text('تذكير أذكار المساء',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text('بعد صلاة العصر وحتى الغروب',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    value: settings.eveningAzkarReminder,
                    activeColor: primary,
                    onChanged: (v) => notifier
                        .update((s) => s.copyWith(eveningAzkarReminder: v)),
                  ),
                  _divider(isDark),

                  // Friday reminders
                  SwitchListTile(
                    title: const Text('تذكيرات يوم الجمعة المباركة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'الصلاة على النبي ﷺ وقراءة سورة الكهف وساعة الإجابة',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.fridayReminder,
                    activeColor: primary,
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(fridayReminder: v)),
                  ),
                  _divider(isDark),

                  // Fasting reminders
                  SwitchListTile(
                    title: const Text('تذكير صيام التطوع',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'صيام الإثنين والخميس والأيام البيض (١٣، ١٤، ١٥)',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.fastingReminder,
                    activeColor: primary,
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(fastingReminder: v)),
                  ),
                  _divider(isDark),

                  // Test audio button
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(_isTestingAudio ? Icons.stop : Icons.play_arrow),
                      label: Text(
                        _isTestingAudio ? 'إيقاف تجربة الأذان' : 'تجربة صوت الأذان الآن',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        if (_isTestingAudio) {
                          await AlarmBridge.stopTestAdhan();
                          setState(() => _isTestingAudio = false);
                        } else {
                          setState(() => _isTestingAudio = true);
                          try {
                            await AlarmBridge.testAdhan(
                              soundId: settings.selectedAdhanSound,
                              volume: settings.adhanVolume,
                            );
                          } catch (_) {
                            setState(() => _isTestingAudio = false);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ─── قسم المظهر والسمات ─────────────────────────────────────────
            _buildSectionHeader('المظهر والسمات', Icons.palette_outlined),

            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  // Theme Mode
                  ListTile(
                    title: const Text('السمة / المظهر',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: Text(
                      _themeName(settings.themeMode),
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: primary,
                          fontWeight: FontWeight.w600),
                    ),
                    trailing: DropdownButton<AppThemeMode>(
                      value: settings.themeMode,
                      underline: const SizedBox.shrink(),
                      dropdownColor: isDark
                          ? AppColors.nightElevated
                          : AppColors.daySurface,
                      items: AppThemeMode.values.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            _themeName(m),
                            style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) notifier.setThemeMode(val);
                      },
                    ),
                  ),
                  _divider(isDark),

                  // Accent Color
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('اللون المميز (Accent Color)',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: AccentColor.values.map((acc) {
                            final cv = _accentColorValue(acc);
                            final isSel = settings.accentColor == acc;
                            return GestureDetector(
                              onTap: () => notifier.update(
                                  (s) => s.copyWith(accentColor: acc)),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: cv,
                                  shape: BoxShape.circle,
                                  border: isSel
                                      ? Border.all(
                                          color: Colors.white, width: 2.5)
                                      : null,
                                ),
                                child: isSel
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.black)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  _divider(isDark),

                  // Font Size
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('حجم خط واجهة التطبيق',
                                style: TextStyle(
                                    fontFamily: 'Cairo', fontSize: 15)),
                            Text('${(settings.fontSize * 100).toInt()}%',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primary)),
                          ],
                        ),
                        Slider(
                          value: settings.fontSize,
                          min: 0.8,
                          max: 1.4,
                          divisions: 6,
                          activeColor: primary,
                          inactiveColor: isDark
                              ? AppColors.nightElevated
                              : const Color(0xFFE2EBE7),
                          onChanged: (v) =>
                              notifier.update((s) => s.copyWith(fontSize: v)),
                        ),
                      ],
                    ),
                  ),
                  _divider(isDark),

                  // Numeral Type (Arabic vs Western)
                  ListTile(
                    title: const Text('نوع الأرقام',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: Text(
                      settings.numeralType == NumeralType.arabic
                          ? 'أرقام مشرقية عربية (١ ٢ ٣ ٤ ٥)'
                          : 'أرقام مغربية لاتينية (1 2 3 4 5)',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isDark
                              ? AppColors.nightTextSecondary
                              : AppColors.dayTextSecondary),
                    ),
                    trailing: DropdownButton<NumeralType>(
                      value: settings.numeralType,
                      underline: const SizedBox.shrink(),
                      dropdownColor: isDark
                          ? AppColors.nightElevated
                          : AppColors.daySurface,
                      items: const [
                        DropdownMenuItem(
                            value: NumeralType.arabic,
                            child: Text('عربية (١٢٣)',
                                style: TextStyle(fontFamily: 'Cairo'))),
                        DropdownMenuItem(
                            value: NumeralType.western,
                            child: Text('لاتينية (123)',
                                style: TextStyle(fontFamily: 'Cairo'))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          notifier
                              .update((s) => s.copyWith(numeralType: val));
                        }
                      },
                    ),
                  ),
                  _divider(isDark),

                  // Language
                  ListTile(
                    title: const Text('لغة التطبيق',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: Text(
                      settings.languageCode == 'ar'
                          ? 'العربية'
                          : (settings.languageCode == 'en'
                              ? 'English'
                              : 'Türkçe'),
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: primary,
                          fontWeight: FontWeight.w600),
                    ),
                    trailing: DropdownButton<String>(
                      value: settings.languageCode,
                      underline: const SizedBox.shrink(),
                      dropdownColor: isDark
                          ? AppColors.nightElevated
                          : AppColors.daySurface,
                      items: const [
                        DropdownMenuItem(
                            value: 'ar',
                            child: Text('العربية',
                                style: TextStyle(fontFamily: 'Cairo'))),
                        DropdownMenuItem(
                            value: 'en',
                            child: Text('English',
                                style: TextStyle(fontFamily: 'Cairo'))),
                        DropdownMenuItem(
                            value: 'tr',
                            child: Text('Türkçe',
                                style: TextStyle(fontFamily: 'Cairo'))),
                      ],
                      onChanged: (val) {
                        if (val != null) notifier.setLanguage(val);
                      },
                    ),
                  ),
                  _divider(isDark),

                  // Background Decoration Toggle
                  SwitchListTile(
                    title: const Text('الزخارف الإسلامية في الخلفية',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'نقوش هندسية إسلامية هادئة في خلفيات الشاشات',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.showBackgroundDecoration,
                    activeColor: primary,
                    onChanged: (v) => notifier.update(
                        (s) => s.copyWith(showBackgroundDecoration: v)),
                  ),
                  _divider(isDark),

                  // Tap sound
                  SwitchListTile(
                    title: const Text('صوت النقر',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'صوت خفيف عند الضغط على الأزرار',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.tapSound,
                    activeColor: primary,
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(tapSound: v)),
                  ),
                  _divider(isDark),

                  // Tap haptic
                  SwitchListTile(
                    title: const Text('الاهتزاز عند النقر',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'اهتزاز خفيف عند الضغط على الأزرار',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.tapHaptic,
                    activeColor: primary,
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(tapHaptic: v)),
                  ),
                  _divider(isDark),

                  // Persistent next-prayer notification
                  SwitchListTile(
                    title: const Text('إشعار دائم للصلاة القادمة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'يعرض الصلاة القادمة والوقت المتبقي مع شريط تقدّم',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.persistentNotification,
                    activeColor: primary,
                    onChanged: (v) => notifier
                        .update((s) => s.copyWith(persistentNotification: v)),
                  ),
                ],
              ),
            ),

            // ─── قسم الأذكار ───────────────────────────────────────────────
            _buildSectionHeader('الأذكار والتسبيح', Icons.auto_stories_outlined),

            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  // Azkar font size
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('حجم خط نصوص الأذكار',
                                style: TextStyle(
                                    fontFamily: 'Cairo', fontSize: 15)),
                            Text('${(settings.azkarFontSize * 100).toInt()}%',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primary)),
                          ],
                        ),
                        Slider(
                          value: settings.azkarFontSize,
                          min: 0.8,
                          max: 1.6,
                          divisions: 8,
                          activeColor: primary,
                          inactiveColor: isDark
                              ? AppColors.nightElevated
                              : const Color(0xFFE2EBE7),
                          onChanged: (v) => notifier
                              .update((s) => s.copyWith(azkarFontSize: v)),
                        ),
                      ],
                    ),
                  ),
                  _divider(isDark),

                  // Tashkeel
                  SwitchListTile(
                    title: const Text('إظهار التشكيل والحركات',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'عرض الحركات الإعرابية الكاملة على نصوص الأذكار',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.showTashkeel,
                    activeColor: primary,
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(showTashkeel: v)),
                  ),
                  _divider(isDark),

                  // Show virtue and source
                  SwitchListTile(
                    title: const Text('إظهار فضل الذكر وتخريجه',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'بيان فضل الحديث ومصدره من كتب السنة المعتمدة',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.showVirtueAndSource,
                    activeColor: primary,
                    onChanged: (v) => notifier
                        .update((s) => s.copyWith(showVirtueAndSource: v)),
                  ),
                  _divider(isDark),

                  // Azkar Vibration
                  SwitchListTile(
                    title: const Text('الاهتزاز عند الضغط على العداد',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'نبضة اهتزاز خفيفة عند كل تسبيحة واهتزاز أطول عند اكتمال العدد',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.azkarVibration,
                    activeColor: primary,
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(azkarVibration: v)),
                  ),
                  _divider(isDark),

                  // Auto advance
                  SwitchListTile(
                    title: const Text('الانتقال التلقائي للذكر التالي',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'التمرير التلقائي إلى الذكر التالي فور اكتمال التكرارات المطلوبة',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.autoAdvanceAzkar,
                    activeColor: primary,
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(autoAdvanceAzkar: v)),
                  ),
                  _divider(isDark),

                  // Keep screen on
                  SwitchListTile(
                    title: const Text('إبقاء الشاشة مضاءة أثناء القراءة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'منع قفل الهاتف تلقائياً أثناء تصفح الأذكار والأوراد',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.keepScreenOnAzkar,
                    activeColor: primary,
                    onChanged: (v) => notifier
                        .update((s) => s.copyWith(keepScreenOnAzkar: v)),
                  ),
                ],
              ),
            ),

            // ─── قسم القبلة ───────────────────────────────────────────────
            _buildSectionHeader('بوصلة القبلة', Icons.explore_outlined),

            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  // Distance unit
                  ListTile(
                    title: const Text('وحدة قياس المسافة إلى مكة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: Text(
                      settings.distanceInKm
                          ? 'كيلومتر (كم)'
                          : 'ميل (Mile)',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: isDark
                              ? AppColors.nightTextSecondary
                              : AppColors.dayTextSecondary),
                    ),
                    trailing: DropdownButton<bool>(
                      value: settings.distanceInKm,
                      underline: const SizedBox.shrink(),
                      dropdownColor: isDark
                          ? AppColors.nightElevated
                          : AppColors.daySurface,
                      items: const [
                        DropdownMenuItem(
                            value: true,
                            child: Text('كيلومتر (كم)',
                                style: TextStyle(fontFamily: 'Cairo'))),
                        DropdownMenuItem(
                            value: false,
                            child: Text('ميل (mi)',
                                style: TextStyle(fontFamily: 'Cairo'))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          notifier
                              .update((s) => s.copyWith(distanceInKm: val));
                        }
                      },
                    ),
                  ),
                  _divider(isDark),

                  // Vibration on align
                  SwitchListTile(
                    title: const Text('الاهتزاز عند محاذاة الكعبة المشرفة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text(
                      'إشعار بالاهتزاز اللمسي الدقيق عند الوصول لاتجاه القبلة الصحيح',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    value: settings.qiblaAlignVibration,
                    activeColor: primary,
                    onChanged: (v) => notifier
                        .update((s) => s.copyWith(qiblaAlignVibration: v)),
                  ),
                ],
              ),
            ),

            // ─── قسم الشاشة الدائمة (AOD) ──────────────────────────────────
            _buildSectionHeader('الشاشة الدائمة (AOD)', Icons.screen_lock_portrait_outlined),

            _buildCard(
              isDark: isDark,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (settings.aodEnabled ? primary : Colors.grey)
                        .withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android,
                    color: settings.aodEnabled ? primary : Colors.grey,
                  ),
                ),
                title: const Text(
                  'إعدادات الشاشة الدائمة (Always-On Display)',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  settings.aodEnabled
                      ? 'مفعلة (${settings.aodWhenToShow == 'adhan' ? 'حول وقت الأذان' : 'دائماً'})'
                      : 'معطلة - اضغط للضبط والمعاينة',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: settings.aodEnabled
                          ? primary
                          : (isDark
                              ? AppColors.nightTextSecondary
                              : AppColors.dayTextSecondary)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AodSettingsScreen(),
                    ),
                  );
                },
              ),
            ),

            // ─── قسم النسخ والبيانات ───────────────────────────────────────
            _buildSectionHeader('البيانات والنسخ الاحتياطي', Icons.save_outlined),

            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  // Export JSON
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: const Text('تصدير الإعدادات (نسخة احتياطية)',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text('حفظ الإعدادات كملف نصي JSON',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    onTap: () {
                      final jsonStr = notifier.exportJson();
                      Clipboard.setData(ClipboardData(text: jsonStr));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تم نسخ بيانات الإعدادات إلى الحافظة بنجاح',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      );
                    },
                  ),
                  _divider(isDark),

                  // Import JSON
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('استعادة الإعدادات من نص JSON',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    subtitle: const Text('لصق إعدادات سابقة واستعادتها',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    onTap: () => _showImportJsonDialog(context, notifier),
                  ),
                  _divider(isDark),

                  // Reset
                  ListTile(
                    leading: const Icon(Icons.restore, color: AppColors.error),
                    title: const Text(
                      'إعادة تعيين الإعدادات للافتراضية',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          color: AppColors.error,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'استعادة جميع قيم الإعدادات إلى وضع المصنع',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    onTap: () => _showResetDialog(context, notifier),
                  ),
                ],
              ),
            ),

            // ─── حول التطبيق ───────────────────────────────────────────────
            _buildSectionHeader('حول التطبيق', Icons.info_outline),

            _buildCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, primary.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'س',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سكينة | Sakina',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.nightTextPrimary
                                    : AppColors.dayTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'الإصدار 1.0.0 (Build 1)',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.nightTextSecondary
                                    : AppColors.dayTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'تطبيق إسلامي مفتوح ومستقل، بدون إعلانات وبدون تتبع، صُمم بعناية ليعين المسلم على ذكر الله وإقامة الصلاة في أوقاتها بسكينة وطمأنينة.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? AppColors.nightTextSecondary
                            : AppColors.dayTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.nightSecondary
                                : AppColors.daySecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showImportJsonDialog(
      BuildContext context, SettingsNotifier notifier) {
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor:
              isDark ? AppColors.nightSurface : AppColors.daySurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('استعادة الإعدادات',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'الصق نص الـ JSON الخاص بالإعدادات السابقة هنا:',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '{"calculationMethod": "ummAlQura", ...}',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.nightElevated
                      : const Color(0xFFF0EFEA),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  try {
                    await notifier.importJson(text);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم استعادة الإعدادات بنجاح',
                              style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('صيغة الـ JSON غير صالحة',
                              style: TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('استعادة',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsNotifier notifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor:
              isDark ? AppColors.nightSurface : AppColors.daySurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('تأكيد إعادة التعيين',
                  style: TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في إعادة ضبط جميع الإعدادات إلى قيمها الافتراضية الأصلية؟ لا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await notifier.reset();
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت إعادة تعيين الإعدادات للافتراضية',
                          style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  );
                }
              },
              child: const Text('إعادة التعيين الآن',
                  style: TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.nightPrimary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.nightPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
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

  Widget _divider(bool isDark) {
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
}
