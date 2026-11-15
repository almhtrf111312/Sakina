import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/settings/settings_repository.dart';
import '../widgets/settings_common.dart';

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return SettingsPageScaffold(
      title: 'المظهر والسمات',
      children: [
        buildSettingsCard(
          isDark: isDark,
          child: Column(
            children: [
              // Theme Mode
              ListTile(
                title: const Text('السمة / المظهر',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: Text(
                  themeName(settings.themeMode),
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
                        themeName(m),
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
              settingsDivider(isDark),

              ListTile(
                title: const Text('نظام عرض الوقت', style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: const Text('ينطبق على التطبيق والشاشة الدائمة والودجات والإشعار',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: ChoiceChip(
                    label: const Center(child: Text('12 ساعة · صباحاً/مساءً', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                    selected: !settings.use24HourTime,
                    onSelected: (_) => notifier.update((s) => s.copyWith(use24HourTime: false)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ChoiceChip(
                    label: const Center(child: Text('24 ساعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                    selected: settings.use24HourTime,
                    onSelected: (_) => notifier.update((s) => s.copyWith(use24HourTime: true)),
                  )),
                ]),
              ),
              settingsDivider(isDark),

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
                        final cv = accentColorValue(acc);
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
              settingsDivider(isDark),

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
                          : AppColors.dayChipStrong,
                      onChanged: (v) =>
                          notifier.update((s) => s.copyWith(fontSize: v)),
                    ),
                  ],
                ),
              ),
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              if (settings.tapSound)
                ListTile(
                  title: const Text('مستوى صوت النقر', style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                  subtitle: Slider(
                    value: settings.tapVolume,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: '${(settings.tapVolume * 100).round()}%',
                    onChanged: (v) => notifier.update((s) => s.copyWith(tapVolume: v)),
                  ),
                ),
              settingsDivider(isDark),

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
              if (settings.tapHaptic)
                ListTile(
                  title: const Text('قوة الاهتزاز', style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                  subtitle: Slider(
                    value: settings.tapHapticIntensity,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: '${(settings.tapHapticIntensity * 100).round()}%',
                    onChanged: (v) => notifier.update((s) => s.copyWith(tapHapticIntensity: v)),
                  ),
                ),
              settingsDivider(isDark),

              ListTile(
                title: const Text('خلفية ودجات الشاشة الرئيسية',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الشفافية: ${(settings.widgetOpacity * 100).round()}%',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    Slider(
                      value: settings.widgetOpacity,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      onChanged: (v) => notifier.update((s) => s.copyWith(widgetOpacity: v)),
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
