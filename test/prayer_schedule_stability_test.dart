import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/data/location/location_service.dart';
import 'package:sakina/data/prayer/prayer_repository.dart';
import 'package:sakina/data/settings/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('appearance and audio changes keep the same prayer repository', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      locationProvider.overrideWithValue(AppLocation.mecca),
    ]);
    addTearDown(container.dispose);
    final initial = container.read(prayerRepositoryProvider);
    await container.read(settingsNotifierProvider.notifier).update((s) =>
        s.copyWith(fontSize: 1.4, adhanVolume: .5, tapVolume: .2));
    expect(container.read(prayerRepositoryProvider), same(initial));
    await container.read(settingsNotifierProvider.notifier).update((s) =>
        s.copyWith(prayerAdjustments: {'Fajr': 7}));
    expect(container.read(prayerRepositoryProvider), isNot(same(initial)));
  });

  test('prayer adjustments invalidate cached calculated times', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const settings = AppSettings();
    final first = await PrayerRepository(prefs, settings, AppLocation.mecca)
        .fetchToday();
    final adjusted = await PrayerRepository(prefs,
        settings.copyWith(prayerAdjustments: {'Fajr': 7}), AppLocation.mecca)
        .fetchToday();
    expect(adjusted.times['Fajr']!.difference(first.times['Fajr']!),
        const Duration(minutes: 7));
    expect(adjusted.times['Dhuhr'], first.times['Dhuhr']);
  });
}
