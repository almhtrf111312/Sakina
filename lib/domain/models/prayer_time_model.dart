import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';

/// Supported astronomical calculation methods.
enum CalculationMethod {
  mwl, // Muslim World League
  isna, // Islamic Society of North America
  egyptian, // Egyptian General Authority of Survey
  makkah, // Umm al-Qura University, Makkah
  karachi, // University of Islamic Sciences, Karachi
  tehran, // Institute of Geophysics, University of Tehran
  jafari, // Shia Ithna Ashari (Leveau)
  turkey, // Diyanet İşleri Başkanlığı
  dubai, // Dubai / UAE
  kuwait, // Kuwait Awqaf
  qatar, // Qatar
  singapore, // MUIS
  custom, // User-defined angles
}

/// Juristic school for Asr prayer time calculation.
enum Madhab {
  shafi, // Shadow length = object length + noon shadow (Shafi, Maliki, Hanbali)
  hanafi, // Shadow length = 2 * object length + noon shadow
}

/// Rules for resolving prayer times in high latitude regions.
enum HighLatitudeRule {
  middleOfTheNight,
  seventhOfTheNight,
  angleBased,
  none,
}

/// Immutable model representing the computed prayer schedule for a single day.
@immutable
class PrayerTimeModel {
  final DateTime date; // Gregorian date
  final HijriDate hijriDate;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime? midnight;
  final DateTime? qiyam; // Last third of night

  final CalculationMethod method;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;
  final Map<String, int> adjustments; // in minutes per prayer

  const PrayerTimeModel({
    required this.date,
    required this.hijriDate,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.midnight,
    this.qiyam,
    this.method = CalculationMethod.makkah,
    this.madhab = Madhab.shafi,
    this.highLatitudeRule = HighLatitudeRule.angleBased,
    this.adjustments = const {},
  });

  /// Map of prayer keys to DateTime.
  Map<String, DateTime> get asMap => {
        AppConstants.prayerFajr: fajr,
        AppConstants.prayerSunrise: sunrise,
        AppConstants.prayerDhuhr: dhuhr,
        AppConstants.prayerAsr: asr,
        AppConstants.prayerMaghrib: maghrib,
        AppConstants.prayerIsha: isha,
      };

  /// Returns the specific prayer time by key.
  DateTime? getTime(String key) => asMap[key.toLowerCase()];

  /// Returns the next upcoming prayer from a given reference time.
  /// If all prayers today have passed, returns Fajr of tomorrow (or next Fajr).
  PrayerEntry getNextPrayer([DateTime? fromTime]) {
    final now = fromTime ?? DateTime.now();

    final prayers = [
      PrayerEntry(AppConstants.prayerFajr, fajr),
      PrayerEntry(AppConstants.prayerSunrise, sunrise),
      PrayerEntry(AppConstants.prayerDhuhr, dhuhr),
      PrayerEntry(AppConstants.prayerAsr, asr),
      PrayerEntry(AppConstants.prayerMaghrib, maghrib),
      PrayerEntry(AppConstants.prayerIsha, isha),
    ];

    for (final p in prayers) {
      if (p.time.isAfter(now)) {
        return p;
      }
    }

    // After Isha: next is tomorrow's Fajr
    final nextFajr = fajr.add(const Duration(days: 1));
    return PrayerEntry(AppConstants.prayerFajr, nextFajr);
  }

  /// Returns the current active prayer (the prayer whose time has arrived most recently).
  PrayerEntry getCurrentPrayer([DateTime? fromTime]) {
    final now = fromTime ?? DateTime.now();

    if (now.isBefore(fajr)) {
      // Prior to today's Fajr: Isha from previous night
      return PrayerEntry(AppConstants.prayerIsha, isha.subtract(const Duration(days: 1)));
    } else if (now.isBefore(sunrise)) {
      return PrayerEntry(AppConstants.prayerFajr, fajr);
    } else if (now.isBefore(dhuhr)) {
      return PrayerEntry(AppConstants.prayerSunrise, sunrise);
    } else if (now.isBefore(asr)) {
      return PrayerEntry(AppConstants.prayerDhuhr, dhuhr);
    } else if (now.isBefore(maghrib)) {
      return PrayerEntry(AppConstants.prayerAsr, asr);
    } else if (now.isBefore(isha)) {
      return PrayerEntry(AppConstants.prayerMaghrib, maghrib);
    } else {
      return PrayerEntry(AppConstants.prayerIsha, isha);
    }
  }

  /// Calculates progress between previous prayer and next prayer (0.0 to 1.0).
  double getProgressToNext([DateTime? fromTime]) {
    final now = fromTime ?? DateTime.now();
    final current = getCurrentPrayer(now);
    final next = getNextPrayer(now);

    final totalMillis = next.time.difference(current.time).inMilliseconds;
    if (totalMillis <= 0) return 0.0;

    final elapsedMillis = now.difference(current.time).inMilliseconds;
    return (elapsedMillis / totalMillis).clamp(0.0, 1.0);
  }

  /// Serialization to JSON
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'hijriYear': hijriDate.year,
        'hijriMonth': hijriDate.month,
        'hijriDay': hijriDate.day,
        'hijriDayOfWeek': hijriDate.dayOfWeek,
        'fajr': fajr.toIso8601String(),
        'sunrise': sunrise.toIso8601String(),
        'dhuhr': dhuhr.toIso8601String(),
        'asr': asr.toIso8601String(),
        'maghrib': maghrib.toIso8601String(),
        'isha': isha.toIso8601String(),
        'midnight': midnight?.toIso8601String(),
        'qiyam': qiyam?.toIso8601String(),
        'method': method.name,
        'madhab': madhab.name,
        'highLatitudeRule': highLatitudeRule.name,
        'adjustments': adjustments,
      };

  /// Deserialization from JSON
  factory PrayerTimeModel.fromJson(Map<String, dynamic> json) {
    return PrayerTimeModel(
      date: DateTime.parse(json['date'] as String),
      hijriDate: HijriDate(
        year: json['hijriYear'] as int? ?? 1447,
        month: json['hijriMonth'] as int? ?? 1,
        day: json['hijriDay'] as int? ?? 1,
        dayOfWeek: json['hijriDayOfWeek'] as int? ?? 1,
      ),
      fajr: DateTime.parse(json['fajr'] as String),
      sunrise: DateTime.parse(json['sunrise'] as String),
      dhuhr: DateTime.parse(json['dhuhr'] as String),
      asr: DateTime.parse(json['asr'] as String),
      maghrib: DateTime.parse(json['maghrib'] as String),
      isha: DateTime.parse(json['isha'] as String),
      midnight: json['midnight'] != null
          ? DateTime.parse(json['midnight'] as String)
          : null,
      qiyam: json['qiyam'] != null
          ? DateTime.parse(json['qiyam'] as String)
          : null,
      method: CalculationMethod.values.firstWhere(
        (m) => m.name == json['method'],
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
      adjustments: json['adjustments'] != null
          ? Map<String, int>.from(json['adjustments'] as Map)
          : const {},
    );
  }

  PrayerTimeModel copyWith({
    DateTime? date,
    HijriDate? hijriDate,
    DateTime? fajr,
    DateTime? sunrise,
    DateTime? dhuhr,
    DateTime? asr,
    DateTime? maghrib,
    DateTime? isha,
    DateTime? midnight,
    DateTime? qiyam,
    CalculationMethod? method,
    Madhab? madhab,
    HighLatitudeRule? highLatitudeRule,
    Map<String, int>? adjustments,
  }) {
    return PrayerTimeModel(
      date: date ?? this.date,
      hijriDate: hijriDate ?? this.hijriDate,
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      midnight: midnight ?? this.midnight,
      qiyam: qiyam ?? this.qiyam,
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      adjustments: adjustments ?? this.adjustments,
    );
  }
}

/// Single prayer entry pairing name key with timestamp.
class PrayerEntry {
  final String key;
  final DateTime time;

  const PrayerEntry(this.key, this.time);

  Duration timeUntil([DateTime? from]) {
    final now = from ?? DateTime.now();
    return time.difference(now);
  }
}
