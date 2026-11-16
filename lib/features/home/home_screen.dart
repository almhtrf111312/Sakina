// lib/features/home/home_screen.dart
// Full home screen widget for Sakina (سكينة).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/location/location_service.dart';
import '../../data/prayer/prayer_repository.dart';
import '../aod/always_on_screen.dart';
import '../location/location_picker_screen.dart';
import 'providers/home_providers.dart';
import 'widgets/hero_prayer_card.dart';
import 'widgets/prayer_list_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _refreshData() async {
    // Refresh location if moved or update prayer times
    await ref.read(locationNotifierProvider.notifier).refreshLocationIfMoved();
    await ref.read(prayerRepositoryProvider).invalidateCache();
    ref.invalidate(prayerTimesProvider);
    ref.invalidate(todayPrayerTimesProvider);
  }

  void _showCitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CitySelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final location = ref.watch(locationProvider);
    final hijriDate = ref.watch(hijriDateStringProvider);
    final gregorianDate = ref.watch(gregorianDateStringProvider);
    final prayerListAsync = ref.watch(orderedPrayerListProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.nightBackground
          : AppColors.dayBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: isDark
              ? AppColors.nightPrimary
              : AppColors.dayPrimary,
          backgroundColor: isDark
              ? AppColors.nightSurface
              : AppColors.daySurface,
          onRefresh: _refreshData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Top Bar: Location & Dates ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dates Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hijriDate,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.nightSecondary
                                  : AppColors.daySecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            gregorianDate,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.nightTextSecondary
                                  : AppColors.dayTextSecondary,
                            ),
                          ),
                        ],
                      ),

                      // Tappable City Pill
                      InkWell(
                        onTap: () => _showCitySelector(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.nightSurface
                                : AppColors.daySurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.nightPrimary.withOpacity(0.2)
                                  : AppColors.dayPrimary.withOpacity(0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                location.isManual
                                    ? Icons.location_city_rounded
                                    : Icons.my_location_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.nightPrimary
                                    : AppColors.dayPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                location.cityName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.nightTextPrimary
                                      : AppColors.dayTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.nightTextSecondary
                                    : AppColors.dayTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Hero Card: Next Prayer & Countdown ──
              const SliverToBoxAdapter(
                child: HeroPrayerCard(),
              ),

              // ── Section Title: مواقيت الصلاة ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مواقيت الصلاة اليوم',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.nightTextPrimary
                              : AppColors.dayTextPrimary,
                        ),
                      ),
                      Text(
                        'التنبيهات',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Cairo',
                          color: isDark
                              ? AppColors.nightTextSecondary
                              : AppColors.dayTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Prayer List Items ──
              prayerListAsync.when(
                data: (prayers) {
                  final upcoming = ref.watch(nextPrayerProgressProvider.select(
                      (value) => value.valueOrNull == null ? null : (
                        value.valueOrNull!.prayerName, value.valueOrNull!.targetTime)));

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = prayers[index];
                        final isNext = upcoming != null && item.key == upcoming.$1 &&
                            item.value.isAtSameMomentAs(upcoming.$2);
                        return PrayerListTile(
                          prayerName: item.key,
                          prayerTime: item.value,
                          isNext: isNext,
                        );
                      },
                      childCount: prayers.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('تعذر تحميل مواقيت الصلاة: $e'),
                    ),
                  ),
                ),
              ),

              // ── Always-on screen quick card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AlwaysOnScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  AppColors.nightPrimary.withOpacity(0.18),
                                  AppColors.nightSurface,
                                ]
                              : [
                                  AppColors.dayPrimary.withOpacity(0.12),
                                  Colors.white,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? AppColors.nightPrimary.withOpacity(0.3)
                              : AppColors.dayPrimary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.nightPrimary.withOpacity(0.2)
                                  : AppColors.dayPrimary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_clock,
                              color: isDark
                                  ? AppColors.nightPrimary
                                  : AppColors.dayPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الشاشة الدائمة',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.nightTextPrimary
                                        : AppColors.dayTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'الساعة والتاريخ والصلاة القادمة عند قفل الجهاز',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.nightTextSecondary
                                        : AppColors.dayTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.nightTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── City Selector Modal Sheet ──────────────────────

class _CitySelectorSheet extends ConsumerWidget {
  const _CitySelectorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLocation = ref.watch(locationProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            'تحديد الموقع والمدينة',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.nightTextPrimary
                  : AppColors.dayTextPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // GPS Auto-detect Button
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: isDark
                ? AppColors.nightElevated
                : AppColors.dayChip,
            leading: Icon(
              Icons.my_location_rounded,
              color: AppColors.nightPrimary,
            ),
            title: const Text(
              'تحديد الموقع التلقائي (GPS)',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'تحديث المواقيت تلقائياً عند تغيير المكان',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
            ),
            onTap: () async {
              Navigator.pop(context);
              final updated = await ref
                  .read(locationNotifierProvider.notifier)
                  .updateGpsLocation();
              if (updated) {
                await ref.read(prayerRepositoryProvider).invalidateCache();
                ref.invalidate(prayerTimesProvider);
                ref.invalidate(todayPrayerTimesProvider);
              }
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: isDark
                ? AppColors.nightElevated
                : AppColors.dayChip,
            leading: Icon(Icons.public, color: AppColors.nightPrimary),
            title: const Text(
              'كل دول العالم ومحافظاتها',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'اختر الدولة ثم المحافظة أو الولاية',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
            ),
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(MaterialPageRoute(
                  builder: (_) => const LocationPickerScreen()));
            },
          ),
          const SizedBox(height: 16),

          // Popular Cities List
          Text(
            'أو اختر من المدن الشائعة:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'Cairo',
              color: isDark
                  ? AppColors.nightTextSecondary
                  : AppColors.dayTextSecondary,
            ),
          ),
          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: AppLocation.defaultCities.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final city = AppLocation.defaultCities[idx];
                final isSelected = currentLocation.cityName == city.cityName;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: isSelected
                        ? AppColors.nightPrimary
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                  title: Text(
                    city.cityName,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? (isDark
                              ? AppColors.nightPrimary
                              : AppColors.dayPrimary)
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    city.countryName,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
                          color: AppColors.nightPrimary)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await ref
                        .read(locationNotifierProvider.notifier)
                        .setManualLocation(city);
                    await ref.read(prayerRepositoryProvider).invalidateCache();
                    ref.invalidate(prayerTimesProvider);
                    ref.invalidate(todayPrayerTimesProvider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
