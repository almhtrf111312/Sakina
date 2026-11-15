import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/settings/settings_repository.dart';
import '../widgets/settings_common.dart';

class AzkarSettingsPage extends ConsumerWidget {
  const AzkarSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return SettingsPageScaffold(
      title: 'الأذكار والتسبيح',
      children: [
        buildSettingsCard(
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
                          : AppColors.dayChipStrong,
                      onChanged: (v) => notifier
                          .update((s) => s.copyWith(azkarFontSize: v)),
                    ),
                  ],
                ),
              ),
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
      ],
    );
  }
}
