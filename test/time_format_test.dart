import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/utils/date_utils.dart';

void main() {
  test('12-hour labels and 24-hour boundaries remain consistent', () {
    expect(AppDateUtils.formatPrayerTime(DateTime(2026, 1, 1, 0, 5)),
        '12:05 صباحاً');
    expect(AppDateUtils.formatPrayerTime(DateTime(2026, 1, 1, 12, 0)),
        '12:00 مساءً');
    expect(AppDateUtils.formatPrayerTime(DateTime(2026, 1, 1, 23, 9)),
        '11:09 مساءً');
    expect(AppDateUtils.formatPrayerTime(DateTime(2026, 1, 1, 23, 9),
        is24Hour: true), '23:09');
  });
}
