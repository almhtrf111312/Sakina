// lib/data/notifications/prayer_alarm_sync.dart
// Keeps the native AlarmManager schedule in sync with calculated prayer times
// and the user's notification settings.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/alarm_bridge.dart';
import '../location/location_service.dart';
import '../prayer/prayer_repository.dart';
import '../settings/settings_repository.dart';

String _typeFor(NotificationMode mode) {
  switch (mode) {
    case NotificationMode.shortBeep:
      return 'short';
    case NotificationMode.silent:
      return 'silent';
    case NotificationMode.vibrate:
      return 'vibrate';
    case NotificationMode.off:
      return 'off';
  }
}

/// Re-schedules the next ~7 days of prayer alarms whenever prayer times or
/// notification settings change. Watch this provider once (e.g. in the app
/// shell) to keep it alive.
final prayerAlarmSyncProvider = FutureProvider<void>((ref) async {
  final schedule = await ref.watch(prayerTimesProvider.future);
  // Re-run only when a setting that affects alarms/widgets really changes;
  // watching the whole settings object re-scheduled every alarm on each
  // slider tick (font size, brightness, theme...), which made the UI stall.
  ref.watch(appSettingsProvider.select((s) => Object.hash(
        Object.hashAll(s.prayerNotifications.entries
            .map((e) => Object.hash(e.key, e.value))),
        s.selectedAdhanSound,
        s.adhanVolume,
        s.gradualVolume,
        s.morningAzkarReminder,
        s.eveningAzkarReminder,
        s.persistentNotification,
      )));
  final settings = ref.read(appSettingsProvider);

  final nowUtc = DateTime.now().toUtc();
  final timeLabel = DateFormat('HH:mm');
  final payload = <Map<String, dynamic>>[];

  for (final day in schedule.take(8)) {
    for (final entry in day.times.entries) {
      final name = entry.key;
      final time = entry.value;
      if (time.isBefore(nowUtc)) continue;

      final mode = settings.prayerNotifications[name] ?? NotificationMode.off;
      payload.add({
        'name': name,
        'timestamp': time.millisecondsSinceEpoch,
        'timeLabel': timeLabel.format(time.toLocal()),
        'enabled': mode != NotificationMode.off,
        'notificationType': _typeFor(mode),
        'soundId': settings.selectedAdhanSound,
        'volume': settings.adhanVolume,
        'gradualVolume': settings.gradualVolume,
      });
    }
  }

  // Morning / evening azkar reminders: 20 min after Fajr and after Asr.
  const reminderDelay = Duration(minutes: 20);
  for (final day in schedule.take(8)) {
    void addReminder(String key, String prayer) {
      final base = day.times[prayer];
      if (base == null) return;
      final t = base.add(reminderDelay);
      if (t.isBefore(nowUtc)) return;
      payload.add({
        'name': key,
        'timestamp': t.millisecondsSinceEpoch,
        'timeLabel': timeLabel.format(t.toLocal()),
        'enabled': true,
        'notificationType': 'azkar',
        'soundId': '',
        'volume': 0.0,
        'gradualVolume': false,
      });
    }

    if (settings.morningAzkarReminder) addReminder('AzkarMorning', 'Fajr');
    if (settings.eveningAzkarReminder) addReminder('AzkarEvening', 'Asr');
  }

  // Home-screen widgets + persistent notification data.
  try {
    final location = ref.watch(locationProvider);
    const five = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final items = <Map<String, dynamic>>[];
    final cutoff = DateTime.now().toUtc().subtract(const Duration(hours: 30));
    for (final day in schedule.take(4)) {
      for (final k in five) {
        final t = day.times[k];
        if (t == null || t.isBefore(cutoff)) continue;
        items.add({'n': k, 'ts': t.millisecondsSinceEpoch});
      }
    }
    final city = [location.cityName, location.countryName]
        .where((e) => e.isNotEmpty)
        .join('، ');
    await AlarmBridge.updateWidgetData(jsonEncode({
      'city': city,
      'items': items,
      'notif': settings.persistentNotification,
    }));
  } catch (e) {
    debugPrint('widget data sync failed: $e');
  }

  try {
    await AlarmBridge.schedulePrayerAlarms(payload);
  } catch (e) {
    debugPrint('prayerAlarmSync failed: $e');
  }
});
