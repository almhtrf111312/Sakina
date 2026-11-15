/// Global application constants for Sakina (سكينة)
abstract final class AppConstants {
  AppConstants._();

  // App Identity
  static const String appName = 'المؤذن';
  static const String appNameEn = 'Al Muadhin';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;
  static const String packageName = 'com.sakina.app';

  // Geographic Coordinates - Holy Kaaba, Mecca, Saudi Arabia
  static const double meccaLatitude = 21.4225;
  static const double meccaLongitude = 39.8262;
  static const double meccaAltitude = 277.0; // meters above sea level
  static const double earthRadiusKm = 6371.0;

  // Notification Channel IDs
  static const String prayerChannelId = 'sakina_prayer_notifications';
  static const String prayerChannelName = 'مواقيت الصلاة والأذان';
  static const String prayerChannelDesc = 'تنبيهات مواقيت الصلاة والأذان بصوت كامل';

  static const String azkarChannelId = 'sakina_azkar_notifications';
  static const String azkarChannelName = 'تنبيهات الأذكار';
  static const String azkarChannelDesc = 'تذكيرات أذكار الصباح والمساء وأذكار النوم';

  static const String aodChannelId = 'sakina_aod_service';
  static const String aodChannelName = 'خدمة الشاشة الدائمة (AOD)';
  static const String aodChannelDesc = 'خدمة خلفية لتشغيل شاشة العرض الدائم عند حلول الصلاة';

  // Shared Preferences Keys
  static const String keyThemeMode = 'sakina_theme_mode';
  static const String keyLanguage = 'sakina_language';
  static const String keyCalculationMethod = 'sakina_calc_method';
  static const String keyMadhab = 'sakina_madhab';
  static const String keyHighLatitudeRule = 'sakina_high_lat_rule';
  static const String keyPrayerAdjustments = 'sakina_prayer_adjustments';
  static const String keyNotificationSettings = 'sakina_notif_settings';
  static const String keyAdhanSound = 'sakina_adhan_sound';
  static const String keyAodSettings = 'sakina_aod_settings';
  static const String keyLastLatitude = 'sakina_last_latitude';
  static const String keyLastLongitude = 'sakina_last_longitude';
  static const String keyLastCity = 'sakina_last_city';
  static const String keyTasbihTarget = 'sakina_tasbih_target';
  static const String keyTasbihCount = 'sakina_tasbih_count';
  static const String keyTasbihTotal = 'sakina_tasbih_total';
  static const String keyTasbihHaptic = 'sakina_tasbih_haptic';
  static const String keyTasbihSound = 'sakina_tasbih_sound';

  // Timing & Refresh Constants
  static const Duration countdownInterval = Duration(seconds: 1);
  static const Duration locationTimeout = Duration(seconds: 15);
  static const Duration locationCacheValidDuration = Duration(hours: 6);
  static const double locationDistanceFilterMeters = 500.0;
  static const double locationMovementThresholdKm = 20.0;

  // Compass & Sensor Constants
  static const double compassLowPassAlpha = 0.15;
  static const double qiblaFacingThresholdDegrees = 4.0; // considered pointing directly to Qibla
  static const Duration compassSampleInterval = Duration(milliseconds: 50);

  // AOD Constants
  static const int aodDefaultPreMinutes = 15;
  static const int aodDefaultPostMinutes = 30;
  static const double aodDefaultBrightness = 0.2;

  // Assets Paths
  static const String fontAmiri = 'Amiri';
  static const String fontCairo = 'Cairo';
  static const String azkarJsonPath = 'assets/data/azkar.json';
  static const String defaultAdhanSoundPath = 'assets/audio/adhan_makkah.mp3';

  // Prayer Keys (Internal identifier strings)
  static const String prayerFajr = 'fajr';
  static const String prayerSunrise = 'sunrise';
  static const String prayerDhuhr = 'dhuhr';
  static const String prayerAsr = 'asr';
  static const String prayerMaghrib = 'maghrib';
  static const String prayerIsha = 'isha';

  static const List<String> prayerKeys = [
    prayerFajr,
    prayerSunrise,
    prayerDhuhr,
    prayerAsr,
    prayerMaghrib,
    prayerIsha,
  ];

  static const List<String> fardPrayerKeys = [
    prayerFajr,
    prayerDhuhr,
    prayerAsr,
    prayerMaghrib,
    prayerIsha,
  ];
}
