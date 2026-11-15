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
      notifier.update((s) => s.copyWith(themeMode: AppThemeMode.amoled)),
    ];
    await Future.wait(writes);
    final restored = SettingsNotifier(prefs);
    expect(restored.debugState.themeMode, AppThemeMode.amoled);
    expect(restored.debugState.accentColor, AccentColor.rose);
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
    final custom = 'custom|نغمتي|content%3A%2F%2Fmedia%2Ftest';
    await notifier.update((s) => s.copyWith(
        selectedFajrSound: 'adhan_4', selectedAdhanSound: custom));
    final restored = SettingsNotifier(prefs);
    expect(restored.debugState.selectedFajrSound, 'adhan_4');
    expect(restored.debugState.selectedAdhanSound, custom);
    notifier.dispose();
    restored.dispose();
  });
}
