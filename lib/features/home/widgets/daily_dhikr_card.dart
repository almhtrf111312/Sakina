// lib/features/home/widgets/daily_dhikr_card.dart
// Daily dhikr card widget with Arabic typography, source, virtue, copy & share actions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/home_providers.dart';

class DailyDhikrCard extends ConsumerWidget {
  const DailyDhikrCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dhikr = ref.watch(dailyDhikrProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.nightSecondary.withOpacity(0.2)
              : AppColors.daySecondary.withOpacity(0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Title & Count Badge ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.nightSecondary.withOpacity(0.15)
                          : AppColors.daySecondary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.nightSecondary
                          : AppColors.daySecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ذِكْرُ الْيَوْمِ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: isDark
                          ? AppColors.nightSecondary
                          : AppColors.daySecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.nightPrimary.withOpacity(0.15)
                      : AppColors.dayPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dhikr.count} مرة',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.nightPrimary
                        : AppColors.dayPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Main Dhikr Arabic Text ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.nightBackground.withOpacity(0.6)
                  : const Color(0xFFF9F8F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              dhikr.text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.w700,
                fontSize: 21,
                height: 1.8,
                color: isDark
                    ? AppColors.nightTextPrimary
                    : AppColors.dayTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Virtue & Source ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 16,
                color: isDark
                    ? AppColors.nightTextSecondary
                    : AppColors.dayTextSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dhikr.virtue,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Cairo',
                        height: 1.4,
                        color: isDark
                            ? AppColors.nightTextSecondary
                            : AppColors.dayTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dhikr.source,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.nightSecondary
                            : AppColors.daySecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Action Footer: Copy Dhikr ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text(
                  'نسخ الذكر',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.nightPrimary
                      : AppColors.dayPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: '${dhikr.text}\n(${dhikr.virtue} - ${dhikr.source})'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم نسخ الذكر إلى الحافظة',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
