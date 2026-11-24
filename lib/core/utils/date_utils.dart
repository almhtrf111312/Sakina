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
  // Gregorian to Hijri conversion (tabular Islamic calendar)
  // ---------------------------------------------------------------------------

  /// Converts a civil date using the arithmetic Hijri calendar.
  /// [adjustmentDays] accounts for local differences in moon sighting.
  static HijriDate toHijri(DateTime date, {int adjustmentDays = 0}) {
    final civilDate = DateTime.utc(date.year, date.month, date.day + adjustmentDays);
    final unixDay = civilDate.difference(DateTime.utc(1970)).inDays;
    const islamicEpoch = 1948440;
    const unixEpoch = 2440588;
    final daysSinceEpoch = unixDay + unixEpoch - islamicEpoch;
    final year = ((30 * daysSinceEpoch + 10646) / 10631).floor();
    final yearStart = 354 * (year - 1) + ((3 + 11 * year) / 30).floor();
    final dayOfYear = daysSinceEpoch - yearStart;

    int monthStart(int month) => 29 * (month - 1) + month ~/ 2;
    var month = 1;
    while (month < 12 && dayOfYear >= monthStart(month + 1)) {
      month++;
    }

    return HijriDate(
      year: year,
      month: month,
      day: dayOfYear - monthStart(month) + 1,
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
