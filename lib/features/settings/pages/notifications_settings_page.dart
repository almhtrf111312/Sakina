import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/alarm_bridge.dart';
import '../../../data/settings/settings_repository.dart';
import '../widgets/permission_check_screen.dart';
import '../widgets/settings_common.dart';
import '../widgets/sound_selector_sheet.dart';

class NotificationsSettingsPage extends ConsumerStatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  ConsumerState<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends ConsumerState<NotificationsSettingsPage> {
  bool _isTestingAudio = false;

  @override
  void dispose() {
    if (_isTestingAudio) {
      AlarmBridge.stopTestAdhan();
    }
    super.dispose();
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
                'نوع تنبيه صلاة ${prayerArabic(prayerKey)}',
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
                    notificationModeIcon(mode),
                    color: isSelected
                        ? primary
                        : (isDark
                            ? AppColors.nightTextSecondary
                            : AppColors.dayTextSecondary),
                  ),
                  title: Text(
                    notificationModeName(mode),
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return SettingsPageScaffold(
      title: 'التنبيهات والأذان',
      children: [
        buildSettingsCard(
          isDark: isDark,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('إظهار الصلاة القادمة في شريط الإشعارات',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: const Text('الصلاة ووقتها والمتبقي ظاهرة مباشرة وتتحدث باستمرار',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                value: settings.persistentNotification,
                activeColor: primary,
                onChanged: (v) => notifier.update(
                    (s) => s.copyWith(persistentNotification: v)),
              ),
              settingsDivider(isDark),
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
              settingsDivider(isDark),

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
                    NotificationMode.shortBeep;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    notificationModeIcon(currentMode),
                    color: currentMode == NotificationMode.off
                        ? (isDark
                            ? AppColors.nightTextSecondary
                            : AppColors.dayTextSecondary)
                        : primary,
                    size: 20,
                  ),
                  title: Text(
                    prayerArabic(pKey),
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
                          : AppColors.dayChip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notificationModeName(currentMode),
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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
                          : AppColors.dayChipStrong,
                      onChanged: (v) => notifier.setAdhanVolume(v),
                    ),
                  ],
                ),
              ),
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
              settingsDivider(isDark),

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
      ],
    );
  }
}
