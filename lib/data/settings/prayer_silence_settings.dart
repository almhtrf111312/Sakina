const prayerSilenceNames = {
  'Fajr': 'الفجر',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};

class PrayerSilence {
  static const maxOffset = 120;

  const PrayerSilence({
    this.enabled = false,
    this.start = 0,
    this.end = 30,
  });

  final bool enabled;
  // Negative offsets are before the adhan, positive offsets are after it.
  final int start;
  final int end;

  PrayerSilence copyWith({bool? enabled, int? start, int? end}) =>
      PrayerSilence(
        enabled: enabled ?? this.enabled,
        start: start ?? this.start,
        end: end ?? this.end,
      );

  Map<String, Object> toJson() => {
        'enabled': enabled,
        'start': start,
        'end': end,
      };

  static Map<String, PrayerSilence> readAll(Object? json) {
    if (json is! Map) return const {};
    final result = <String, PrayerSilence>{};
    for (final name in prayerSilenceNames.keys) {
      final value = json[name];
      if (value is! Map) continue;
      final start = value['start'];
      final end = value['end'];
      if (start is! int || end is! int ||
          start < -maxOffset || end > maxOffset || start >= end) {
        continue;
      }
      result[name] = PrayerSilence(
        enabled: value['enabled'] == true,
        start: start,
        end: end,
      );
    }
    return result;
  }
}
