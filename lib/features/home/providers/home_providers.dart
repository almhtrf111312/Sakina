// lib/features/home/providers/home_providers.dart
// All Riverpod providers and models for Sakina Home Screen.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_utils.dart';
import '../../../data/prayer/prayer_repository.dart';
import '../../../data/settings/settings_repository.dart';

// ─────────────────────────── Arabic Names Mapping ───────────────────────────

const Map<String, String> prayerArabicNames = {
  'Fajr': 'الفجر',
  'Sunrise': 'الشروق',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};

String getPrayerArabicName(String name) => prayerArabicNames[name] ?? name;

// ─────────────────────────── Date Formatting Providers ──────────────────────

/// Current Hijri date as formatted Arabic text (e.g., "14 جمادى الأولى 1448 هـ")
final hijriDateStringProvider = Provider<String>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final hDate = AppDateUtils.toHijri(DateTime.now(),
      adjustmentDays: settings.hijriOffset);
  return hDate.format(
      languageCode: 'ar',
      useArabicDigits: settings.numeralType == NumeralType.arabic);
});

/// Current Gregorian date in Arabic (e.g., "السبت، 14 نوفمبر 2026")
final gregorianDateStringProvider = Provider<String>((ref) {
  final now = DateTime.now();
  final formatter = DateFormat('EEEE، d MMMM y', 'ar');
  return formatter.format(now);
});

// ─────────────────────────── Prayer Progress Provider ───────────────────────

class NextPrayerProgress {
  final String prayerName;
  final String prayerArabicName;
  final DateTime targetTime;
  final Duration remaining;
  final double progress; // 0.0 to 1.0 (0.0 = just started, 1.0 = adhan reached)
  final String formattedCountdown;

  const NextPrayerProgress({
    required this.prayerName,
    required this.prayerArabicName,
    required this.targetTime,
    required this.remaining,
    required this.progress,
    required this.formattedCountdown,
  });
}

final nextPrayerProgressProvider = StreamProvider<NextPrayerProgress?>((ref) {
  final scheduleAsync = ref.watch(prayerTimesProvider);

  return scheduleAsync.when(
    data: (schedule) {
      if (schedule.isEmpty) return Stream.value(null);

      NextPrayerProgress? current() {
        final nowUtc = DateTime.now().toUtc();
        final orderedNames = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

        DateTime? prevTime;
        String? nextName;
        DateTime? nextTime;

        // Traverse days to find previous and next prayer relative to nowUtc
        for (final day in schedule) {
          for (final name in orderedNames) {
            final t = day.times[name];
            if (t == null) continue;

            if (t.isBefore(nowUtc) || t.isAtSameMomentAs(nowUtc)) {
              prevTime = t;
            } else if (t.isAfter(nowUtc)) {
              nextName = name;
              nextTime = t;
              break;
            }
          }
          if (nextName != null) break;
        }

        if (nextName == null || nextTime == null) return null;

        // Default prevTime if null (start of current prayer cycle 3 hours prior)
        prevTime ??= nextTime.subtract(const Duration(hours: 3));

        final totalDuration = nextTime.difference(prevTime).inSeconds;
        final elapsed = nowUtc.difference(prevTime).inSeconds;
        final remaining = nextTime.difference(nowUtc);

        double progress = 0.0;
        if (totalDuration > 0) {
          progress = (elapsed / totalDuration).clamp(0.0, 1.0);
        }

        final hours = remaining.inHours.toString().padLeft(2, '0');
        final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        final formattedCountdown = '$hours:$minutes:$seconds';

        return NextPrayerProgress(
          prayerName: nextName,
          prayerArabicName: getPrayerArabicName(nextName),
          targetTime: nextTime.toLocal(),
          remaining: remaining.isNegative ? Duration.zero : remaining,
          progress: progress,
          formattedCountdown: formattedCountdown,
        );
      }
      return (() async* {
        yield current();
        yield* Stream.periodic(const Duration(seconds: 1), (_) => current());
      })();
    },
    loading: () => Stream.value(null),
    error: (error, stack) => Stream.error(error, stack),
  );
});

// ─────────────────────────── Daily Dhikr Model & Provider ───────────────────

class DailyDhikr {
  final String text;
  final String virtue;
  final String source;
  final int count;

  const DailyDhikr({
    required this.text,
    required this.virtue,
    required this.source,
    this.count = 100,
  });
}

final dailyDhikrList = const [
  DailyDhikr(
    text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    virtue: 'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن',
    source: 'صحيح البخاري ومسلم',
    count: 100,
  ),
  DailyDhikr(
    text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    virtue: 'كانت له عدل عشر رقاب، وكتبت له مائة حسنة، ومحيت عنه مائة سيئة',
    source: 'متفق عليه',
    count: 100,
  ),
  DailyDhikr(
    text: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
    virtue: 'من لزم الاستغفار جعل الله له من كل هم فرجاً ومن كل ضيق مخرجاً',
    source: 'سنن أبي داود',
    count: 100,
  ),
  DailyDhikr(
    text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    virtue: 'من صلى عليّ صلاة صلى الله عليه بها عشراً',
    source: 'صحيح مسلم',
    count: 10,
  ),
  DailyDhikr(
    text: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
    virtue: 'كنز من كنوز الجنة ودواء لتسعة وتسعين داء أيسرها الهم',
    source: 'متفق عليه',
    count: 100,
  ),
  DailyDhikr(
    text: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
    virtue: 'أحب الكلام إلى الله تعالى، وهن الباقيات الصالحات',
    source: 'صحيح مسلم',
    count: 33,
  ),
  DailyDhikr(
    text: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
    virtue: 'دعاء جامع لتفريج الكروب والهموم وصلاح الأحوال',
    source: 'سنن النسائي والحاكم',
    count: 3,
  ),
];

final dailyDhikrProvider = Provider<DailyDhikr>((ref) {
  final now = DateTime.now();
  final dayOfYear = int.parse(DateFormat('D').format(now));
  final index = dayOfYear % dailyDhikrList.length;
  return dailyDhikrList[index];
});
