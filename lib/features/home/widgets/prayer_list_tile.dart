// lib/features/home/widgets/prayer_list_tile.dart
// Prayer list item widget with 3-state bell toggle (full adhan, silent/vibrate, off).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/prayer_icons.dart';
import '../../../data/settings/settings_repository.dart';
import '../providers/home_providers.dart';

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
        NotificationMode.fullAdhan;

    final arabicName = getPrayerArabicName(prayerName);
    final timeFormat = DateFormat('hh:mm a', 'ar');
    final formattedTime = timeFormat.format(prayerTime.toLocal());

    // Highlight styles if this prayer is the next upcoming prayer
    final cardBg = isNext
        ? (isDark
            ? const Color(0xFF1D2B28)
            : const Color(0xFFE9F5F1))
        : (isDark
            ? const Color(0xFF16211F)
            : Colors.white);

    final borderColor = isNext
        ? (isDark
            ? const Color(0xFF5FB59B)
            : const Color(0xFF2F7F69))
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
                  ? const Color(0xFF5FB59B).withOpacity(0.12)
                  : const Color(0xFF2F7F69).withOpacity(0.08),
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
                      ? const Color(0xFF5FB59B).withOpacity(0.2)
                      : const Color(0xFF2F7F69).withOpacity(0.15))
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
                      ? const Color(0xFF5FB59B)
                      : const Color(0xFF2F7F69))
                  : (isDark
                      ? const Color(0xFF9DB0AA)
                      : const Color(0xFF607068)),
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
                        ? const Color(0xFFE8EFEC)
                        : const Color(0xFF1B2A27),
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF5FB59B).withOpacity(0.2)
                          : const Color(0xFF2F7F69).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'القادمة',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: isDark
                            ? const Color(0xFF5FB59B)
                            : const Color(0xFF2F7F69),
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
                  ? const Color(0xFFE8EFEC)
                  : const Color(0xFF1B2A27),
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
      case NotificationMode.fullAdhan:
        icon = Icons.notifications_active_rounded;
        iconColor = isDark
            ? const Color(0xFFC9A86A) // Gold
            : const Color(0xFFA9884A);
        tooltip = 'أذان كامل';
        break;
      case NotificationMode.silent:
      case NotificationMode.vibrate:
      case NotificationMode.shortBeep:
        icon = Icons.notifications_rounded;
        iconColor = isDark
            ? const Color(0xFF5FB59B) // Primary teal
            : const Color(0xFF2F7F69);
        tooltip = 'تنبيه صامت / اهتزاز';
        break;
      case NotificationMode.off:
        icon = Icons.notifications_off_outlined;
        iconColor = isDark
            ? const Color(0xFF9DB0AA).withOpacity(0.4)
            : const Color(0xFF607068).withOpacity(0.4);
        tooltip = 'معطل';
        break;
    }

    return IconButton(
      icon: Icon(icon, color: iconColor, size: 22),
      tooltip: tooltip,
      onPressed: () {
        // Cycle: fullAdhan -> silent -> off -> fullAdhan
        NotificationMode nextMode;
        if (mode == NotificationMode.fullAdhan) {
          nextMode = NotificationMode.silent;
        } else if (mode == NotificationMode.silent ||
            mode == NotificationMode.vibrate ||
            mode == NotificationMode.shortBeep) {
          nextMode = NotificationMode.off;
        } else {
          nextMode = NotificationMode.fullAdhan;
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
      case NotificationMode.fullAdhan:
        return 'أذان كامل';
      case NotificationMode.silent:
        return 'صامت';
      case NotificationMode.vibrate:
        return 'اهتزاز';
      case NotificationMode.shortBeep:
        return 'تنبيه قصير';
      case NotificationMode.off:
        return 'إيقاف';
    }
  }
}
