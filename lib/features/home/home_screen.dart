// lib/features/home/home_screen.dart
// Full home screen widget for Sakina (سكينة).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/location/location_service.dart';
import '../../data/prayer/prayer_repository.dart';
import '../aod/aod_settings_screen.dart';
import 'providers/home_providers.dart';
import 'widgets/daily_dhikr_card.dart';
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
    final nextPrayerAsync = ref.watch(nextPrayerProvider);
    final prayerListAsync = ref.watch(orderedPrayerListProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E1514)
          : const Color(0xFFF6F4EE),
      body: SafeArea(
        child: RefreshIndicator(
          color: isDark
              ? const Color(0xFF5FB59B)
              : const Color(0xFF2F7F69),
          backgroundColor: isDark
              ? const Color(0xFF16211F)
              : Colors.white,
          onRefresh: _refreshData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Top Bar: Location & Dates ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                                  ? const Color(0xFFC9A86A)
                                  : const Color(0xFFA9884A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            gregorianDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'Cairo',
                              color: isDark
                                  ? const Color(0xFF9DB0AA)
                                  : const Color(0xFF607068),
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
                                ? const Color(0xFF16211F)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF5FB59B).withOpacity(0.2)
                                  : const Color(0xFF2F7F69).withOpacity(0.15),
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
                                    ? const Color(0xFF5FB59B)
                                    : const Color(0xFF2F7F69),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                location.cityName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFE8EFEC)
                                      : const Color(0xFF1B2A27),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF9DB0AA)
                                    : const Color(0xFF607068),
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

              // ── Quick Azkar Shortcuts (صباح / مساء) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AzkarShortcutCard(
                          title: 'أذكار الصباح',
                          subtitle: 'نور وبركة ليومك',
                          icon: Icons.wb_sunny_outlined,
                          accentColor: const Color(0xFFC9A86A),
                          onTap: () {
                            // Navigate to morning azkar
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AzkarShortcutCard(
                          title: 'أذكار المساء',
                          subtitle: 'حفظ وسكينة لليلتك',
                          icon: Icons.nights_stay_outlined,
                          accentColor: const Color(0xFF5FB59B),
                          onTap: () {
                            // Navigate to evening azkar
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section Title: مواقيت الصلاة ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مواقيت الصلاة اليوم',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFE8EFEC)
                              : const Color(0xFF1B2A27),
                        ),
                      ),
                      Text(
                        'التنبيهات',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Cairo',
                          color: isDark
                              ? const Color(0xFF9DB0AA)
                              : const Color(0xFF607068),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Prayer List Items ──
              prayerListAsync.when(
                data: (prayers) {
                  final nextName = nextPrayerAsync.asData?.value?.name;

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = prayers[index];
                        final isNext = item.key == nextName;
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

              // ── AOD Lock Screen Wallpaper Quick Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AodSettingsScreen(),
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
                                  const Color(0xFF5FB59B).withOpacity(0.18),
                                  const Color(0xFF16211F),
                                ]
                              : [
                                  const Color(0xFF2F7F69).withOpacity(0.12),
                                  Colors.white,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF5FB59B).withOpacity(0.3)
                              : const Color(0xFF2F7F69).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF5FB59B).withOpacity(0.2)
                                  : const Color(0xFF2F7F69).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_clock,
                              color: isDark
                                  ? const Color(0xFF5FB59B)
                                  : const Color(0xFF2F7F69),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'خلفية شاشة القفل والشاشة الدائمة (AOD)',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? const Color(0xFFE8EFEC)
                                        : const Color(0xFF1B2A27),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'تثبيت كخلفية لقفل الشاشة مع تخصيص الساعة والمواقيت',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF9DB0AA)
                                        : const Color(0xFF607068),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFF9DB0AA),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Daily Dhikr Card at Bottom ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 24),
                  child: DailyDhikrCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Azkar Shortcut Card ────────────────────────────

class _AzkarShortcutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _AzkarShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16211F) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFE8EFEC)
                          : const Color(0xFF1B2A27),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'Cairo',
                      color: isDark
                          ? const Color(0xFF9DB0AA)
                          : const Color(0xFF607068),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        color: isDark ? const Color(0xFF16211F) : Colors.white,
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
                  ? const Color(0xFFE8EFEC)
                  : const Color(0xFF1B2A27),
            ),
          ),
          const SizedBox(height: 16),

          // GPS Auto-detect Button
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: isDark
                ? const Color(0xFF1D2B28)
                : const Color(0xFFF0F7F4),
            leading: const Icon(
              Icons.my_location_rounded,
              color: Color(0xFF5FB59B),
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
          const SizedBox(height: 16),

          // Popular Cities List
          Text(
            'أو اختر من المدن الشائعة:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'Cairo',
              color: isDark
                  ? const Color(0xFF9DB0AA)
                  : const Color(0xFF607068),
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
                        ? const Color(0xFF5FB59B)
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
                              ? const Color(0xFF5FB59B)
                              : const Color(0xFF2F7F69))
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    city.countryName,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF5FB59B))
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
