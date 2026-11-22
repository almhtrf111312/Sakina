import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/data/settings/prayer_silence_settings.dart';
import 'package:sakina/data/settings/settings_repository.dart';
import 'package:sakina/features/settings/pages/prayer_silence_settings_page.dart';

void main() {
  test('existing settings default to prayer silence turned off', () {
    final settings = AppSettings.fromJson(const {});
    expect(settings.prayerSilenceEnabled, isFalse);
    expect(settings.prayerSilence, isEmpty);
  });

  test('prayers retain separate enable flags and signed offsets', () {
    final settings = const AppSettings().copyWith(
      prayerSilenceEnabled: true,
      prayerSilence: const {
        'Fajr': PrayerSilence(enabled: true, start: -10, end: 25),
        'Asr': PrayerSilence(enabled: true, start: 20, end: 45),
        'Isha': PrayerSilence(start: -30, end: 0),
      },
    );
    final restored = AppSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
    );
    expect(restored.prayerSilenceEnabled, isTrue);
    expect(restored.prayerSilence['Fajr']?.toJson(),
        {'enabled': true, 'start': -10, 'end': 25});
    expect(restored.prayerSilence['Asr']?.toJson(),
        {'enabled': true, 'start': 20, 'end': 45});
    expect(restored.prayerSilence['Isha']?.toJson(),
        {'enabled': false, 'start': -30, 'end': 0});
  });

  testWidgets('the page enables only the selected prayer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const channel = MethodChannel('com.sakina.app/alarm');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => {'supported': true, 'access': true, 'exactAlarm': true},
    );
    addTearDown(() =>
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PrayerSilenceSettingsPage()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('الفجر'));
    await tester.pumpAndSettle();

    final settings = container.read(appSettingsProvider);
    expect(settings.prayerSilenceEnabled, isTrue);
    expect(settings.prayerSilence.keys, ['Fajr']);
    expect(settings.prayerSilence['Fajr']?.enabled, isTrue);
    expect(find.text('بداية الصامت ونهايته'), findsOneWidget);
  });

  test('invalid ranges and non-prayer entries are discarded individually', () {
    final rules = PrayerSilence.readAll({
      'Fajr': {'enabled': true, 'start': 0, 'end': 30},
      'Dhuhr': {'enabled': true, 'start': 40, 'end': 20},
      'Asr': {'enabled': true, 'start': -121, 'end': 20},
      'Maghrib': {'enabled': true, 'start': 0, 'end': 0},
      'Sunrise': {'enabled': true, 'start': 0, 'end': 20},
    });
    expect(rules.keys, ['Fajr']);
  });
}
