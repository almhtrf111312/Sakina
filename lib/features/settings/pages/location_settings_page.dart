import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/prayer/prayer_calculator.dart';
import '../../../data/settings/settings_repository.dart';
import '../widgets/calculation_method_selector.dart';
import '../widgets/settings_common.dart';

class LocationSettingsPage extends ConsumerWidget {
  const LocationSettingsPage({super.key});

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
                          prayerArabic(pKey),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return SettingsPageScaffold(
      title: 'الموقع وحساب المواقيت',
      children: [
        buildSettingsCard(
          isDark: isDark,
          child: Column(
            children: [
              // Calculation Method
              ListTile(
                title: const Text('طريقة الحساب الفلكي',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: Text(
                  methodName(settings.calculationMethod),
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
              settingsDivider(isDark),

              // Madhab
              ListTile(
                title: const Text('المذهب الفقهي لحساب صلاة العصر',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: Text(
                  madhabName(settings.madhab),
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
              settingsDivider(isDark),

              // High Latitude Rule
              ListTile(
                title: const Text('قاعدة خطوط العرض العليا',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: Text(
                  highLatName(settings.highLatitudeRule),
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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
      ],
    );
  }
}
