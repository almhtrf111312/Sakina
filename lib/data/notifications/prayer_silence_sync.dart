import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/alarm_bridge.dart';
import '../prayer/prayer_repository.dart';
import '../settings/settings_repository.dart';

final prayerSilenceSyncProvider = FutureProvider<void>((ref) async {
  if (defaultTargetPlatform != TargetPlatform.android || kIsWeb) return;

  final (enabled, rules) = ref.watch(appSettingsProvider.select(
    (s) => (s.prayerSilenceEnabled, s.prayerSilence),
  ));
  final activeRules = rules.entries.where((entry) => entry.value.enabled);
  final windows = <List<int>>[];

  if (enabled && activeRules.isNotEmpty) {
    final schedule = ref.watch(prayerTimesProvider);
    final days = schedule.valueOrNull;
    if (days == null) return;
    final yesterday = ref.watch(prayerRepositoryProvider).previousDay();
    final now = DateTime.now();
    for (final day in [yesterday, ...days]) {
      for (final entry in activeRules) {
        final time = day.times[entry.key];
        if (time == null) continue;
        final end = time.add(Duration(minutes: entry.value.end));
        if (!end.isAfter(now)) continue;
        final start = time.add(Duration(minutes: entry.value.start));
        windows.add([start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
      }
    }
  }

  try {
    await AlarmBridge.setPrayerSilenceWindows(windows);
  } catch (error) {
    debugPrint('Prayer silence sync failed: $error');
  }
});
