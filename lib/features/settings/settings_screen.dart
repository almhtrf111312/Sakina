// lib/features/settings/settings_screen.dart
// Main settings page: a list of categories, each opening its own page.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../aod/always_on_screen.dart';
import 'pages/appearance_settings_page.dart';
import 'pages/azkar_settings_page.dart';
import 'pages/location_settings_page.dart';
import 'pages/notifications_settings_page.dart';
import 'pages/qibla_settings_page.dart';
import 'widgets/permission_check_screen.dart';
import 'widgets/settings_common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Widget _entry(
    BuildContext context, {
    required bool isDark,
    required Color primary,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
    Color? subtitleColor,
  }) {
    return buildSettingsCard(
      isDark: isDark,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: subtitleColor ??
                  (isDark
                      ? AppColors.nightTextSecondary
                      : AppColors.dayTextSecondary),
            ),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final aodEnabled = ref.watch(alwaysOnProvider).enabled;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.nightBackground : AppColors.dayBackground,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.nightSurface : AppColors.daySurface,
          elevation: 0,
          title: Text(
            'الإعدادات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.nightTextPrimary
                  : AppColors.dayTextPrimary,
            ),
          ),
          actions: [
            // Quick permissions shortcut
            IconButton(
              icon: Icon(
                Icons.security_outlined,
                color: isDark
                    ? AppColors.nightSecondary
                    : AppColors.daySecondary,
              ),
              tooltip: 'فحص الأذونات',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PermissionCheckScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            _entry(
              context,
              isDark: isDark,
              primary: primary,
              icon: Icons.public_outlined,
              title: 'الموقع وحساب المواقيت',
              subtitle: 'طريقة الحساب، المذهب، تعديل الدقائق، التقويم الهجري',
              page: const LocationSettingsPage(),
            ),
            _entry(
              context,
              isDark: isDark,
              primary: primary,
              icon: Icons.notifications_active_outlined,
              title: 'التنبيهات والأذان',
              subtitle: 'نوع التنبيه لكل صلاة، صوت الأذان، التذكيرات',
              page: const NotificationsSettingsPage(),
            ),
            _entry(
              context,
              isDark: isDark,
              primary: primary,
              icon: Icons.palette_outlined,
              title: 'المظهر والسمات',
              subtitle: 'السمة، اللون المميز، الخط، الأرقام، اللغة',
              page: const AppearanceSettingsPage(),
            ),
            _entry(
              context,
              isDark: isDark,
              primary: primary,
              icon: Icons.auto_stories_outlined,
              title: 'الأذكار والتسبيح',
              subtitle: 'حجم الخط، التشكيل، الاهتزاز، الانتقال التلقائي',
              page: const AzkarSettingsPage(),
            ),
            _entry(
              context,
              isDark: isDark,
              primary: primary,
              icon: Icons.explore_outlined,
              title: 'بوصلة القبلة',
              subtitle: 'وحدة المسافة والاهتزاز عند محاذاة القبلة',
              page: const QiblaSettingsPage(),
            ),
            _entry(
              context,
              isDark: isDark,
              primary: primary,
              icon: Icons.phone_android,
              title: 'الشاشة الدائمة',
              subtitle:
                  aodEnabled ? 'مفعلة' : 'معطلة - اضغط للضبط والمعاينة',
              subtitleColor: aodEnabled ? primary : null,
              page: const AlwaysOnScreen(),
            ),
            // ─── حول التطبيق ───────────────────────────────────────────────
            const SizedBox(height: 12),
            buildSettingsCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, primary.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'س',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المؤذن | Al Muadhin',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.nightTextPrimary
                                    : AppColors.dayTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'الإصدار 1.0.0 (Build 1)',
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
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'تطبيق إسلامي مفتوح ومستقل، بدون إعلانات وبدون تتبع، صُمم بعناية ليعين المسلم على ذكر الله وإقامة الصلاة في أوقاتها بسكينة وطمأنينة.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? AppColors.nightTextSecondary
                            : AppColors.dayTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.nightSecondary
                                : AppColors.daySecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            buildSettingsCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('المزيد من تطبيقات المطوّر',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'اكتشف تطبيقاتنا وتابع أحدث الإصدارات والتحديثات عبر قناتنا على تيليغرام.',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.6)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.telegram),
                      label: const Text('زيارة قناة المطوّر'),
                      onPressed: () async {
                        try {
                          await const MethodChannel('com.sakina.app/external_link')
                              .invokeMethod<void>('openDeveloperChannel');
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('تعذر فتح القناة. تأكد من وجود متصفح أو تطبيق تيليغرام.')));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
