// lib/features/home/widgets/prayer_list_tile.dart
// Prayer list item widget with 3-state bell toggle (full adhan, silent/vibrate, off).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';

import '../../../core/utils/prayer_icons.dart';
import '../../../data/settings/settings_repository.dart';
import '../providers/home_providers.dart';
import '../../settings/widgets/settings_common.dart';
import '../../../core/theme/app_colors.dart';

class PrayerListTile extends ConsumerWidget {
  final String prayerName;
  final DateTime prayerTime;
  final bool isNext;

  const PrayerListTile({
    super.key,
    required this.prayerName,
    required this.prayerTime,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(appSettingsProvider);

    final notificationMode = settings.prayerNotifications[prayerName] ??
        NotificationMode.shortBeep;

    final arabicName = getPrayerArabicName(prayerName);
    final formattedTime = AppDateUtils.formatPrayerTime(prayerTime.toLocal(),
        is24Hour: settings.use24HourTime, languageCode: settings.languageCode);

    // Highlight styles if this prayer is the next upcoming prayer
    final cardBg = isNext
        ? (isDark
            ? AppColors.nightElevated
            : AppColors.dayChip)
        : (isDark
            ? AppColors.nightSurface
            : AppColors.daySurface);

    final borderColor = isNext
        ? (isDark
            ? AppColors.nightPrimary
            : AppColors.dayPrimary)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: isNext ? 1.5 : 0.5,
        ),
        boxShadow: [
          if (isNext)
            BoxShadow(
              color: isDark
                  ? AppColors.nightPrimary.withOpacity(0.12)
                  : AppColors.dayPrimary.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _adjustTime(context, ref, settings),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // ── Prayer Icon ──
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isNext
                        ? (isDark
                            ? AppColors.nightPrimary.withOpacity(0.2)
                            : AppColors.dayPrimary.withOpacity(0.15))
                        : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.04)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PrayerIcons.getIcon(prayerName),
                    size: 20,
                    color: isNext
                        ? (isDark
                            ? AppColors.nightPrimary
                            : AppColors.dayPrimary)
                        : (isDark
                            ? AppColors.nightTextSecondary
                            : AppColors.dayTextSecondary),
                  ),
                ),
                const SizedBox(width: 8),

                // ── Prayer Arabic Name + (القادمة badge if next) ──
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        arabicName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Cairo',
                          fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                          color: isDark
                              ? AppColors.nightTextPrimary
                              : AppColors.dayTextPrimary,
                        ),
                      ),
                      if (isNext) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.nightPrimary.withOpacity(0.2)
                                : AppColors.dayPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'القادمة',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.nightPrimary
                                  : AppColors.dayPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Time Text ──
                Text(
                  formattedTime,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.nightTextPrimary
                        : AppColors.dayTextPrimary,
                  ),
                ),
                const SizedBox(width: 4),

                // ── Bell Icon (3 states: fullAdhan, silent, off) ──
                _buildBellButton(context, ref, notificationMode, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _adjustTime(BuildContext context, WidgetRef ref,
      AppSettings settings) async {
    final original = settings.prayerAdjustments[prayerName] ?? 0;
    var minutes = original.clamp(-30, 30);
    final applied = await showDialog<int>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setDialogState) {
          final adjusted = prayerTime.add(Duration(minutes: minutes - original));
          final time = AppDateUtils.formatPrayerTime(adjusted.toLocal(),
              is24Hour: settings.use24HourTime, languageCode: settings.languageCode);
          return AlertDialog(
            title: Text('تعديل وقت ${getPrayerArabicName(prayerName)}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'إنقاص دقيقة',
                      onPressed: minutes <= -30 ? null
                          : () => setDialogState(() => minutes--),
                    ),
                    Text('${minutes > 0 ? '+' : ''}$minutes د'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'إضافة دقيقة',
                      onPressed: minutes >= 30 ? null
                          : () => setDialogState(() => minutes++),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialog),
                child: const Text('إلغاء')),
              TextButton(
                onPressed: minutes == 0 ? null : () => setDialogState(() => minutes = 0),
                child: const Text('إعادة الضبط'),
              ),
              FilledButton(onPressed: () => Navigator.pop(dialog, minutes),
                child: const Text('حفظ')),
            ],
          );
        },
      ),
    );
    if (context.mounted && applied != null && applied != original) {
      await ref.read(settingsNotifierProvider.notifier)
          .setPrayerAdjustment(prayerName, applied);
    }
  }

  Widget _buildBellButton(BuildContext context, WidgetRef ref,
      NotificationMode mode, bool isDark) {
    IconData icon;
    Color iconColor;
    String tooltip;

    switch (mode) {
      case NotificationMode.shortBeep:
        icon = Icons.notifications_active_rounded;
        iconColor = isDark
            ? AppColors.nightSecondary // Gold
            : AppColors.daySecondary;
        tooltip = 'تكبيرة فقط';
        break;
      case NotificationMode.fullAdhan:
        icon = Icons.mosque_outlined;
        iconColor = Theme.of(context).colorScheme.primary;
        tooltip = 'أذان كامل';
        break;
      case NotificationMode.vibrate:
        icon = Icons.notifications_rounded;
        iconColor = isDark
            ? AppColors.nightPrimary // Primary teal
            : AppColors.dayPrimary;
        tooltip = 'اهتزاز فقط';
        break;
      case NotificationMode.off:
        icon = Icons.notifications_off_outlined;
        iconColor = isDark
            ? AppColors.nightTextSecondary.withOpacity(0.4)
            : AppColors.dayTextSecondary.withOpacity(0.4);
        tooltip = 'معطل';
        break;
    }

    return IconButton(
      icon: Icon(icon, color: iconColor, size: 22),
      tooltip: tooltip,
      onPressed: () {
        final modes = NotificationMode.values;
        final nextMode = modes[(mode.index + 1) % modes.length];
        ref.read(settingsNotifierProvider.notifier)
            .setPrayerNotification(prayerName, nextMode);
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('${getPrayerArabicName(prayerName)} · ${notificationModeName(nextMode)}'),
            duration: const Duration(milliseconds: 1500),
          ));
      },
    );
  }
}
