// lib/features/home/widgets/hero_prayer_card.dart
// Hero prayer card with countdown, circular progress indicator, and next prayer details.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/prayer_icons.dart';
import '../providers/home_providers.dart';

class HeroPrayerCard extends ConsumerWidget {
  const HeroPrayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(nextPrayerProgressProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return progressAsync.when(
      data: (data) {
        if (data == null) {
          return _buildLoadingPlaceholder(context, isDark);
        }

        final timeFormat = DateFormat('hh:mm a', 'ar');
        final formattedTime = timeFormat.format(data.targetTime);

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
                      const Color(0xFF1D2B28),
                      const Color(0xFF16211F),
                    ]
                  : [
                      const Color(0xFFE8F5F1),
                      const Color(0xFFFFFFFF),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.35)
                    : const Color(0xFF2F7F69).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? const Color(0xFF5FB59B).withOpacity(0.15)
                  : const Color(0xFF2F7F69).withOpacity(0.12),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              // ── Header: Icon + Next Prayer Title ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF5FB59B).withOpacity(0.15)
                          : const Color(0xFF2F7F69).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PrayerIcons.getIcon(data.prayerName),
                      color: isDark
                          ? const Color(0xFF5FB59B)
                          : const Color(0xFF2F7F69),
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
                          ? const Color(0xFFE8EFEC)
                          : const Color(0xFF1B2A27),
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
                      ? const Color(0xFF9DB0AA)
                      : const Color(0xFF607068),
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
                              ? const Color(0xFF1D2B28).withOpacity(0.8)
                              : const Color(0xFFE0ECE8),
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
                              ? const Color(0xFF5FB59B)
                              : const Color(0xFF2F7F69),
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
                            ? const Color(0xFF0E1514).withOpacity(0.6)
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? const Color(0xFF5FB59B).withOpacity(0.05)
                                : const Color(0xFF2F7F69).withOpacity(0.05),
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
                                  ? const Color(0xFF9DB0AA)
                                  : const Color(0xFF607068),
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
                                  ? const Color(0xFFE8EFEC)
                                  : const Color(0xFF1B2A27),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFFC9A86A).withOpacity(0.18)
                                  : const Color(0xFFA9884A).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'سكينة وطمأنينة',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? const Color(0xFFC9A86A)
                                    : const Color(0xFFA9884A),
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
        color: isDark ? const Color(0xFF16211F) : Colors.white,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5FB59B)),
        ),
      ),
    );
  }
}
