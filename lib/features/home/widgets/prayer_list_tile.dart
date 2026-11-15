// lib/features/home/widgets/prayer_list_tile.dart
// Prayer list item widget with 3-state bell toggle (full adhan, silent/vibrate, off).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';

import '../../../core/utils/prayer_icons.dart';
import '../../../data/settings/settings_repository.dart';
import '../providers/home_providers.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          // ── Prayer Icon ──
          Container(
            padding: const EdgeInsets.all(10),
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
          const SizedBox(width: 14),

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
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.nightTextPrimary
                  : AppColors.dayTextPrimary,
            ),
          ),
          const SizedBox(width: 12),

          // ── Bell Icon (3 states: fullAdhan, silent, off) ──
          _buildBellButton(context, ref, notificationMode, isDark),
        ],
      ),
    );
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
        tooltip = 'أذان';
        break;
      case NotificationMode.silent:
      case NotificationMode.vibrate:
        icon = Icons.notifications_rounded;
        iconColor = isDark
            ? AppColors.nightPrimary // Primary teal
            : AppColors.dayPrimary;
        tooltip = 'تنبيه صامت / اهتزاز';
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
        // Cycle: short alert -> silent -> off -> short alert
        NotificationMode nextMode;
        if (mode == NotificationMode.shortBeep) {
          nextMode = NotificationMode.silent;
        } else if (mode == NotificationMode.silent ||
            mode == NotificationMode.vibrate) {
          nextMode = NotificationMode.off;
        } else {
          nextMode = NotificationMode.shortBeep;
        }

        ref
            .read(settingsNotifierProvider.notifier)
            .setPrayerNotification(prayerName, nextMode);

        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تعيين تنبيه $prayerName إلى: ${_modeLabel(nextMode)}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  String _modeLabel(NotificationMode mode) {
    switch (mode) {
      case NotificationMode.silent:
        return 'صامت';
      case NotificationMode.vibrate:
        return 'اهتزاز';
      case NotificationMode.shortBeep:
        return 'أذان';
      case NotificationMode.off:
        return 'إيقاف';
    }
  }
}
