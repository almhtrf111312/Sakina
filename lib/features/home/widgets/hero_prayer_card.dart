// lib/features/home/widgets/hero_prayer_card.dart
// Hero prayer card with countdown, circular progress indicator, and next prayer details.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/prayer_icons.dart';
import '../../../data/settings/settings_repository.dart';
import '../../../data/prayer/prayer_repository.dart';
import '../providers/home_providers.dart';
import 'home_clock_display.dart';

class HeroPrayerCard extends ConsumerWidget {
  const HeroPrayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final progressAsync = ref.watch(nextPrayerProgressProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return progressAsync.when(
      data: (data) {
        if (data == null) {
          return _buildLoadingPlaceholder(context, isDark,
              failed: ref.watch(prayerTimesProvider).hasError);
        }

        final formattedTime = AppDateUtils.formatPrayerTime(data.targetTime,
            is24Hour: settings.use24HourTime, languageCode: settings.languageCode);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.nightElevated,
                      AppColors.nightSurface,
                    ]
                  : [
                      AppColors.dayChip,
                      AppColors.daySurface,
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.35)
                    : AppColors.dayPrimary.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? AppColors.nightPrimary.withOpacity(0.15)
                  : AppColors.dayPrimary.withOpacity(0.12),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              const _LiveClock(),
              const SizedBox(height: 14),
              // ── Header: Icon + Next Prayer Title ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.nightPrimary.withOpacity(0.15)
                          : AppColors.dayPrimary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PrayerIcons.getIcon(data.prayerName),
                      color: isDark
                          ? AppColors.nightPrimary
                          : AppColors.dayPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'الصلاة القادمة: صلاة ${data.prayerArabicName}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                      color: isDark
                          ? AppColors.nightTextPrimary
                          : AppColors.dayTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Target Adhan Time
              Text(
                'حان موعدها الساعة $formattedTime',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.nightTextSecondary
                      : AppColors.dayTextSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 24),

              HomeClockDisplay(style: settings.homeClockStyle, data: data),

            ],
          ),
        );
      },
      loading: () => _buildLoadingPlaceholder(context, isDark),
      error: (_, __) => _buildLoadingPlaceholder(context, isDark, failed: true),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context, bool isDark, {bool failed = false}) {
    return Container(
      width: double.infinity,
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isDark ? AppColors.nightSurface : Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _LiveClock(),
          const SizedBox(height: 16),
          Text(failed ? 'تعذر تحميل مواقيت الصلاة' : 'جارٍ تجهيز مواقيت الصلاة'),
        ],
      ),
    );
  }
}


/// Large live clock + date shown at the top of the hero card.
class _LiveClock extends ConsumerStatefulWidget {
  const _LiveClock();

  @override
  ConsumerState<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends ConsumerState<_LiveClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.nightPrimary : AppColors.dayPrimary;
    String two(int n) => n.toString().padLeft(2, '0');
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          textDirection: TextDirection.ltr,
          children: [
            Text(
              AppDateUtils.formatPrayerTime(_now,
                  is24Hour: settings.use24HourTime, languageCode: settings.languageCode),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: settings.use24HourTime ? 52 : 40,
                height: 1.1,
                fontWeight: FontWeight.w300,
                color: primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              two(_now.second),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                color: primary.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
