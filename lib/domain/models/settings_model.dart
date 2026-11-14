import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/settings/settings_repository.dart' show AppThemeMode;
import 'prayer_time_model.dart';

export '../../data/settings/settings_repository.dart' show AppThemeMode;

/// Supported application languages.
enum AppLanguage {
  arabic('ar', 'العربية'),
  english('en', 'English'),
  turkish('tr', 'Türkçe');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.arabic,
    );
  }
}

/// Notification type for each prayer time.
enum PrayerNotificationType {
  adhan, // Full vocal adhan audio
  beep, // Brief subtle takbir or chime
  silent, // Silent push notification only
  off, // No notification
}

/// Comprehensive Always-On Display (AOD) settings.
class AodSettings {
  final bool enabled;
  final double brightness; // 0.05 to 1.0
  final bool showHijri;
  final bool showNextPrayer;
  final bool showPrayerRow;
  final bool burnInProtection;
  final int preMinutes; // Minutes before adhan to trigger AOD
  final int postMinutes; // Minutes after adhan to keep AOD active
  final String accentColor; // 'green', 'gold', 'white', 'blue'

  const AodSettings({
    this.enabled = true,
    this.brightness = 0.2,
    this.showHijri = true,
    this.showNextPrayer = true,
    this.showPrayerRow = true,
    this.burnInProtection = true,
    this.preMinutes = 15,
    this.postMinutes = 30,
    this.accentColor = 'green',
  });

  AodSettings copyWith({
    bool? enabled,
    double? brightness,
    bool? showHijri,
    bool? showNextPrayer,
    bool? showPrayerRow,
    bool? burnInProtection,
    int? preMinutes,
    int? postMinutes,
    String? accentColor,
  }) {
    return AodSettings(
      enabled: enabled ?? this.enabled,
      brightness: brightness ?? this.brightness,
      showHijri: showHijri ?? this.showHijri,
      showNextPrayer: showNextPrayer ?? this.showNextPrayer,
      showPrayerRow: showPrayerRow ?? this.showPrayerRow,
      burnInProtection: burnInProtection ?? this.burnInProtection,
      preMinutes: preMinutes ?? this.preMinutes,
      postMinutes: postMinutes ?? this.postMinutes,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'brightness': brightness,
        'showHijri': showHijri,
        'showNextPrayer': showNextPrayer,
        'showPrayerRow': showPrayerRow,
        'burnInProtection': burnInProtection,
        'preMinutes': preMinutes,
        'postMinutes': postMinutes,
        'accentColor': accentColor,
      };

  factory AodSettings.fromJson(Map<String, dynamic> json) {
    return AodSettings(
      enabled: json['enabled'] as bool? ?? true,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.2,
      showHijri: json['showHijri'] as bool? ?? true,
      showNextPrayer: json['showNextPrayer'] as bool? ?? true,
      showPrayerRow: json['showPrayerRow'] as bool? ?? true,
      burnInProtection: json['burnInProtection'] as bool? ?? true,
      preMinutes: json['preMinutes'] as int? ?? 15,
      postMinutes: json['postMinutes'] as int? ?? 30,
      accentColor: json['accentColor'] as String? ?? 'green',
    );
  }
}

/// Global settings state model for Sakina.
@Deprecated('Use AppSettings and appSettingsProvider from settings_repository.dart')
@immutable
class SettingsModel {
  final AppThemeMode themeMode;
  final AppLanguage language;
  final CalculationMethod calculationMethod;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;
  final Map<String, int> prayerAdjustments; // Minutes offset per prayer key
  final Map<String, PrayerNotificationType> prayerNotifications;
  final String adhanSound; // e.g. 'makkah', 'madinah', 'aqsa', 'cairo'
  final AodSettings aodSettings;
  final bool hapticFeedbackEnabled;
  final bool clickSoundEnabled;
  final bool keepScreenOnAzkar;
  final double azkarFontSize;
  final int hijriAdjustmentDays; // Moon sighting offset (-2 to +2)
  final String? manualCity;
  final double? manualLatitude;
  final double? manualLongitude;

  const SettingsModel({
    this.themeMode = AppThemeMode.night,
    this.language = AppLanguage.arabic,
    this.calculationMethod = CalculationMethod.makkah,
    this.madhab = Madhab.shafi,
    this.highLatitudeRule = HighLatitudeRule.angleBased,
    this.prayerAdjustments = const {
      AppConstants.prayerFajr: 0,
      AppConstants.prayerSunrise: 0,
      AppConstants.prayerDhuhr: 0,
      AppConstants.prayerAsr: 0,
      AppConstants.prayerMaghrib: 0,
      AppConstants.prayerIsha: 0,
    },
    this.prayerNotifications = const {
      AppConstants.prayerFajr: PrayerNotificationType.adhan,
      AppConstants.prayerSunrise: PrayerNotificationType.silent,
      AppConstants.prayerDhuhr: PrayerNotificationType.adhan,
      AppConstants.prayerAsr: PrayerNotificationType.adhan,
      AppConstants.prayerMaghrib: PrayerNotificationType.adhan,
      AppConstants.prayerIsha: PrayerNotificationType.adhan,
    },
    this.adhanSound = 'makkah',
    this.aodSettings = const AodSettings(),
    this.hapticFeedbackEnabled = true,
    this.clickSoundEnabled = false,
    this.keepScreenOnAzkar = true,
    this.azkarFontSize = 24.0,
    this.hijriAdjustmentDays = 0,
    this.manualCity,
    this.manualLatitude,
    this.manualLongitude,
  });

  SettingsModel copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
    HighLatitudeRule? highLatitudeRule,
    Map<String, int>? prayerAdjustments,
    Map<String, PrayerNotificationType>? prayerNotifications,
    String? adhanSound,
    AodSettings? aodSettings,
    bool? hapticFeedbackEnabled,
    bool? clickSoundEnabled,
    bool? keepScreenOnAzkar,
    double? azkarFontSize,
    int? hijriAdjustmentDays,
    String? manualCity,
    double? manualLatitude,
    double? manualLongitude,
  }) {
    return SettingsModel(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      prayerAdjustments: prayerAdjustments ?? this.prayerAdjustments,
      prayerNotifications: prayerNotifications ?? this.prayerNotifications,
      adhanSound: adhanSound ?? this.adhanSound,
      aodSettings: aodSettings ?? this.aodSettings,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      clickSoundEnabled: clickSoundEnabled ?? this.clickSoundEnabled,
      keepScreenOnAzkar: keepScreenOnAzkar ?? this.keepScreenOnAzkar,
      azkarFontSize: azkarFontSize ?? this.azkarFontSize,
      hijriAdjustmentDays: hijriAdjustmentDays ?? this.hijriAdjustmentDays,
      manualCity: manualCity ?? this.manualCity,
      manualLatitude: manualLatitude ?? this.manualLatitude,
      manualLongitude: manualLongitude ?? this.manualLongitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'language': language.code,
        'calculationMethod': calculationMethod.name,
        'madhab': madhab.name,
        'highLatitudeRule': highLatitudeRule.name,
        'prayerAdjustments': prayerAdjustments,
        'prayerNotifications': prayerNotifications.map((k, v) => MapEntry(k, v.name)),
        'adhanSound': adhanSound,
        'aodSettings': aodSettings.toJson(),
        'hapticFeedbackEnabled': hapticFeedbackEnabled,
        'clickSoundEnabled': clickSoundEnabled,
        'keepScreenOnAzkar': keepScreenOnAzkar,
        'azkarFontSize': azkarFontSize,
        'hijriAdjustmentDays': hijriAdjustmentDays,
        'manualCity': manualCity,
        'manualLatitude': manualLatitude,
        'manualLongitude': manualLongitude,
      };

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    final adjustmentsRaw = json['prayerAdjustments'];
    final notifsRaw = json['prayerNotifications'] as Map<String, dynamic>?;

    return SettingsModel(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == json['themeMode'],
        orElse: () => AppThemeMode.night,
      ),
      language: AppLanguage.fromCode(json['language'] as String? ?? 'ar'),
      calculationMethod: CalculationMethod.values.firstWhere(
        (m) => m.name == json['calculationMethod'],
        orElse: () => CalculationMethod.makkah,
      ),
      madhab: Madhab.values.firstWhere(
        (m) => m.name == json['madhab'],
        orElse: () => Madhab.shafi,
      ),
      highLatitudeRule: HighLatitudeRule.values.firstWhere(
        (r) => r.name == json['highLatitudeRule'],
        orElse: () => HighLatitudeRule.angleBased,
      ),
      prayerAdjustments: adjustmentsRaw is Map
          ? adjustmentsRaw.map((k, v) => MapEntry(k.toString(), v as int))
          : const {},
      prayerNotifications: notifsRaw != null
          ? notifsRaw.map((k, v) => MapEntry(
                k,
                PrayerNotificationType.values.firstWhere(
                  (t) => t.name == v,
                  orElse: () => PrayerNotificationType.adhan,
                ),
              ))
          : const {},
      adhanSound: json['adhanSound'] as String? ?? 'makkah',
      aodSettings: json['aodSettings'] != null
          ? AodSettings.fromJson(json['aodSettings'] as Map<String, dynamic>)
          : const AodSettings(),
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] as bool? ?? true,
      clickSoundEnabled: json['clickSoundEnabled'] as bool? ?? false,
      keepScreenOnAzkar: json['keepScreenOnAzkar'] as bool? ?? true,
      azkarFontSize: (json['azkarFontSize'] as num?)?.toDouble() ?? 24.0,
      hijriAdjustmentDays: json['hijriAdjustmentDays'] as int? ?? 0,
      manualCity: json['manualCity'] as String?,
      manualLatitude: (json['manualLatitude'] as num?)?.toDouble(),
      manualLongitude: (json['manualLongitude'] as num?)?.toDouble(),
    );
  }
}

/// StateNotifier controlling the application settings.
@Deprecated('Use settingsNotifierProvider from settings_repository.dart')
class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier([SettingsModel? initial]) : super(initial ?? const SettingsModel());

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setLanguage(AppLanguage language) {
    state = state.copyWith(language: language);
  }

  void setCalculationMethod(CalculationMethod method) {
    state = state.copyWith(calculationMethod: method);
  }

  void setMadhab(Madhab madhab) {
    state = state.copyWith(madhab: madhab);
  }

  void setPrayerAdjustment(String prayerKey, int minutes) {
    final updated = Map<String, int>.from(state.prayerAdjustments);
    updated[prayerKey] = minutes;
    state = state.copyWith(prayerAdjustments: updated);
  }

  void setPrayerNotification(String prayerKey, PrayerNotificationType type) {
    final updated = Map<String, PrayerNotificationType>.from(state.prayerNotifications);
    updated[prayerKey] = type;
    state = state.copyWith(prayerNotifications: updated);
  }

  void setAdhanSound(String sound) {
    state = state.copyWith(adhanSound: sound);
  }

  void updateAodSettings(AodSettings aod) {
    state = state.copyWith(aodSettings: aod);
  }

  void setHaptic(bool enabled) {
    state = state.copyWith(hapticFeedbackEnabled: enabled);
  }

  void setKeepScreenOnAzkar(bool keep) {
    state = state.copyWith(keepScreenOnAzkar: keep);
  }

  void setAzkarFontSize(double size) {
    state = state.copyWith(azkarFontSize: size);
  }

  void setHijriAdjustment(int days) {
    state = state.copyWith(hijriAdjustmentDays: days);
  }

  void setManualLocation({
    required String city,
    required double latitude,
    required double longitude,
  }) {
    state = state.copyWith(
      manualCity: city,
      manualLatitude: latitude,
      manualLongitude: longitude,
    );
  }
}
