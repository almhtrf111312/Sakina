import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/alarm_bridge.dart';
import '../../data/prayer/prayer_repository.dart';
import '../../data/settings/settings_repository.dart';
import 'aod_preview_screen.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

enum AodShowWhen { alwaysLocked, aroundAdhan, chargingOnly, schedule }

enum AodPattern { simple, full, clock, decorative }

enum AodColor { green, gold, white, blue }

class AodSettings {
  final bool enabled;
  final AodShowWhen showWhen;
  final int beforeAdhanMinutes;
  final int afterAdhanMinutes;
  final int autoOffSeconds;
  final AodPattern pattern;
  final AodColor color;
  final double brightness;
  final bool burnInProtection;
  final bool showClock;
  final bool showHijriDate;
  final bool showPrayersRow;
  final bool showBattery;
  final bool dontOnAirplaneMode;
  final int dontBelowBatteryPct;
  final bool dontOnPowerSave;
  final TimeOfDay? scheduleFrom;
  final TimeOfDay? scheduleTo;
  final int clockStyle; // 0: Modern Digital, 1: Classic Amiri, 2: Minimalist, 3: Boxed

  const AodSettings({
    this.enabled = true,
    this.showWhen = AodShowWhen.alwaysLocked,
    this.beforeAdhanMinutes = 10,
    this.afterAdhanMinutes = 15,
    this.autoOffSeconds = 60,
    this.pattern = AodPattern.full,
    this.color = AodColor.green,
    this.brightness = 0.4,
    this.burnInProtection = true,
    this.showClock = true,
    this.showHijriDate = true,
    this.showPrayersRow = true,
    this.showBattery = true,
    this.dontOnAirplaneMode = false,
    this.dontBelowBatteryPct = 10,
    this.dontOnPowerSave = false,
    this.scheduleFrom,
    this.scheduleTo,
    this.clockStyle = 0,
  });

  AodSettings copyWith({
    bool? enabled,
    AodShowWhen? showWhen,
    int? beforeAdhanMinutes,
    int? afterAdhanMinutes,
    int? autoOffSeconds,
    AodPattern? pattern,
    AodColor? color,
    double? brightness,
    bool? burnInProtection,
    bool? showClock,
    bool? showHijriDate,
    bool? showPrayersRow,
    bool? showBattery,
    bool? dontOnAirplaneMode,
    int? dontBelowBatteryPct,
    bool? dontOnPowerSave,
    TimeOfDay? scheduleFrom,
    TimeOfDay? scheduleTo,
    int? clockStyle,
  }) =>
      AodSettings(
        enabled: enabled ?? this.enabled,
        showWhen: showWhen ?? this.showWhen,
        beforeAdhanMinutes: beforeAdhanMinutes ?? this.beforeAdhanMinutes,
        afterAdhanMinutes: afterAdhanMinutes ?? this.afterAdhanMinutes,
        autoOffSeconds: autoOffSeconds ?? this.autoOffSeconds,
        pattern: pattern ?? this.pattern,
        color: color ?? this.color,
        brightness: brightness ?? this.brightness,
        burnInProtection: burnInProtection ?? this.burnInProtection,
        showClock: showClock ?? this.showClock,
        showHijriDate: showHijriDate ?? this.showHijriDate,
        showPrayersRow: showPrayersRow ?? this.showPrayersRow,
        showBattery: showBattery ?? this.showBattery,
        dontOnAirplaneMode: dontOnAirplaneMode ?? this.dontOnAirplaneMode,
        dontBelowBatteryPct: dontBelowBatteryPct ?? this.dontBelowBatteryPct,
        dontOnPowerSave: dontOnPowerSave ?? this.dontOnPowerSave,
        scheduleFrom: scheduleFrom ?? this.scheduleFrom,
        scheduleTo: scheduleTo ?? this.scheduleTo,
        clockStyle: clockStyle ?? this.clockStyle,
      );
}

// ─── Provider ────────────────────────────────────────────────────────────────

final aodSettingsProvider =
    StateNotifierProvider<AodSettingsNotifier, AodSettings>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AodSettingsNotifier(prefs);
  },
);

class AodSettingsNotifier extends StateNotifier<AodSettings> {
  final SharedPreferences? _prefs;
  static const _key = 'sakina_aod_ui_settings';

  AodSettingsNotifier([this._prefs]) : super(_loadInitial(_prefs));

  static AodSettings _loadInitial(SharedPreferences? prefs) {
    if (prefs == null) return const AodSettings();
    final raw = prefs.getString(_key);
    if (raw == null) return const AodSettings();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AodSettings(
        enabled: map['enabled'] as bool? ?? true,
        clockStyle: map['clockStyle'] as int? ?? 0,
        brightness: (map['brightness'] as num?)?.toDouble() ?? 0.4,
        burnInProtection: map['burnInProtection'] as bool? ?? true,
        showClock: map['showClock'] as bool? ?? true,
        showHijriDate: map['showHijriDate'] as bool? ?? true,
        showPrayersRow: map['showPrayersRow'] as bool? ?? true,
        showBattery: map['showBattery'] as bool? ?? true,
        autoOffSeconds: map['autoOffSeconds'] as int? ?? 60,
        beforeAdhanMinutes: map['beforeAdhanMinutes'] as int? ?? 10,
        afterAdhanMinutes: map['afterAdhanMinutes'] as int? ?? 15,
      );
    } catch (_) {
      return const AodSettings();
    }
  }

  void update(AodSettings s) {
    state = s;
    _persist(s);
  }

  void toggle(bool v) {
    final s = state.copyWith(enabled: v);
    state = s;
    _persist(s);
  }

  void _persist(AodSettings s) {
    _prefs?.setString(
      _key,
      jsonEncode({
        'enabled': s.enabled,
        'clockStyle': s.clockStyle,
        'brightness': s.brightness,
        'burnInProtection': s.burnInProtection,
        'showClock': s.showClock,
        'showHijriDate': s.showHijriDate,
        'showPrayersRow': s.showPrayersRow,
        'showBattery': s.showBattery,
        'autoOffSeconds': s.autoOffSeconds,
        'beforeAdhanMinutes': s.beforeAdhanMinutes,
        'afterAdhanMinutes': s.afterAdhanMinutes,
      }),
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AodSettingsScreen extends ConsumerStatefulWidget {
  const AodSettingsScreen({super.key});

  @override
  ConsumerState<AodSettingsScreen> createState() => _AodSettingsScreenState();
}

class _AodSettingsScreenState extends ConsumerState<AodSettingsScreen> {
  bool _aodSupported = true;
  bool _wallpaperSupported = true;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    try {
      final aod = await AlarmBridge.isAodSupported();
      final wp = await AlarmBridge.isWallpaperSupported();
      if (mounted) {
        setState(() {
          _aodSupported = aod;
          _wallpaperSupported = wp;
        });
      }
    } catch (_) {}
  }

  Color _colorValue(AodColor c) {
    switch (c) {
      case AodColor.green:
        return const Color(0xFF5FB59B);
      case AodColor.gold:
        return const Color(0xFFC9A86A);
      case AodColor.white:
        return Colors.white;
      case AodColor.blue:
        return const Color(0xFF5B9BD5);
    }
  }

  String _colorLabel(AodColor c) {
    switch (c) {
      case AodColor.green:
        return 'أخضر زمردي';
      case AodColor.gold:
        return 'ذهبي هادئ';
      case AodColor.white:
        return 'أبيض ناصع';
      case AodColor.blue:
        return 'أزرق ليلي';
    }
  }

  String _clockStyleLabel(int style) {
    switch (style) {
      case 0:
        return 'رقمي عصري';
      case 1:
        return 'خط كلاسيكي';
      case 2:
        return 'بسيط ناعم';
      case 3:
        return 'إطار هندسي';
      default:
        return 'رقمي';
    }
  }

  String _showWhenLabel(AodShowWhen w) {
    switch (w) {
      case AodShowWhen.alwaysLocked:
        return 'دائماً أثناء القفل (خلفية AOD كاملة)';
      case AodShowWhen.aroundAdhan:
        return 'حول وقت الأذان فقط';
      case AodShowWhen.chargingOnly:
        return 'عند الشحن فقط';
      case AodShowWhen.schedule:
        return 'جدول زمني مخصص';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aodSettingsProvider);
    final notifier = ref.read(aodSettingsProvider.notifier);
    final appSettings = ref.watch(settingsNotifierProvider);
    final appSettingsNotifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);
    final accent = _colorValue(settings.color);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1514),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16211F),
        title: const Text(
          'الشاشة الدائمة وخلفية القفل (AOD)',
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              color: Color(0xFFE8EFEC),
              fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5FB59B)),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: !_aodSupported
          ? _buildNotSupported(theme)
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // ─── HERO ACTION: Set as Lock Screen Wallpaper ───
                _buildWallpaperHeroCard(accent),

                const SizedBox(height: 12),

                // ─── Enable Toggle ───
                _buildCard(
                  child: SwitchListTile(
                    title: const Text('تفعيل الشاشة الدائمة (AOD)',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xFFE8EFEC),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'تعرض مواقيت الصلاة والعد التنازلي على شاشة القفل بوضع AMOLED',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xFF9DB0AA),
                            fontSize: 13)),
                    value: settings.enabled,
                    activeColor: accent,
                    onChanged: notifier.toggle,
                    secondary:
                        Icon(Icons.lock_clock, color: accent, size: 28),
                  ),
                ),

                if (settings.enabled) ...[
                  // ─── Clock Style (شكل الساعة) ───
                  _buildSectionHeader('شكل وتصميم الساعة'),
                  _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('اختر نمط عرض الوقت على شاشة القفل:',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Color(0xFF9DB0AA),
                                  fontSize: 13)),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(4, (index) {
                              final isSelected = settings.clockStyle == index;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    notifier.update(
                                        settings.copyWith(clockStyle: index));
                                    _syncWallpaperSettings();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accent.withOpacity(0.18)
                                          : const Color(0xFF1D2B28),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? accent
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          index == 0
                                              ? Icons.access_time_filled
                                              : index == 1
                                                  ? Icons.access_time
                                                  : index == 2
                                                      ? Icons.timelapse
                                                      : Icons.crop_square,
                                          color: isSelected
                                              ? accent
                                              : const Color(0xFF9DB0AA),
                                          size: 24,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _clockStyleLabel(index),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 11,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? accent
                                                : const Color(0xFFE8EFEC),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Time & Date Settings (تعديل الوقت والتاريخ) ───
                  _buildSectionHeader('تعديل الوقت والتاريخ والأرقام'),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildSwitch(
                          'عرض التاريخ الهجري',
                          settings.showHijriDate,
                          accent,
                          (v) {
                            notifier.update(settings.copyWith(showHijriDate: v));
                            _syncWallpaperSettings();
                          },
                        ),
                        const Divider(color: Color(0xFF26363A)),
                        ListTile(
                          title: const Text('تعديل التاريخ الهجري يدوياً',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Color(0xFFE8EFEC),
                                  fontSize: 15)),
                          subtitle: Text(
                            appSettings.hijriOffset == 0
                                ? 'بدون تعديل (تلقائي)'
                                : '${appSettings.hijriOffset > 0 ? "+" : ""}${appSettings.hijriOffset} يوم',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: accent,
                                fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Color(0xFF5FB59B)),
                                onPressed: appSettings.hijriOffset > -2
                                    ? () {
                                        appSettingsNotifier.setHijriOffset(
                                            appSettings.hijriOffset - 1);
                                        _syncWallpaperSettings();
                                      }
                                    : null,
                              ),
                              Text('${appSettings.hijriOffset}',
                                  style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    color: Color(0xFF5FB59B)),
                                onPressed: appSettings.hijriOffset < 2
                                    ? () {
                                        appSettingsNotifier.setHijriOffset(
                                            appSettings.hijriOffset + 1);
                                        _syncWallpaperSettings();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Color(0xFF26363A)),
                        ListTile(
                          title: const Text('نوع الأرقام (الساعة والمواقيت)',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Color(0xFFE8EFEC),
                                  fontSize: 15)),
                          subtitle: Text(
                            appSettings.numeralType == NumeralType.arabic
                                ? 'أرقام عربية مشرقية (٠ ١ ٢ ٣)'
                                : 'أرقام غربية (0 1 2 3)',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: accent,
                                fontSize: 13),
                          ),
                          trailing: Switch(
                            value: appSettings.numeralType == NumeralType.arabic,
                            activeColor: accent,
                            onChanged: (v) {
                              appSettingsNotifier.setNumeralType(v
                                  ? NumeralType.arabic
                                  : NumeralType.western);
                              _syncWallpaperSettings();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Prayer Times Adjustments (تعديل مواقيت الأذان) ───
                  _buildSectionHeader('تعديل مواقيت الأذان (بالدقائق)'),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildPrayerAdjustmentRow('الفجر', 'fajr', appSettings,
                            appSettingsNotifier, accent),
                        const Divider(color: Color(0xFF26363A)),
                        _buildPrayerAdjustmentRow('الظهر', 'dhuhr', appSettings,
                            appSettingsNotifier, accent),
                        const Divider(color: Color(0xFF26363A)),
                        _buildPrayerAdjustmentRow('العصر', 'asr', appSettings,
                            appSettingsNotifier, accent),
                        const Divider(color: Color(0xFF26363A)),
                        _buildPrayerAdjustmentRow('المغرب', 'maghrib',
                            appSettings, appSettingsNotifier, accent),
                        const Divider(color: Color(0xFF26363A)),
                        _buildPrayerAdjustmentRow('العشاء', 'isha', appSettings,
                            appSettingsNotifier, accent),
                      ],
                    ),
                  ),

                  // ─── When to Show ───
                  _buildSectionHeader('طريقة التفعيل والظهور'),
                  _buildCard(
                    child: Column(
                      children: AodShowWhen.values.map((w) {
                        return RadioListTile<AodShowWhen>(
                          title: Text(_showWhenLabel(w),
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Color(0xFFE8EFEC),
                                  fontSize: 14)),
                          value: w,
                          groupValue: settings.showWhen,
                          activeColor: accent,
                          onChanged: (v) =>
                              notifier.update(settings.copyWith(showWhen: v)),
                        );
                      }).toList(),
                    ),
                  ),

                  // ─── Colors and Appearance ───
                  _buildSectionHeader('اللون المميز وسطوع الشاشة'),
                  _buildCard(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('لون الإضاءة',
                                  style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Color(0xFFE8EFEC),
                                      fontSize: 15)),
                              Row(
                                children: AodColor.values.map((c) {
                                  final cv = _colorValue(c);
                                  final selected = settings.color == c;
                                  return GestureDetector(
                                    onTap: () {
                                      notifier
                                          .update(settings.copyWith(color: c));
                                      _syncWallpaperSettings();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: cv,
                                        shape: BoxShape.circle,
                                        border: selected
                                            ? Border.all(
                                                color: Colors.white, width: 2.5)
                                            : null,
                                      ),
                                      child: selected
                                          ? const Icon(Icons.check,
                                              color: Colors.black, size: 16)
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Color(0xFF26363A)),
                        _buildSliderTile(
                          label: 'مستوى السطوع',
                          value: settings.brightness,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          format: (v) => '${(v * 100).toInt()}%',
                          accent: accent,
                          onChanged: (v) =>
                              notifier.update(settings.copyWith(brightness: v)),
                        ),
                        const Divider(color: Color(0xFF26363A)),
                        SwitchListTile(
                          title: const Text('حماية الشاشة من الاحتراق (Burn-in)',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Color(0xFFE8EFEC),
                                  fontSize: 15)),
                          subtitle: const Text(
                              'إزاحة العناصر بكسلات خفيفة كل دقيقة لحماية شاشات AMOLED',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Color(0xFF9DB0AA),
                                  fontSize: 12)),
                          value: settings.burnInProtection,
                          activeColor: accent,
                          onChanged: (v) => notifier
                              .update(settings.copyWith(burnInProtection: v)),
                        ),
                      ],
                    ),
                  ),

                  // ─── Show / Hide Elements ───
                  _buildSectionHeader('عناصر العرض على شاشة القفل'),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildSwitch('الساعة الرقمية', settings.showClock, accent,
                            (v) {
                          notifier.update(settings.copyWith(showClock: v));
                          _syncWallpaperSettings();
                        }),
                        const Divider(color: Color(0xFF26363A)),
                        _buildSwitch(
                            'صف الصلوات الخمس مع الإضاءة',
                            settings.showPrayersRow,
                            accent, (v) {
                          notifier
                              .update(settings.copyWith(showPrayersRow: v));
                          _syncWallpaperSettings();
                        }),
                        const Divider(color: Color(0xFF26363A)),
                        _buildSwitch(
                            'مستوى البطارية',
                            settings.showBattery,
                            accent,
                            (v) => notifier
                                .update(settings.copyWith(showBattery: v))),
                      ],
                    ),
                  ),

                  // ─── Preview Buttons ───
                  _buildSectionHeader('المعاينة والتجربة'),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accent,
                              side: BorderSide(color: accent),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.remove_red_eye),
                            label: const Text('معاينة الشاشة',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold)),
                            onPressed: _previewAod,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.wallpaper),
                            label: const Text('تثبيت كخلفية',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold)),
                            onPressed: _setAsLockscreenWallpaper,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ],
            ),
    );
  }

  Widget _buildWallpaperHeroCard(Color accent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.25),
            const Color(0xFF16211F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.4), width: 1.2),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wallpaper, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'خلفية شاشة القفل الدائمة (AOD)',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'تثبيت مباشر وواقعي كخلفية لقفل الشاشة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'يقوم هذا الخيار بطلب الصلاحيات المطلوبة وفتح معالج أندرويد لتثبيت تطبيق سكينة كخلفية حية لشاشة القفل، لتبقى الساعة ومواقيت الأذان والعد التنازلي معروضة بدقة بوضع الشاشة الدائمة وبأقل استهلاك للطاقة.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: Color(0xFF9DB0AA),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1514),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2E3D39)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFF9DB0AA)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ملاحظة: وفق قيود أندرويد الأمنية، لا يُسمح للتطبيقات بالرسم داخل شاشة AOD الخاصة بالنظام؛ ويوفر تطبيق سكينة الحل المعتمد عبر خلفية حية لشاشة القفل بوضع AMOLED الموفر وبكسلات مطفأة.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Color(0xFF9DB0AA),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.check_circle_outline, size: 22),
            label: const Text(
              'تثبيت التطبيق كخلفية لشاشة القفل الآن',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _setAsLockscreenWallpaper,
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerAdjustmentRow(
    String label,
    String key,
    AppSettings appSettings,
    SettingsNotifier notifier,
    Color accent,
  ) {
    final currentOffset = appSettings.prayerAdjustments[key] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Color(0xFFE8EFEC),
                  fontSize: 15)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Color(0xFF5FB59B), size: 22),
                onPressed: currentOffset > -30
                    ? () {
                        notifier.setPrayerAdjustment(key, currentOffset - 1);
                        _syncWallpaperSettings();
                      }
                    : null,
              ),
              Container(
                alignment: Alignment.center,
                width: 50,
                child: Text(
                  currentOffset == 0
                      ? '0 د'
                      : '${currentOffset > 0 ? "+" : ""}$currentOffset د',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: currentOffset == 0 ? Colors.white70 : accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFF5FB59B), size: 22),
                onPressed: currentOffset < 30
                    ? () {
                        notifier.setPrayerAdjustment(key, currentOffset + 1);
                        _syncWallpaperSettings();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _syncWallpaperSettings() async {
    final settings = ref.read(aodSettingsProvider);
    final appSettings = ref.read(settingsNotifierProvider);
    final accentInt = _colorValue(settings.color).value;

    await AlarmBridge.updateWallpaperSettings(
      clockStyle: settings.clockStyle,
      accentColor: accentInt,
      showHijri: settings.showHijriDate,
      showGregorian: true,
      showCountdown: true,
      showPrayersRow: settings.showPrayersRow,
      hijriOffset: appSettings.hijriOffset,
      useArabicNumerals: appSettings.numeralType == NumeralType.arabic,
    );
  }

  Future<void> _setAsLockscreenWallpaper() async {
    await _syncWallpaperSettings();

    try {
      final success = await AlarmBridge.setAsLockscreenWallpaper();
      if (mounted && success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF16211F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.wallpaper, color: Color(0xFF5FB59B)),
                SizedBox(width: 8),
                Text('تثبيت خلفية القفل',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'تم فتح نافذة نظام أندرويد لمعاينة الخلفية.\n\nاضغط على "تعيين كخلفية" (Set Wallpaper) ثم حدد "شاشة القفل" أو "شاشة القفل والشاشة الرئيسية" لتعمل خلفية سكينة الدائمة (AOD) بشكل مستمر ومباشر.',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Color(0xFFE8EFEC),
                  fontSize: 14,
                  height: 1.6),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً فهمت',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Color(0xFF5FB59B),
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرسال أمر الخلفية: $e',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: const Color(0xFF16211F),
          ),
        );
      }
    }
  }

  Future<void> _previewAod() async {
    final settings = ref.read(aodSettingsProvider);
    final prayerData = {
      'nextPrayer': 'العشاء',
      'nextPrayerTime': '21:30',
      'countdown': '01:45',
      'currentTime': '19:45',
      'hijriDate': '١٤ جمادى الأولى ١٤٤٨',
      'prayers': [
        {'name': 'الفجر', 'time': '05:12', 'passed': true},
        {'name': 'الظهر', 'time': '12:30', 'passed': true},
        {'name': 'العصر', 'time': '15:45', 'passed': true},
        {'name': 'المغرب', 'time': '18:22', 'passed': true},
        {'name': 'العشاء', 'time': '21:30', 'passed': false},
      ],
      'batteryPct': 85,
      'color': settings.color.name,
      'brightness': settings.brightness,
      'showClock': settings.showClock,
      'showHijriDate': settings.showHijriDate,
      'showPrayersRow': settings.showPrayersRow,
      'showBattery': settings.showBattery,
      'pattern': settings.pattern.name,
      'clockStyle': settings.clockStyle,
    };

    try {
      await AlarmBridge.showAodScreen(prayerData);
    } catch (_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AodPreviewScreen(),
          ),
        );
      }
    }
  }

  Widget _buildNotSupported(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android,
                size: 64, color: Color(0xFF5FB59B)),
            const SizedBox(height: 16),
            const Text('الشاشة الدائمة تتطلب إذناً إضافياً',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    color: Color(0xFFE8EFEC),
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'لتشغيل وضع العرض فوق شاشة القفل، يتطلب التطبيق إذن الظهور فوق التطبيقات الأخرى.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Color(0xFF9DB0AA))),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5FB59B),
                  foregroundColor: Colors.black),
              child: const Text('منح الإذن الآن',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              onPressed: () async {
                await AlarmBridge.requestDrawOverApps();
                await _checkSupport();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(title,
          style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: Color(0xFF5FB59B),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF16211F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildSwitch(
      String label, bool value, Color accent, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label,
          style: const TextStyle(
              fontFamily: 'Cairo', color: Color(0xFFE8EFEC), fontSize: 15)),
      value: value,
      activeColor: accent,
      onChanged: onChanged,
    );
  }

  Widget _buildSliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) format,
    required Color accent,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFFE8EFEC),
                      fontSize: 15)),
              Text(format(value),
                  style: TextStyle(
                      fontFamily: 'Cairo', color: accent, fontSize: 14)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: accent,
            inactiveColor: const Color(0xFF2A3D39),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
