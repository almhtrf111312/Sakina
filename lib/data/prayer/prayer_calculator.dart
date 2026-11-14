// lib/data/prayer/prayer_calculator.dart
// Full astronomical prayer time calculation — no external adhan package.

import 'dart:math';

// ─────────────────────────── Enumerations ───────────────────────────────────

enum CalculationMethod {
  mwl,         // Muslim World League
  ummAlQura,   // Umm Al-Qura University, Mecca
  egyptian,    // Egyptian General Authority of Survey
  karachi,     // University of Islamic Sciences, Karachi
  isna,        // Islamic Society of North America
  diyanet,     // Diyanet İşleri Başkanlığı
  dubai,       // Dubai
  kuwait,      // Kuwait
  qatar,       // Qatar
  singapore,   // Majlis Ugama Islam Singapura
  tehran,      // Institute of Geophysics, University of Tehran
  custom,      // User-defined
}

enum Madhab { shafi, hanafi }

enum HighLatitudeRule { middleOfNight, seventhOfNight, angleBased }

// ───────────────────────── Calculation Parameters ───────────────────────────

class CalculationParameters {
  final double fajrAngle;
  final double ishaAngle;
  final int ishaInterval; // minutes after Maghrib (Umm Al-Qura / Qatar)
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;
  final Map<String, int> adjustments; // per-prayer minute offsets

  const CalculationParameters({
    required this.fajrAngle,
    required this.ishaAngle,
    this.ishaInterval = 0,
    this.madhab = Madhab.shafi,
    this.highLatitudeRule = HighLatitudeRule.middleOfNight,
    this.adjustments = const {},
  });

  static CalculationParameters forMethod(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.mwl:
        return const CalculationParameters(fajrAngle: 18, ishaAngle: 17);
      case CalculationMethod.ummAlQura:
        return const CalculationParameters(
            fajrAngle: 18.5, ishaAngle: 0, ishaInterval: 90);
      case CalculationMethod.egyptian:
        return const CalculationParameters(fajrAngle: 19.5, ishaAngle: 17.5);
      case CalculationMethod.karachi:
        return const CalculationParameters(fajrAngle: 18, ishaAngle: 18);
      case CalculationMethod.isna:
        return const CalculationParameters(fajrAngle: 15, ishaAngle: 15);
      case CalculationMethod.diyanet:
        return const CalculationParameters(fajrAngle: 18, ishaAngle: 17);
      case CalculationMethod.dubai:
        return const CalculationParameters(fajrAngle: 18.2, ishaAngle: 18.2);
      case CalculationMethod.kuwait:
        return const CalculationParameters(fajrAngle: 18, ishaAngle: 17.5);
      case CalculationMethod.qatar:
        return const CalculationParameters(
            fajrAngle: 18, ishaAngle: 0, ishaInterval: 90);
      case CalculationMethod.singapore:
        return const CalculationParameters(fajrAngle: 20, ishaAngle: 18);
      case CalculationMethod.tehran:
        return const CalculationParameters(fajrAngle: 17.7, ishaAngle: 14,
            // Tehran uses a custom formula; Maghrib angle 4.5 handled separately
        );
      case CalculationMethod.custom:
        return const CalculationParameters(fajrAngle: 18, ishaAngle: 17);
    }
  }
}

// ───────────────────────────── Main Calculator ──────────────────────────────

class PrayerCalculator {
  final double latitude;
  final double longitude;
  final double elevation; // metres above sea level
  final CalculationMethod method;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;
  final Map<String, int> adjustments;

  PrayerCalculator({
    required this.latitude,
    required this.longitude,
    this.elevation = 0,
    this.method = CalculationMethod.mwl,
    this.madhab = Madhab.shafi,
    this.highLatitudeRule = HighLatitudeRule.middleOfNight,
    this.adjustments = const {},
  });

  /// Returns all prayer times as UTC DateTimes for [date].
  Map<String, DateTime> calculate(DateTime date) {
    final params = CalculationParameters.forMethod(method).copyWith(
      madhab: madhab,
      highLatitudeRule: highLatitudeRule,
      adjustments: adjustments,
    );

    // Julian Day Number for noon UTC of given date
    final jd = _julianDay(date.year, date.month, date.day);

    // ── Solar position at solar noon ──
    final solarNoon = _solarNoon(jd, longitude);
    final sunriseAngle = _sunriseAngle(latitude, elevation);

    // ── Core times ──
    final sunriseJd = _sunriseTime(jd, latitude, longitude, sunriseAngle);
    final sunsetJd  = _sunsetTime(jd, latitude, longitude, sunriseAngle);
    final dhuhrJd   = solarNoon;

    // ── Asr ──
    final asrJd = _asrTime(jd, latitude, longitude, params.madhab);

    // ── Fajr / Isha ──
    final nightDuration = sunriseJd - (sunsetJd - 1); // sunsetJd is next-day if wrapped
    final fajrJd = _twilightTime(jd, latitude, longitude, params.fajrAngle,
        isRising: true, nightDuration: nightDuration,
        rule: params.highLatitudeRule, sunriseJd: sunriseJd, sunsetJd: sunsetJd);

    double ishaJd;
    if (params.ishaInterval > 0) {
      ishaJd = sunsetJd + params.ishaInterval / 1440.0;
    } else {
      ishaJd = _twilightTime(jd, latitude, longitude, params.ishaAngle,
          isRising: false, nightDuration: nightDuration,
          rule: params.highLatitudeRule, sunriseJd: sunriseJd, sunsetJd: sunsetJd);
    }

    // Tehran: Maghrib = sunset + 4.5°
    double maghribJd;
    if (method == CalculationMethod.tehran) {
      maghribJd = _twilightTime(jd, latitude, longitude, 4.5,
          isRising: false, nightDuration: nightDuration,
          rule: params.highLatitudeRule, sunriseJd: sunriseJd, sunsetJd: sunsetJd);
    } else {
      maghribJd = sunsetJd;
    }

    final times = {
      'Fajr':    _jdToUtc(fajrJd, date),
      'Sunrise': _jdToUtc(sunriseJd, date),
      'Dhuhr':   _jdToUtc(dhuhrJd, date),
      'Asr':     _jdToUtc(asrJd, date),
      'Maghrib': _jdToUtc(maghribJd, date),
      'Isha':    _jdToUtc(ishaJd, date),
    };

    // Apply per-prayer minute adjustments
    return times.map((key, dt) {
      final adj = params.adjustments[key] ?? 0;
      return MapEntry(key, dt.add(Duration(minutes: adj)));
    });
  }

  // ─────────────────── Astronomical helper functions ──────────────────────

  /// Julian day number for noon UTC.
  static double _julianDay(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day + b - 1524.5;
  }

  /// Solar noon (transit) as a JD. [jd] is the JD at 0h UTC of the date.
  static double _solarNoon(double jd, double longitude) {
    final t = _julianCenturies(jd + 0.5);
    final eot = _equationOfTime(t); // minutes
    // UTC hour of local apparent noon = 12 - lon/15 - EoT/60
    return jd + (12.0 - longitude / 15.0 - eot / 60.0) / 24.0;
  }

  /// Julian centuries since J2000.
  static double _julianCenturies(double jd) => (jd - 2451545.0) / 36525.0;

  /// Equation of Time in minutes.
  static double _equationOfTime(double t) {
    final epsilon = _obliquityCorrection(t);
    final l0 = 280.46646 + t * (36000.76983 + t * 0.0003032);
    final e = 0.016708634 - t * (0.000042037 + t * 0.0000001267);
    final m = _toRad(357.52911 + t * (35999.05029 - t * 0.0001537));
    final y = pow(tan(_toRad(epsilon / 2)), 2) as double;
    final l0r = _toRad(l0);

    final eot = y * sin(2 * l0r) -
        2 * e * sin(m) +
        4 * e * y * sin(m) * cos(2 * l0r) -
        0.5 * y * y * sin(4 * l0r) -
        1.25 * e * e * sin(2 * m);
    return _toDeg(eot) * 4; // convert radians to minutes
  }

  static double _obliquityCorrection(double t) {
    final e0 = 23.0 + (26.0 + ((21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813)))) / 60.0) / 60.0;
    final omega = 125.04 - 1934.136 * t;
    return e0 + 0.00256 * cos(_toRad(omega));
  }

  static double _sunDeclination(double t) {
    final omega = _toRad(125.04 - 1934.136 * t);
    final lambda = 280.46646 + t * 36000.76983;
    final apparentLong = _toRad(lambda - 0.00569 - 0.00478 * sin(omega));
    final epsilon = _toRad(_obliquityCorrection(t));
    return _toDeg(asin(sin(epsilon) * sin(apparentLong)));
  }

  /// Standard refraction + elevation correction for sunrise/sunset.
  static double _sunriseAngle(double latitude, double elevation) {
    final refractionCorrection = 0.833;
    final elevationCorrection = (elevation > 0)
        ? (0.0347 * sqrt(elevation))
        : 0.0;
    return 0.0 + refractionCorrection + elevationCorrection;
  }

  /// Hour angle for a given target altitude angle.
  static double? _hourAngle(double jd, double latitude, double angle,
      {required bool morning}) {
    final t = _julianCenturies(jd);
    final decl = _toRad(_sunDeclination(t));
    final latR = _toRad(latitude);
    final cosH = (cos(_toRad(90 + angle)) - sin(decl) * sin(latR)) /
        (cos(decl) * cos(latR));
    if (cosH.isNaN) return null;
    if (cosH > 1.0) {
      if (cosH <= 1.00001) return 0.0;
      return null; // Sun never rises/sets
    }
    if (cosH < -1.0) {
      if (cosH >= -1.00001) return morning ? -180.0 : 180.0;
      return null; // Sun never rises/sets
    }
    final h = _toDeg(acos(cosH.clamp(-1.0, 1.0)));
    return morning ? -h : h;
  }

  /// Sunrise time in JD.
  static double _sunriseTime(
      double jd, double latitude, double longitude, double angle) {
    final noon = _solarNoon(jd, longitude);
    final ha = _hourAngle(jd, latitude, angle, morning: true);
    if (ha == null) return noon - 6 / 24.0;
    return noon + ha / 360.0;
  }

  /// Sunset time in JD.
  static double _sunsetTime(
      double jd, double latitude, double longitude, double angle) {
    final noon = _solarNoon(jd, longitude);
    final ha = _hourAngle(jd, latitude, angle, morning: false);
    if (ha == null) return noon + 6 / 24.0;
    return noon + ha / 360.0;
  }

  /// Asr shadow ratio: Shafi = 1, Hanafi = 2.
  static double _asrTime(
      double jd, double latitude, double longitude, Madhab madhab) {
    final shadowFactor = madhab == Madhab.hanafi ? 2.0 : 1.0;
    final noon = _solarNoon(jd, longitude);
    final t = _julianCenturies(jd);
    final decl = _toRad(_sunDeclination(t));
    final latR = _toRad(latitude);

    // Shadow angle: target altitude = atan(1 / (shadowFactor + tan(|lat - decl|)))
    final angle =
        _toDeg(atan(1.0 / (shadowFactor + tan((latR - decl).abs()))));
    final ha = _hourAngle(jd, latitude, -angle, morning: false);
    if (ha == null) return noon + 3 / 24.0;
    return noon + ha / 360.0;
  }

  /// Fajr / Isha twilight time with high-latitude safety.
  static double _twilightTime(
    double jd,
    double latitude,
    double longitude,
    double angle, {
    required bool isRising,
    required double nightDuration,
    required HighLatitudeRule rule,
    required double sunriseJd,
    required double sunsetJd,
  }) {
    final noon = _solarNoon(jd, longitude);
    final ha = _hourAngle(jd, latitude, angle, morning: isRising);

    if (ha != null) {
      return noon + ha / 360.0;
    }

    // High-latitude fallback
    switch (rule) {
      case HighLatitudeRule.middleOfNight:
        final portion = isRising ? 1 / 2.0 : 1 / 2.0;
        return isRising
            ? sunriseJd - portion * nightDuration
            : sunsetJd + portion * nightDuration;
      case HighLatitudeRule.seventhOfNight:
        final portion = 1 / 7.0;
        return isRising
            ? sunriseJd - portion * nightDuration
            : sunsetJd + portion * nightDuration;
      case HighLatitudeRule.angleBased:
        final portion = angle / 60.0;
        return isRising
            ? sunriseJd - portion * nightDuration
            : sunsetJd + portion * nightDuration;
    }
  }

  /// Convert a Julian day to an absolute UTC DateTime (handles day wrap).
  static DateTime _jdToUtc(double jd, DateTime date) {
    final ms = ((jd - 2440587.5) * 86400000.0).round();
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  static double _toRad(double deg) => deg * pi / 180.0;
  static double _toDeg(double rad) => rad * 180.0 / pi;
}

// ──────────────────── Extension helpers ─────────────────────────────────────

extension _ParamsCopyWith on CalculationParameters {
  CalculationParameters copyWith({
    double? fajrAngle,
    double? ishaAngle,
    int? ishaInterval,
    Madhab? madhab,
    HighLatitudeRule? highLatitudeRule,
    Map<String, int>? adjustments,
  }) {
    return CalculationParameters(
      fajrAngle: fajrAngle ?? this.fajrAngle,
      ishaAngle: ishaAngle ?? this.ishaAngle,
      ishaInterval: ishaInterval ?? this.ishaInterval,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      adjustments: adjustments ?? this.adjustments,
    );
  }
}
