// lib/data/settings/settings_repository.dart
// SharedPreferences-backed settings repository with Riverpod providers.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/prayer/prayer_calculator.dart';
import '../../core/utils/alarm_bridge.dart';

// ─────────────────────────── SharedPreferences provider ─────────────────────

/// Must be overridden in ProviderScope with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider not initialised');
});

// ─────────────────────────── Settings model ──────────────────────────────────

enum AppThemeMode { night, day, amoled, systemAuto, sunriseAuto }

enum NumeralType { arabic, western }

enum NotificationMode { shortBeep, silent, vibrate, off }

enum AccentColor { green, gold, white, blue, teal, purple, rose, orange, red, lime }

class AppSettings {
  // ── Location & Calculation ─────────────────────────────────────────────
  final CalculationMethod calculationMethod;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;
  final int hijriOffset; // -2 .. +2
  final Map<String, int> prayerAdjustments; // prayer name → minutes offset

  // ── Notifications ──────────────────────────────────────────────────────
  final Map<String, NotificationMode> prayerNotifications;
  final String selectedAdhanSound;
  final double adhanVolume; // 0.0 .. 1.0
  final bool gradualVolume;
  final int preAdhanReminderMinutes; // 0 = off
  final bool iqamaReminder;
  final bool morningAzkarReminder;
  final bool eveningAzkarReminder;
  final bool fridayReminder;
  final bool fastingReminder;

  // ── Appearance ─────────────────────────────────────────────────────────
  final AppThemeMode themeMode;
  final AccentColor accentColor;
  final double fontSize;
  final NumeralType numeralType;
  final String languageCode; // 'ar', 'en', 'tr'
  final bool showBackgroundDecoration;
  final bool tapSound;
  final bool tapHaptic;
  final bool use24HourTime;
  final double tapVolume;
  final double tapHapticIntensity;
  final bool persistentNotification;

  // ── Azkar ─────────────────────────────────────────────────────────────
  final double azkarFontSize;
  final bool showTashkeel;
  final bool showVirtueAndSource;
  final bool azkarVibration;
  final bool autoAdvanceAzkar;
  final bool keepScreenOnAzkar;

  // ── Qibla ─────────────────────────────────────────────────────────────
  final bool distanceInKm;
  final bool qiblaAlignVibration;

  // ── AOD ───────────────────────────────────────────────────────────────
  final bool aodEnabled;
  final String aodWhenToShow; // 'always', 'adhan', 'charging', 'schedule'
  final int aodBeforeAdhanMin;
  final int aodAfterAdhanMin;
  final int aodAutoOffSeconds;
  final String aodPattern; // 'simple', 'full', 'clock', 'decorative'
  final String aodColor;   // 'green', 'gold', 'white', 'blue'
  final double aodBrightness;
  final bool aodBurnInProtection;
  final bool aodShowClock;
  final bool aodShowHijri;
  final bool aodShowPrayers;
  final bool aodShowBattery;
  final bool aodDisableAirplane;
  final int aodDisableBatteryBelow;
  final bool aodDisablePowerSave;

  const AppSettings({
    this.calculationMethod = CalculationMethod.mwl,
    this.madhab = Madhab.shafi,
    this.highLatitudeRule = HighLatitudeRule.middleOfNight,
    this.hijriOffset = 0,
    this.prayerAdjustments = const {},
    this.prayerNotifications = const {
      'Fajr': NotificationMode.shortBeep,
      'Sunrise': NotificationMode.off,
      'Dhuhr': NotificationMode.shortBeep,
      'Asr': NotificationMode.shortBeep,
      'Maghrib': NotificationMode.shortBeep,
      'Isha': NotificationMode.shortBeep,
    },
    this.selectedAdhanSound = 'adhan_5',
    this.adhanVolume = 1.0,
    this.gradualVolume = false,
    this.preAdhanReminderMinutes = 0,
    this.iqamaReminder = false,
    this.morningAzkarReminder = true,
    this.eveningAzkarReminder = true,
    this.fridayReminder = true,
    this.fastingReminder = false,
    this.themeMode = AppThemeMode.night,
    this.accentColor = AccentColor.green,
    this.fontSize = 1.0,
    this.numeralType = NumeralType.arabic,
    this.languageCode = 'ar',
    this.showBackgroundDecoration = true,
    this.tapSound = true,
    this.tapHaptic = true,
    this.use24HourTime = false,
    this.tapVolume = 0.35,
    this.tapHapticIntensity = 0.25,
    this.persistentNotification = true,
    this.azkarFontSize = 1.0,
    this.showTashkeel = true,
    this.showVirtueAndSource = true,
    this.azkarVibration = false,
    this.autoAdvanceAzkar = false,
    this.keepScreenOnAzkar = true,
    this.distanceInKm = true,
    this.qiblaAlignVibration = true,
    this.aodEnabled = false,
    this.aodWhenToShow = 'adhan',
    this.aodBeforeAdhanMin = 5,
    this.aodAfterAdhanMin = 15,
    this.aodAutoOffSeconds = 0,
    this.aodPattern = 'simple',
    this.aodColor = 'green',
    this.aodBrightness = 0.5,
    this.aodBurnInProtection = true,
    this.aodShowClock = true,
    this.aodShowHijri = true,
    this.aodShowPrayers = true,
    this.aodShowBattery = false,
    this.aodDisableAirplane = true,
    this.aodDisableBatteryBelow = 10,
    this.aodDisablePowerSave = true,
  });

  AppSettings copyWith({
    CalculationMethod? calculationMethod,
    Madhab? madhab,
    HighLatitudeRule? highLatitudeRule,
    int? hijriOffset,
    Map<String, int>? prayerAdjustments,
    Map<String, NotificationMode>? prayerNotifications,
    String? selectedAdhanSound,
    double? adhanVolume,
    bool? gradualVolume,
    int? preAdhanReminderMinutes,
    bool? iqamaReminder,
    bool? morningAzkarReminder,
    bool? eveningAzkarReminder,
    bool? fridayReminder,
    bool? fastingReminder,
    AppThemeMode? themeMode,
    AccentColor? accentColor,
    double? fontSize,
    NumeralType? numeralType,
    String? languageCode,
    bool? showBackgroundDecoration,
    bool? tapSound,
    bool? tapHaptic,
    bool? use24HourTime,
    double? tapVolume,
    double? tapHapticIntensity,
    bool? persistentNotification,
    double? azkarFontSize,
    bool? showTashkeel,
    bool? showVirtueAndSource,
    bool? azkarVibration,
    bool? autoAdvanceAzkar,
    bool? keepScreenOnAzkar,
    bool? distanceInKm,
    bool? qiblaAlignVibration,
    bool? aodEnabled,
    String? aodWhenToShow,
    int? aodBeforeAdhanMin,
    int? aodAfterAdhanMin,
    int? aodAutoOffSeconds,
    String? aodPattern,
    String? aodColor,
    double? aodBrightness,
    bool? aodBurnInProtection,
    bool? aodShowClock,
    bool? aodShowHijri,
    bool? aodShowPrayers,
    bool? aodShowBattery,
    bool? aodDisableAirplane,
    int? aodDisableBatteryBelow,
    bool? aodDisablePowerSave,
  }) {
    return AppSettings(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      hijriOffset: hijriOffset ?? this.hijriOffset,
      prayerAdjustments: prayerAdjustments ?? this.prayerAdjustments,
      prayerNotifications: prayerNotifications ?? this.prayerNotifications,
      selectedAdhanSound: selectedAdhanSound ?? this.selectedAdhanSound,
      adhanVolume: adhanVolume ?? this.adhanVolume,
      gradualVolume: gradualVolume ?? this.gradualVolume,
      preAdhanReminderMinutes: preAdhanReminderMinutes ?? this.preAdhanReminderMinutes,
      iqamaReminder: iqamaReminder ?? this.iqamaReminder,
      morningAzkarReminder: morningAzkarReminder ?? this.morningAzkarReminder,
      eveningAzkarReminder: eveningAzkarReminder ?? this.eveningAzkarReminder,
      fridayReminder: fridayReminder ?? this.fridayReminder,
      fastingReminder: fastingReminder ?? this.fastingReminder,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      fontSize: fontSize ?? this.fontSize,
      numeralType: numeralType ?? this.numeralType,
      languageCode: languageCode ?? this.languageCode,
      showBackgroundDecoration:
          showBackgroundDecoration ?? this.showBackgroundDecoration,
      tapSound: tapSound ?? this.tapSound,
      tapHaptic: tapHaptic ?? this.tapHaptic,
      use24HourTime: use24HourTime ?? this.use24HourTime,
      tapVolume: tapVolume ?? this.tapVolume,
      tapHapticIntensity: tapHapticIntensity ?? this.tapHapticIntensity,
      persistentNotification: persistentNotification ?? this.persistentNotification,
      azkarFontSize: azkarFontSize ?? this.azkarFontSize,
      showTashkeel: showTashkeel ?? this.showTashkeel,
      showVirtueAndSource: showVirtueAndSource ?? this.showVirtueAndSource,
      azkarVibration: azkarVibration ?? this.azkarVibration,
      autoAdvanceAzkar: autoAdvanceAzkar ?? this.autoAdvanceAzkar,
      keepScreenOnAzkar: keepScreenOnAzkar ?? this.keepScreenOnAzkar,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      qiblaAlignVibration: qiblaAlignVibration ?? this.qiblaAlignVibration,
      aodEnabled: aodEnabled ?? this.aodEnabled,
      aodWhenToShow: aodWhenToShow ?? this.aodWhenToShow,
      aodBeforeAdhanMin: aodBeforeAdhanMin ?? this.aodBeforeAdhanMin,
      aodAfterAdhanMin: aodAfterAdhanMin ?? this.aodAfterAdhanMin,
      aodAutoOffSeconds: aodAutoOffSeconds ?? this.aodAutoOffSeconds,
      aodPattern: aodPattern ?? this.aodPattern,
      aodColor: aodColor ?? this.aodColor,
      aodBrightness: aodBrightness ?? this.aodBrightness,
      aodBurnInProtection: aodBurnInProtection ?? this.aodBurnInProtection,
      aodShowClock: aodShowClock ?? this.aodShowClock,
      aodShowHijri: aodShowHijri ?? this.aodShowHijri,
      aodShowPrayers: aodShowPrayers ?? this.aodShowPrayers,
      aodShowBattery: aodShowBattery ?? this.aodShowBattery,
      aodDisableAirplane: aodDisableAirplane ?? this.aodDisableAirplane,
      aodDisableBatteryBelow:
          aodDisableBatteryBelow ?? this.aodDisableBatteryBelow,
      aodDisablePowerSave: aodDisablePowerSave ?? this.aodDisablePowerSave,
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'calculationMethod': calculationMethod.name,
        'madhab': madhab.name,
        'highLatitudeRule': highLatitudeRule.name,
        'hijriOffset': hijriOffset,
        'prayerAdjustments': prayerAdjustments,
        'prayerNotifications':
            prayerNotifications.map((k, v) => MapEntry(k, v.name)),
        'selectedAdhanSound': selectedAdhanSound,
        'adhanVolume': adhanVolume,
        'gradualVolume': gradualVolume,
        'preAdhanReminderMinutes': preAdhanReminderMinutes,
        'iqamaReminder': iqamaReminder,
        'morningAzkarReminder': morningAzkarReminder,
        'eveningAzkarReminder': eveningAzkarReminder,
        'fridayReminder': fridayReminder,
        'fastingReminder': fastingReminder,
        'themeMode': themeMode.name,
        'accentColor': accentColor.name,
        'fontSize': fontSize,
        'numeralType': numeralType.name,
        'languageCode': languageCode,
        'showBackgroundDecoration': showBackgroundDecoration,
        'tapSound': tapSound,
        'tapHaptic': tapHaptic,
        'use24HourTime': use24HourTime,
        'tapVolume': tapVolume,
        'tapHapticIntensity': tapHapticIntensity,
        'persistentNotification': persistentNotification,
        'azkarFontSize': azkarFontSize,
        'showTashkeel': showTashkeel,
        'showVirtueAndSource': showVirtueAndSource,
        'azkarVibration': azkarVibration,
        'autoAdvanceAzkar': autoAdvanceAzkar,
        'keepScreenOnAzkar': keepScreenOnAzkar,
        'distanceInKm': distanceInKm,
        'qiblaAlignVibration': qiblaAlignVibration,
        'aodEnabled': aodEnabled,
        'aodWhenToShow': aodWhenToShow,
        'aodBeforeAdhanMin': aodBeforeAdhanMin,
        'aodAfterAdhanMin': aodAfterAdhanMin,
        'aodAutoOffSeconds': aodAutoOffSeconds,
        'aodPattern': aodPattern,
        'aodColor': aodColor,
        'aodBrightness': aodBrightness,
        'aodBurnInProtection': aodBurnInProtection,
        'aodShowClock': aodShowClock,
        'aodShowHijri': aodShowHijri,
        'aodShowPrayers': aodShowPrayers,
        'aodShowBattery': aodShowBattery,
        'aodDisableAirplane': aodDisableAirplane,
        'aodDisableBatteryBelow': aodDisableBatteryBelow,
        'aodDisablePowerSave': aodDisablePowerSave,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    T en<T>(List<T> values, String? name, T fallback) =>
        values.firstWhere((v) => (v as dynamic).name == name,
            orElse: () => fallback);

    return AppSettings(
      calculationMethod: en(CalculationMethod.values,
          j['calculationMethod'] as String?, CalculationMethod.mwl),
      madhab: en(Madhab.values, j['madhab'] as String?, Madhab.shafi),
      highLatitudeRule: en(HighLatitudeRule.values,
          j['highLatitudeRule'] as String?, HighLatitudeRule.middleOfNight),
      hijriOffset: (j['hijriOffset'] as int?) ?? 0,
      prayerAdjustments:
          ((j['prayerAdjustments'] as Map<String, dynamic>?) ?? {})
              .map((k, v) => MapEntry(k, v as int)),
      prayerNotifications:
          ((j['prayerNotifications'] as Map<String, dynamic>?) ?? {}).map(
              (k, v) => MapEntry(
                  k,
                  en(NotificationMode.values, v as String?,
                      NotificationMode.shortBeep))),
      selectedAdhanSound:
          (j['selectedAdhanSound'] as String?) ?? 'adhan_5',
      adhanVolume: (j['adhanVolume'] as num?)?.toDouble() ?? 1.0,
      gradualVolume: (j['gradualVolume'] as bool?) ?? false,
      preAdhanReminderMinutes: (j['preAdhanReminderMinutes'] as int?) ?? 0,
      iqamaReminder: (j['iqamaReminder'] as bool?) ?? false,
      morningAzkarReminder: (j['morningAzkarReminder'] as bool?) ?? true,
      eveningAzkarReminder: (j['eveningAzkarReminder'] as bool?) ?? true,
      fridayReminder: (j['fridayReminder'] as bool?) ?? true,
      fastingReminder: (j['fastingReminder'] as bool?) ?? false,
      themeMode: en(AppThemeMode.values, j['themeMode'] as String?,
          AppThemeMode.night),
      accentColor: en(
          AccentColor.values, j['accentColor'] as String?, AccentColor.green),
      fontSize: (j['fontSize'] as num?)?.toDouble() ?? 1.0,
      numeralType: en(NumeralType.values, j['numeralType'] as String?,
          NumeralType.arabic),
      languageCode: (j['languageCode'] as String?) ?? 'ar',
      showBackgroundDecoration:
          (j['showBackgroundDecoration'] as bool?) ?? true,
      tapSound: (j['tapSound'] as bool?) ?? true,
      tapHaptic: (j['tapHaptic'] as bool?) ?? true,
      use24HourTime: (j['use24HourTime'] as bool?) ?? false,
      tapVolume: ((j['tapVolume'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0),
      tapHapticIntensity: ((j['tapHapticIntensity'] as num?)?.toDouble() ?? 0.25).clamp(0.0, 1.0),
      persistentNotification: (j['persistentNotification'] as bool?) ?? true,
      azkarFontSize: (j['azkarFontSize'] as num?)?.toDouble() ?? 1.0,
      showTashkeel: (j['showTashkeel'] as bool?) ?? true,
      showVirtueAndSource: (j['showVirtueAndSource'] as bool?) ?? true,
      azkarVibration: (j['azkarVibration'] as bool?) ?? false,
      autoAdvanceAzkar: (j['autoAdvanceAzkar'] as bool?) ?? false,
      keepScreenOnAzkar: (j['keepScreenOnAzkar'] as bool?) ?? true,
      distanceInKm: (j['distanceInKm'] as bool?) ?? true,
      qiblaAlignVibration: (j['qiblaAlignVibration'] as bool?) ?? true,
      aodEnabled: (j['aodEnabled'] as bool?) ?? false,
      aodWhenToShow: (j['aodWhenToShow'] as String?) ?? 'adhan',
      aodBeforeAdhanMin: (j['aodBeforeAdhanMin'] as int?) ?? 5,
      aodAfterAdhanMin: (j['aodAfterAdhanMin'] as int?) ?? 15,
      aodAutoOffSeconds: (j['aodAutoOffSeconds'] as int?) ?? 0,
      aodPattern: (j['aodPattern'] as String?) ?? 'simple',
      aodColor: (j['aodColor'] as String?) ?? 'green',
      aodBrightness: (j['aodBrightness'] as num?)?.toDouble() ?? 0.5,
      aodBurnInProtection: (j['aodBurnInProtection'] as bool?) ?? true,
      aodShowClock: (j['aodShowClock'] as bool?) ?? true,
      aodShowHijri: (j['aodShowHijri'] as bool?) ?? true,
      aodShowPrayers: (j['aodShowPrayers'] as bool?) ?? true,
      aodShowBattery: (j['aodShowBattery'] as bool?) ?? false,
      aodDisableAirplane: (j['aodDisableAirplane'] as bool?) ?? true,
      aodDisableBatteryBelow: (j['aodDisableBatteryBelow'] as int?) ?? 10,
      aodDisablePowerSave: (j['aodDisablePowerSave'] as bool?) ?? true,
    );
  }
}

// ─────────────────────────── Notifier ───────────────────────────────────────

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const _key = 'app_settings_v1';
  static const _themeKey = 'sakina_theme_mode';
  static const _accentKey = 'sakina_accent_color';
  final SharedPreferences _prefs;
  Future<void> _pendingSave = Future.value();

  SettingsNotifier(this._prefs) : super(const AppSettings()) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    try {
      if (raw == null) throw const FormatException('Missing settings snapshot');
      state = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A damaged or older settings payload must not erase the chosen theme.
      final theme = AppThemeMode.values.firstWhere(
          (v) => v.name == _prefs.getString(_themeKey),
          orElse: () => AppThemeMode.night);
      final accent = AccentColor.values.firstWhere(
          (v) => v.name == _prefs.getString(_accentKey),
          orElse: () => AccentColor.green);
      state = AppSettings(themeMode: theme, accentColor: accent);
    }
  }

  Future<void> _save() {
    // Capture this exact revision and serialize writes: rapid selection changes
    // must not let an earlier disk write finish after the final selection.
    final snapshot = state;
    _pendingSave = _pendingSave.catchError((_) {}).then((_) async {
      await _prefs.setString(_key, jsonEncode(snapshot.toJson()));
      await _prefs.setString(_themeKey, snapshot.themeMode.name);
      await _prefs.setString(_accentKey, snapshot.accentColor.name);
    });
    return _pendingSave;
  }

  Future<void> update(AppSettings Function(AppSettings) updater) async {
    final previousTimeFormat = state.use24HourTime;
    state = updater(state);
    await _save();
    if (previousTimeFormat != state.use24HourTime) {
      await AlarmBridge.refreshTimeDisplays();
    }
  }

  // ── Convenience setters ───────────────────────────────────────────────

  Future<void> setCalculationMethod(CalculationMethod m) =>
      update((s) => s.copyWith(calculationMethod: m));

  Future<void> setMadhab(Madhab m) =>
      update((s) => s.copyWith(madhab: m));

  Future<void> setHighLatitudeRule(HighLatitudeRule r) =>
      update((s) => s.copyWith(highLatitudeRule: r));

  Future<void> setHijriOffset(int o) =>
      update((s) => s.copyWith(hijriOffset: o));

  Future<void> setPrayerAdjustment(String prayer, int minutes) => update((s) {
        final map = Map<String, int>.from(s.prayerAdjustments);
        map[prayer] = minutes;
        return s.copyWith(prayerAdjustments: map);
      });

  Future<void> setPrayerNotification(String prayer, NotificationMode mode) =>
      update((s) {
        final map = Map<String, NotificationMode>.from(s.prayerNotifications);
        map[prayer] = mode;
        return s.copyWith(prayerNotifications: map);
      });

  Future<void> setThemeMode(AppThemeMode m) =>
      update((s) => s.copyWith(themeMode: m));

  Future<void> setLanguage(String code) =>
      update((s) => s.copyWith(languageCode: code));

  Future<void> setAdhanSound(String sound) =>
      update((s) => s.copyWith(selectedAdhanSound: sound));

  Future<void> setAdhanVolume(double v) =>
      update((s) => s.copyWith(adhanVolume: v));

  Future<void> setAodEnabled(bool v) =>
      update((s) => s.copyWith(aodEnabled: v));

  Future<void> setNumeralType(NumeralType t) =>
      update((s) => s.copyWith(numeralType: t));

  /// Export all settings as JSON string.
  String exportJson() => jsonEncode(state.toJson());

  /// Import settings from JSON string.
  Future<void> importJson(String raw) async {
    state = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    await _save();
  }

  /// Reset to defaults.
  Future<void> reset() async {
    state = const AppSettings();
    await _save();
  }
}

// ─────────────────────────── Providers ──────────────────────────────────────

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

/// Read-only convenience alias.
final appSettingsProvider = Provider<AppSettings>((ref) {
  return ref.watch(settingsNotifierProvider);
});
