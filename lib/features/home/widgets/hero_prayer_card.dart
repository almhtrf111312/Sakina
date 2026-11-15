// lib/features/home/widgets/hero_prayer_card.dart
// Hero prayer card with countdown, circular progress indicator, and next prayer details.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/prayer_icons.dart';
import '../../../data/settings/settings_repository.dart';
import '../providers/home_providers.dart';

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
          return _buildLoadingPlaceholder(context, isDark);
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

              // ── Circular Progress & Countdown ──
              SizedBox(
                width: 190,
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background track
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? AppColors.nightElevated.withOpacity(0.8)
                              : AppColors.dayChipStrong,
                        ),
                      ),
                    ),
                    // Active animated progress track
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: CircularProgressIndicator(
                        value: data.progress,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? AppColors.nightPrimary
                              : AppColors.dayPrimary,
                        ),
                      ),
                    ),
                    // Inner glow / decor
                    Container(
                      width: 154,
                      height: 154,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.nightBackground.withOpacity(0.6)
                            : AppColors.daySurface,
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? AppColors.nightPrimary.withOpacity(0.05)
                                : AppColors.dayPrimary.withOpacity(0.05),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'متبقي على الأذان',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontFamily: 'Cairo',
                              color: isDark
                                  ? AppColors.nightTextSecondary
                                  : AppColors.dayTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.formattedCountdown,
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: isDark
                                  ? AppColors.nightTextPrimary
                                  : AppColors.dayTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.nightSecondary.withOpacity(0.18)
                                  : AppColors.daySecondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'سكينة وطمأنينة',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? AppColors.nightSecondary
                                    : AppColors.daySecondary,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingPlaceholder(context, isDark),
      error: (_, __) => _buildLoadingPlaceholder(context, isDark),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isDark ? AppColors.nightSurface : Colors.white,
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.nightPrimary),
        ),
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
    final sub = isDark ? AppColors.nightTextSecondary : AppColors.dayTextSecondary;
    String two(int n) => n.toString().padLeft(2, '0');
    final date = DateFormat('EEEE، d MMMM yyyy', 'ar').format(_now);
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
        Text(date,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: sub)),
      ],
    );
  }
}
