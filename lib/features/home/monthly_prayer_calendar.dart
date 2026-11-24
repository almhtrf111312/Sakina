import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../data/location/location_service.dart';
import '../../data/prayer/prayer_repository.dart';
import '../../data/settings/settings_repository.dart';

const _prayers = {
  'Fajr': 'الفجر',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};

DateTime _step(DateTime date, int days) =>
    DateTime.utc(date.year, date.month, date.day + days);

HijriDate _hijri(DateTime date, int offset) =>
    AppDateUtils.toHijri(date, adjustmentDays: offset);

({int year, int month}) _month(DateTime date, int offset) {
  final hijri = _hijri(date, offset);
  return (year: hijri.year, month: hijri.month);
}

/// Civil date bounds of the Hijri month containing [date].
({DateTime start, DateTime end}) hijriMonthRange(DateTime date, int offset) {
  final month = _month(date, offset);
  var start = date;
  var end = _step(date, 1);
  while (_month(_step(start, -1), offset) == month) {
    start = _step(start, -1);
  }
  while (_month(end, offset) == month) {
    end = _step(end, 1);
  }
  return (start: start, end: end);
}

class MonthlyPrayerCalendar extends ConsumerStatefulWidget {
  const MonthlyPrayerCalendar({super.key});

  @override
  ConsumerState<MonthlyPrayerCalendar> createState() =>
      _MonthlyPrayerCalendarState();
}

class _MonthlyPrayerCalendarState extends ConsumerState<MonthlyPrayerCalendar> {
  final _today = DateTime.now();
  late var _selected = DateTime.utc(_today.year, _today.month, _today.day);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final city = ref.watch(locationProvider).cityName;
    final repository = ref.watch(prayerRepositoryProvider);
    final range = hijriMonthRange(_selected, settings.hijriOffset);
    final month = _hijri(range.start, settings.hijriOffset);
    final days = repository.calculateRange(
      range.start,
      range.end.difference(range.start).inDays,
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    String digits(String text) => settings.numeralType == NumeralType.arabic
        ? AppDateUtils.toArabicDigits(text)
        : text;

    Widget cell(String text, {bool bold = false, bool ltr = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          child: Text(
            digits(text),
            textAlign: TextAlign.center,
            textDirection: ltr ? TextDirection.ltr : null,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.bold : null,
            ),
          ),
        );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التقويم الشهري')),
        body: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'الشهر السابق',
                  onPressed: () => setState(() => _selected = _step(range.start, -1)),
                  icon: const Icon(Icons.chevron_right),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        digits('${AppDateUtils.hijriMonthsAr[month.month - 1]} ${month.year} هـ'),
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (city.isNotEmpty) Text(city, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'الشهر التالي',
                  onPressed: () => setState(() => _selected = range.end),
                  icon: const Icon(Icons.chevron_left),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth < 350 ? 350 : constraints.maxWidth,
                    child: Column(
                      children: [
                        Table(
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: colors.surfaceContainerHighest),
                              children: [
                                cell('اليوم', bold: true),
                                for (final label in _prayers.values)
                                  cell(label, bold: true),
                              ],
                            ),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                            key: ValueKey((month.year, month.month)),
                            itemCount: days.length,
                            itemBuilder: (context, index) {
                              final day = days[index];
                              final date = day.date;
                              final isToday = DateUtils.isSameDay(date, _today);
                              final hijri = _hijri(DateTime.utc(date.year, date.month, date.day),
                                  settings.hijriOffset);
                              return Table(
                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? colors.primary.withOpacity(0.15)
                                          : index.isEven ? colors.surfaceContainerLow : colors.surface,
                                    ),
                                    children: [
                                      cell('${hijri.day}\n${date.day}/${date.month}',
                                          bold: isToday, ltr: true),
                                      for (final name in _prayers.keys)
                                        cell(
                                          day.times[name] == null
                                              ? '—'
                                              : AppDateUtils.formatPrayerTime(
                                                  day.times[name]!.toLocal(),
                                                  is24Hour: settings.use24HourTime,
                                                ),
                                          ltr: true,
                                        ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
