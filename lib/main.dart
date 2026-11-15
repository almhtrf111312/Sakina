import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/i18n/app_localizations.dart';
import 'core/theme/app_colors.dart';
import 'features/aod/always_on_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/notifications/prayer_alarm_sync.dart';
import 'core/utils/alarm_bridge.dart';
import 'data/prayer/prayer_repository.dart';
import 'data/settings/settings_repository.dart';
import 'features/home/home_screen.dart';
import 'features/azkar/azkar_screen.dart';
import 'features/qibla/qibla_screen.dart';
import 'features/tasbih/tasbih_screen.dart';
import 'features/settings/settings_screen.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final currentTabProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Lock to portrait by default; can be changed in settings.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar + navigation bar.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SakinaApp(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------

class SakinaApp extends ConsumerWidget {
  const SakinaApp({super.key});

  /// Day/night decision for the "follow sunrise/sunset" theme mode.
  bool _isDaytime(WidgetRef ref) {
    final now = DateTime.now();
    final schedule = ref.watch(prayerTimesProvider).valueOrNull;
    if (schedule != null && schedule.isNotEmpty) {
      final times = schedule.first.times;
      final sunrise = times['Sunrise']?.toLocal();
      final maghrib = times['Maghrib']?.toLocal();
      if (sunrise != null && maghrib != null) {
        return now.isAfter(sunrise) && now.isBefore(maghrib);
      }
    }
    return now.hour >= 6 && now.hour < 18;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Persisted settings (the same provider the Settings screen edits).
    final settings = ref.watch(appSettingsProvider);

    // Palette switches must be set before the themes are built.
    AppPalette.amoled = settings.themeMode == AppThemeMode.amoled;
    AppPalette.accent = settings.accentColor.name;

    final ThemeMode themeMode;
    switch (settings.themeMode) {
      case AppThemeMode.night:
      case AppThemeMode.amoled:
        themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.day:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.systemAuto:
        themeMode = ThemeMode.system;
        break;
      case AppThemeMode.sunriseAuto:
        themeMode = _isDaytime(ref) ? ThemeMode.light : ThemeMode.dark;
        break;
    }

    final locale = Locale(settings.languageCode);
    final isRtl = settings.languageCode == 'ar';

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.dayTheme(),
      darkTheme: settings.themeMode == AppThemeMode.amoled
          ? AppTheme.amoledTheme()
          : AppTheme.nightTheme(),
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('tr'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final iconBrightness = dark ? Brightness.light : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: iconBrightness,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: iconBrightness,
          ),
          child: _TapFeedback(
            sound: settings.tapSound,
            haptic: settings.tapHaptic,
            volume: settings.tapVolume,
            intensity: settings.tapHapticIntensity,
            // The tasbih counter emits its own cue, including a distinct goal cue.
            skipCounter: () => ref.read(currentTabProvider) == 3,
            child: Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
          ),
        );
      },
      home: const SakinaShell(),
    );
  }
}

/// Plays a short click and/or vibration on every genuine tap (not scrolls).
class _TapFeedback extends StatefulWidget {
  const _TapFeedback({
    required this.child,
    required this.sound,
    required this.haptic,
    required this.volume,
    required this.intensity,
    required this.skipCounter,
  });

  final Widget child;
  final bool sound;
  final bool haptic;
  final double volume;
  final double intensity;
  final bool Function() skipCounter;

  @override
  State<_TapFeedback> createState() => _TapFeedbackState();
}

class _TapFeedbackState extends State<_TapFeedback> {
  Offset? _downPos;
  int _downAt = 0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _downPos = e.position;
        _downAt = DateTime.now().millisecondsSinceEpoch;
      },
      onPointerUp: (e) {
        final down = _downPos;
        _downPos = null;
        if (down == null || widget.skipCounter() || (!widget.sound && !widget.haptic)) return;
        final moved = (e.position - down).distance;
        final held = DateTime.now().millisecondsSinceEpoch - _downAt;
        if (moved < 14 && held < 350) {
          AlarmBridge.tapFeedback(sound: widget.sound, haptic: widget.haptic,
              volume: widget.volume, intensity: widget.intensity);
        }
      },
      onPointerCancel: (_) => _downPos = null,
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Shell with bottom navigation
// ---------------------------------------------------------------------------

class SakinaShell extends ConsumerStatefulWidget {
  const SakinaShell({super.key});

  @override
  ConsumerState<SakinaShell> createState() => _SakinaShellState();
}

class _SakinaShellState extends ConsumerState<SakinaShell>
    with TickerProviderStateMixin {
  Widget _screenFor(int index) {
    switch (index) {
      case 1:
        return const AzkarScreen(key: ValueKey('tab-azkar'));
      case 2:
        return const QiblaScreen(key: ValueKey('tab-qibla'));
      case 3:
        return const TasbihScreen(key: ValueKey('tab-tasbih'));
      case 4:
        return const SettingsScreen(key: ValueKey('tab-settings'));
      default:
        return const HomeScreen(key: ValueKey('tab-home'));
    }
  }

  void _onTabTapped(int index) {
    if (ref.read(currentTabProvider) == index) return;
    // Only the selected tab is built: no animated sweep through heavy
    // intermediate screens and no background sensors/timers on hidden tabs.
    ref.read(currentTabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    // Keep native adhan alarms in sync with prayer times & settings.
    ref.watch(prayerAlarmSyncProvider);
    ref.watch(alwaysOnProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: _screenFor(currentTab),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: l10n.home,
                  isSelected: currentTab == 0,
                  onTap: () => _onTabTapped(0),
                ),
                _NavItem(
                  icon: Icons.auto_stories_rounded,
                  label: l10n.azkar,
                  isSelected: currentTab == 1,
                  onTap: () => _onTabTapped(1),
                ),
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: l10n.qibla,
                  isSelected: currentTab == 2,
                  onTap: () => _onTabTapped(2),
                ),
                _NavItem(
                  icon: Icons.radio_button_checked_rounded,
                  label: l10n.tasbih,
                  isSelected: currentTab == 3,
                  onTap: () => _onTabTapped(3),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: l10n.settings,
                  isSelected: currentTab == 4,
                  onTap: () => _onTabTapped(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation item widget
// ---------------------------------------------------------------------------

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
