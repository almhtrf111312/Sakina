// lib/data/notifications/prayer_alarm_sync.dart
// Keeps the native AlarmManager schedule in sync with calculated prayer times
// and the user's notification settings.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/alarm_bridge.dart';
import '../prayer/prayer_repository.dart';
import '../settings/settings_repository.dart';

String _typeFor(NotificationMode mode) {
  switch (mode) {
    case NotificationMode.fullAdhan:
      return 'adhan';
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
  final settings = ref.watch(appSettingsProvider);

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

  try {
    await AlarmBridge.schedulePrayerAlarms(payload);
  } catch (e) {
    debugPrint('prayerAlarmSync failed: $e');
  }
});
