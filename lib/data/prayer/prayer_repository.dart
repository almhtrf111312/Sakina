// lib/data/prayer/prayer_repository.dart
// Riverpod prayer-time repository: caching, next-prayer detection, countdown.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../location/location_service.dart';
import '../settings/settings_repository.dart';
import 'prayer_calculator.dart';

// ─────────────────────────── Domain types ───────────────────────────────────

class DayPrayerTimes {
  final DateTime date;
  final Map<String, DateTime> times; // prayer name → UTC DateTime

  const DayPrayerTimes({required this.date, required this.times});

  factory DayPrayerTimes.fromJson(Map<String, dynamic> json) {
    return DayPrayerTimes(
      date: DateTime.parse(json['date'] as String),
      times: (json['times'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, DateTime.parse(v as String))),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'times': times.map((k, v) => MapEntry(k, v.toIso8601String())),
      };
}

class NextPrayer {
  final String name;
  final DateTime time; // UTC
  final Duration remaining;

  const NextPrayer({
    required this.name,
    required this.time,
    required this.remaining,
  });
}

// ──────────────────────────── Repository ────────────────────────────────────

class PrayerRepository {
  static const _cacheKey = 'prayer_times_cache';
  static const _cacheMetaKey = 'prayer_times_cache_meta';

  final SharedPreferences _prefs;
  final AppSettings _settings;
  final AppLocation _location;

  PrayerRepository(this._prefs, this._settings, this._location);

  // ── Build calculator from current settings ─────────────────────────────

  PrayerCalculator _buildCalculator() {
    return PrayerCalculator(
      latitude: _location.latitude,
      longitude: _location.longitude,
      elevation: _location.elevation,
      method: _settings.calculationMethod,
      madhab: _settings.madhab,
      highLatitudeRule: _settings.highLatitudeRule,
      adjustments: _settings.prayerAdjustments,
    );
  }

  // ── Cache helpers ──────────────────────────────────────────────────────

  String _metaKey() =>
      '${_location.latitude.toStringAsFixed(4)}_'
      '${_location.longitude.toStringAsFixed(4)}_'
      '${_settings.calculationMethod.name}_'
      '${_settings.madhab.name}';

  Future<List<DayPrayerTimes>?> _loadFromCache() async {
    final meta = _prefs.getString(_cacheMetaKey);
    if (meta != _metaKey()) return null;

    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;

    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => DayPrayerTimes.fromJson(e as Map<String, dynamic>))
          .toList();
      // Validate: first date must be today or in the future
      final today = _today();
      if (list.isNotEmpty && list.first.date.isBefore(today)) return null;
      return list;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(List<DayPrayerTimes> data) async {
    await _prefs.setString(_cacheKey,
        jsonEncode(data.map((d) => d.toJson()).toList()));
    await _prefs.setString(_cacheMetaKey, _metaKey());
  }

  // ── Fetch: today + 60 days ──────────────────────────────────────────────

  Future<List<DayPrayerTimes>> fetchPrayerTimes() async {
    final cached = await _loadFromCache();
    if (cached != null && cached.length >= 60) return cached;

    final calc = _buildCalculator();
    final today = _today();
    final result = <DayPrayerTimes>[];

    for (int i = 0; i < 61; i++) {
      final date = today.add(Duration(days: i));
      final times = calc.calculate(date);
      result.add(DayPrayerTimes(date: date, times: times));
    }

    await _saveToCache(result);
    return result;
  }

  /// Today's prayer times only (fast path).
  Future<DayPrayerTimes> fetchToday() async {
    final all = await fetchPrayerTimes();
    return all.first;
  }

  /// Invalidate cache (call after settings/location change).
  Future<void> invalidateCache() async {
    await _prefs.remove(_cacheKey);
    await _prefs.remove(_cacheMetaKey);
  }

  // ── Next prayer detection ───────────────────────────────────────────────

  NextPrayer? getNextPrayer(List<DayPrayerTimes> schedule) {
    final now = DateTime.now().toUtc();
    final orderedNames = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    for (final day in schedule) {
      for (final name in orderedNames) {
        final time = day.times[name];
        if (time == null) continue;
        if (time.isAfter(now)) {
          return NextPrayer(
            name: name,
            time: time,
            remaining: time.difference(now),
          );
        }
      }
    }
    return null;
  }

  // ── Utility ────────────────────────────────────────────────────────────

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}

// ─────────────────────────── Providers ──────────────────────────────────────

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final settings = ref.watch(appSettingsProvider);
  final location = ref.watch(locationProvider);
  return PrayerRepository(prefs, settings, location);
});

/// All prayer times for today + next 60 days.
final prayerTimesProvider =
    FutureProvider<List<DayPrayerTimes>>((ref) async {
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.fetchPrayerTimes();
});

/// Today's prayer times.
final todayPrayerTimesProvider = FutureProvider<DayPrayerTimes>((ref) async {
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.fetchToday();
});

/// Next upcoming prayer (recalculated each second via countdownProvider).
final nextPrayerProvider = Provider<AsyncValue<NextPrayer?>>((ref) {
  final schedule = ref.watch(prayerTimesProvider);
  return schedule.whenData(
      (data) => ref.watch(prayerRepositoryProvider).getNextPrayer(data));
});

/// Countdown stream — emits every second.
final countdownProvider = StreamProvider<Duration?>((ref) {
  final nextPrayerAsync = ref.watch(nextPrayerProvider);

  return nextPrayerAsync.when(
    data: (next) {
      if (next == null) return Stream.value(null);
      return Stream.periodic(const Duration(seconds: 1), (_) {
        final remaining = next.time.difference(DateTime.now().toUtc());
        return remaining.isNegative ? Duration.zero : remaining;
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Today's prayer times as an ordered list of [name, DateTime] pairs.
final orderedPrayerListProvider = Provider<AsyncValue<List<MapEntry<String, DateTime>>>>((ref) {
  final today = ref.watch(todayPrayerTimesProvider);
  return today.whenData((day) {
    const order = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    return order
        .where((n) => day.times.containsKey(n))
        .map((n) => MapEntry(n, day.times[n]!))
        .toList();
  });
});
