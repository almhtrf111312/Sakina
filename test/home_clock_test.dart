import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/prayer/prayer_repository.dart';
import 'package:sakina/features/home/providers/home_providers.dart';
import 'package:sakina/features/home/widgets/home_clock_display.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prayer countdown emits immediately without waiting for a timer', () async {
    final now = DateTime.now().toUtc();
    final container = ProviderContainer(overrides: [
      prayerTimesProvider.overrideWith((ref) async => [DayPrayerTimes(
        date: now, times: {'Fajr': now.add(const Duration(hours: 1))})]),
    ]);
    addTearDown(container.dispose);
    final value = await container.read(nextPrayerProgressProvider.future)
        .timeout(const Duration(milliseconds: 800));
    expect(value?.prayerName, 'Fajr');
    expect(value?.remaining.inSeconds, greaterThan(3500));
  });

  testWidgets('all home clock styles display the prayer countdown', (tester) async {
    final data = NextPrayerProgress(prayerName: 'Fajr', prayerArabicName: 'الفجر',
      targetTime: DateTime.now(), remaining: const Duration(hours: 1),
      progress: .5, formattedCountdown: '01:00:00');
    for (final style in [0, 1, 2]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body:
        HomeClockDisplay(style: style, data: data))));
      expect(find.text('01:00:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
