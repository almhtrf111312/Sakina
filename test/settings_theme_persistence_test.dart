import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/data/settings/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rapid appearance changes restore the final selection', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    final writes = [
      notifier.update((s) => s.copyWith(themeMode: AppThemeMode.day)),
      notifier.update((s) => s.copyWith(accentColor: AccentColor.rose)),
      notifier.update((s) => s.copyWith(themeMode: AppThemeMode.amoled,
          homeClockStyle: 2)),
    ];
    await Future.wait(writes);
    final restored = SettingsNotifier(prefs);
    expect(restored.debugState.themeMode, AppThemeMode.amoled);
    expect(restored.debugState.accentColor, AccentColor.rose);
    expect(restored.debugState.homeClockStyle, 2);
    notifier.dispose();
    restored.dispose();
  });

  test('damaged legacy payload keeps saved appearance choices', () async {
    SharedPreferences.setMockInitialValues({
      'app_settings_v1': jsonEncode({'prayerAdjustments': 'invalid'}),
      'sakina_theme_mode': 'day',
      'sakina_accent_color': 'purple',
    });
    final prefs = await SharedPreferences.getInstance();
    final restored = SettingsNotifier(prefs);
    expect(restored.debugState.themeMode, AppThemeMode.day);
    expect(restored.debugState.accentColor, AccentColor.purple);
    restored.dispose();
  });

  test('Fajr sound stays separate from the other prayer sound', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    const shortClip = 'adhan_10';
    await notifier.update((s) => s.copyWith(
        selectedFajrSound: 'adhan_4', selectedAdhanSound: shortClip,
        selectedFullAdhanSound: 'adhan_full_3'));
    expect(notifier.debugState.selectedAdhanSound, shortClip);
    expect(jsonDecode(prefs.getString('app_settings_v1')!)['selectedAdhanSound'], shortClip);
    expect(AppSettings.fromJson(
        jsonDecode(prefs.getString('app_settings_v1')!) as Map<String, dynamic>)
        .selectedAdhanSound, shortClip);
    final restored = SettingsNotifier(prefs);
    expect(restored.debugState.selectedFajrSound, 'adhan_4');
    expect(restored.debugState.selectedFullAdhanSound, 'adhan_full_3');
    expect(restored.debugState.selectedAdhanSound, shortClip);
    notifier.dispose();
    restored.dispose();
  });
}
