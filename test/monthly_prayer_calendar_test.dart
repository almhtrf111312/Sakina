import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/utils/date_utils.dart';
import 'package:sakina/data/location/location_service.dart';
import 'package:sakina/data/prayer/prayer_repository.dart';
import 'package:sakina/data/settings/settings_repository.dart';
import 'package:sakina/features/home/monthly_prayer_calendar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Hijri month navigation respects the configured date adjustment', () {
    final date = DateTime.utc(2026, 11, 24);
    for (final adjustment in [-2, 0, 2]) {
      final range = hijriMonthRange(date, adjustment);
      final days = range.end.difference(range.start).inDays;
      expect(days, inInclusiveRange(29, 30));
      expect(date.isBefore(range.start), isFalse);
      expect(date.isBefore(range.end), isTrue);
      final first = AppDateUtils.toHijri(range.start, adjustmentDays: adjustment);
      final next = AppDateUtils.toHijri(range.end, adjustmentDays: adjustment);
      expect(first.day, 1);
      expect(next.day, 1);
      expect((first.year, first.month), isNot((next.year, next.month)));
      expect(hijriMonthRange(range.end, adjustment).start, range.end);
    }
  });

  test('all months around the Hijri year boundary have 29 or 30 days', () {
    var date = DateTime.utc(2026, 1, 1);
    for (var i = 0; i < 24; i++) {
      final range = hijriMonthRange(date, 0);
      expect(range.end.difference(range.start).inDays, inInclusiveRange(29, 30));
      expect(AppDateUtils.toHijri(range.start).day, 1);
      date = range.end;
    }
  });

  test('calendar calculations keep the daily schedule and cache consistent', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = PrayerRepository(prefs, const AppSettings(), AppLocation.mecca);
    final today = await repository.fetchToday();
    final date = today.date;
    final range = hijriMonthRange(DateTime.utc(date.year, date.month, date.day), 0);
    final days = repository.calculateRange(range.start, range.end.difference(range.start).inDays);
    expect(days.singleWhere((day) => day.date == today.date).times, today.times);
    expect((await repository.fetchToday()).date, today.date);
  });
}
