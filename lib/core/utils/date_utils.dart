import 'dart:math' as math;
import 'package:intl/intl.dart';

/// Comprehensive date & time utility for Sakina.
/// Includes Hijri conversion, prayer time formatting, and countdown calculations.
class AppDateUtils {
  AppDateUtils._();

  // ---------------------------------------------------------------------------
  // Hijri Month Names
  // ---------------------------------------------------------------------------

  static const List<String> hijriMonthsAr = [
    'مُحَرَّم',
    'صَفَر',
    'رَبِيع الأَوَّل',
    'رَبِيع الآخِر',
    'جُمَادَى الأُولَى',
    'جُمَادَى الآخِرَة',
    'رَجَب',
    'شَعْبَان',
    'رَمَضَان',
    'شَوَّال',
    'ذُو القَعْدَة',
    'ذُو الحِجَّة',
  ];

  static const List<String> hijriMonthsEn = [
    'Muharram',
    'Safar',
    'Rabi\' al-Awwal',
    'Rabi\' al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];

  static const List<String> hijriMonthsTr = [
    'Muharrem',
    'Safer',
    'Rebiülevvel',
    'Rebiülahir',
    'Cemaziyelevvel',
    'Cemaziyelahir',
    'Recep',
    'Şaban',
    'Ramazan',
    'Şevval',
    'Zilkade',
    'Zilhicce',
  ];

  static const List<String> weekdaysAr = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  // ---------------------------------------------------------------------------
  // Gregorian to Hijri Conversion (Kuwaiti / Astronomical Algorithm)
  // ---------------------------------------------------------------------------

  /// Converts a Gregorian DateTime into [HijriDate].
  /// [adjustmentDays] allows manual correction by ±1 or ±2 days for moon sighting.
  static HijriDate toHijri(DateTime date, {int adjustmentDays = 0}) {
    DateTime adjustedDate = date.add(Duration(days: adjustmentDays));
    int day = adjustedDate.day;
    int month = adjustedDate.month;
    int year = adjustedDate.year;

    int m = month;
    int y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }

    int a = (y / 100).floor();
    int b = 2 - a + (a / 4).floor();
    if (y < 1583) b = 0;
    if (y == 1582) {
      if (m > 10) b = -10;
      if (m == 10) {
        b = 0;
        if (day > 4) b = -10;
      }
    }

    double jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;

    b = 0;
    if (jd > 2299160) {
      a = ((jd - 1867216.25) / 36524.25).floor();
      b = a - (a / 4).floor() + 1;
    }

    double bb = jd + b + 1524;
    int cc = ((bb - 122.1) / 365.25).floor();
    int dd = (365.25 * cc).floor();
    int ee = ((bb - dd) / 30.6001).floor();
    day = (bb - dd - (30.6001 * ee).floor()).floor();
    month = ee - 1;
    if (ee > 13) {
      cc += 1;
      month = ee - 13;
    }
    year = cc - 4716;

    double epoch = 1948439.5;
    double wd = (jd + 1.5) % 7;

    double z = jd - epoch;
    double cyc = (z / 10631).floorToDouble();
    z = z - 10631 * cyc;
    double j = ((z - 0.1335) / 354.36667).floorToDouble();
    double iy = 30 * cyc + j;
    z = z - (j * 354.36667 + 0.5).floorToDouble();
    double im = ((z + 28.5001) / 29.5).floorToDouble();
    if (im == 13) im = 12;
    int id = (z - (29.5001 * (im - 1) - 0.5).floorToDouble()).toInt();

    int hYear = iy.toInt();
    int hMonth = im.toInt();
    int hDay = id;

    // Guard bounds
    if (hMonth < 1) hMonth = 1;
    if (hMonth > 12) hMonth = 12;
    if (hDay < 1) hDay = 1;
    if (hDay > 30) hDay = 30;

    return HijriDate(
      year: hYear,
      month: hMonth,
      day: hDay,
      dayOfWeek: date.weekday,
    );
  }

  // ---------------------------------------------------------------------------
  // Formatting Helpers
  // ---------------------------------------------------------------------------

  /// Formats time in 12-hour or 24-hour style.
  /// Example (12h Ar): "04:30 م", Example (12h En): "04:30 PM", (24h): "16:30"
  static String formatPrayerTime(
    DateTime time, {
    bool is24Hour = false,
    String languageCode = 'ar',
  }) {
    if (is24Hour) {
      return DateFormat('HH:mm').format(time);
    }

    final hour24 = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final hourFormatted = hour12.toString().padLeft(2, '0');

    final isPm = hour24 >= 12;
    final amPm = switch (languageCode) {
      'ar' => isPm ? 'م' : 'ص',
      'tr' => isPm ? 'ÖS' : 'ÖÖ',
      _ => isPm ? 'PM' : 'AM',
    };

    return '$hourFormatted:$minute $amPm';
  }

  /// Formats duration into a countdown string: "HH:MM:SS" or "MM:SS"
  static String formatCountdown(Duration duration, {bool showSeconds = true}) {
    if (duration.isNegative) {
      return showSeconds ? '00:00:00' : '00:00';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    if (hours > 0 || !showSeconds) {
      return showSeconds ? '$hh:$mm:$ss' : '$hh:$mm';
    }
    return '$mm:$ss';
  }

  /// Returns remaining time human-readable in Arabic/English.
  /// Example: "بقي ساعتان و 15 دقيقة" or "2h 15m remaining"
  static String formatRemainingHuman(Duration duration, {String languageCode = 'ar'}) {
    if (duration.isNegative) {
      return languageCode == 'ar' ? 'حان وقت الصلاة' : 'Prayer time reached';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (languageCode == 'ar') {
      if (hours == 0) {
        return 'بقي $minutes دقيقة';
      } else if (hours == 1) {
        return minutes == 0 ? 'بقي ساعة' : 'بقي ساعة و $minutes دقيقة';
      } else if (hours == 2) {
        return minutes == 0 ? 'بقي ساعتان' : 'بقي ساعتان و $minutes دقيقة';
      } else if (hours <= 10) {
        return minutes == 0 ? 'بقي $hours ساعات' : 'بقي $hours ساعات و $minutes دقيقة';
      } else {
        return minutes == 0 ? 'بقي $hours ساعة' : 'بقي $hours ساعة و $minutes دقيقة';
      }
    } else {
      if (hours == 0) return '${minutes}m remaining';
      return '${hours}h ${minutes}m remaining';
    }
  }

  /// Formats a Gregorian date with weekday.
  /// Example: "الجمعة، 14 نوفمبر 2026"
  static String formatGregorianDate(DateTime date, {String languageCode = 'ar'}) {
    final locale = languageCode == 'ar' ? 'ar' : (languageCode == 'tr' ? 'tr' : 'en');
    return DateFormat('EEEE، d MMMM yyyy', locale).format(date);
  }

  /// Converts western digits (0-9) to Eastern Arabic digits (٠-٩)
  static String toArabicDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String output = input;
    for (int i = 0; i < english.length; i++) {
      output = output.replaceAll(english[i], arabic[i]);
    }
    return output;
  }
}

// ---------------------------------------------------------------------------
// HijriDate Model
// ---------------------------------------------------------------------------

class HijriDate {
  final int year;
  final int month;
  final int day;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday

  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
    required this.dayOfWeek,
  });

  /// Returns full Hijri date string according to language.
  /// Example (ar): "١٤ رجب ١٤٤٧ هـ"
  String format({String languageCode = 'ar', bool useArabicDigits = false}) {
    final monthName = switch (languageCode) {
      'ar' => AppDateUtils.hijriMonthsAr[(month - 1).clamp(0, 11)],
      'tr' => AppDateUtils.hijriMonthsTr[(month - 1).clamp(0, 11)],
      _ => AppDateUtils.hijriMonthsEn[(month - 1).clamp(0, 11)],
    };

    final dayStr = useArabicDigits ? AppDateUtils.toArabicDigits('$day') : '$day';
    final yearStr = useArabicDigits ? AppDateUtils.toArabicDigits('$year') : '$year';

    if (languageCode == 'ar') {
      return '$dayStr $monthName $yearStr هـ';
    } else if (languageCode == 'tr') {
      return '$dayStr $monthName $yearStr H.';
    } else {
      return '$dayStr $monthName $yearStr AH';
    }
  }

  /// Day of week name
  String getWeekdayName({String languageCode = 'ar'}) {
    final index = (dayOfWeek - 1).clamp(0, 6);
    if (languageCode == 'ar') {
      return AppDateUtils.weekdaysAr[index];
    }
    return DateFormat('EEEE', languageCode).format(
      DateTime(2026, 1, 5).add(Duration(days: index)),
    );
  }

  @override
  String toString() => '$day/$month/$year AH';
}
