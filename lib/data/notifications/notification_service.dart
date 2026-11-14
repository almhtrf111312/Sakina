import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../core/utils/alarm_bridge.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum NotificationType { fullAdhan, shortAdhan, silent, vibrate, off }

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

// ─── Models ───────────────────────────────────────────────────────────────────

class PrayerNotificationConfig {
  final PrayerName prayer;
  final NotificationType type;
  final String soundId;
  final double volume;
  final bool gradualVolume;
  final int preAdhanMinutes;
  final int iqamaMinutes;
  final DateTime prayerTimeMs;

  const PrayerNotificationConfig({
    required this.prayer,
    required this.type,
    required this.soundId,
    required this.volume,
    required this.gradualVolume,
    required this.preAdhanMinutes,
    required this.iqamaMinutes,
    required this.prayerTimeMs,
  });

  String get prayerArabicName {
    switch (prayer) {
      case PrayerName.fajr:
        return 'الفجر';
      case PrayerName.dhuhr:
        return 'الظهر';
      case PrayerName.asr:
        return 'العصر';
      case PrayerName.maghrib:
        return 'المغرب';
      case PrayerName.isha:
        return 'العشاء';
    }
  }

  Map<String, dynamic> toMap() => {
        'name': prayerArabicName,
        'timeMs': prayerTimeMs.millisecondsSinceEpoch,
        'notificationType': type.name,
        'soundId': soundId,
        'volume': volume,
        'gradualVolume': gradualVolume,
        'preAdhanMinutes': preAdhanMinutes,
        'iqamaMinutes': iqamaMinutes,
      };
}

// ─── Notification Channels ────────────────────────────────────────────────────

class _NChannels {
  static const String adhan = 'sakina_adhan';
  static const String adhanName = 'أذان الصلاة';
  static const String adhanDesc = 'تنبيهات وقت الصلاة والأذان';

  static const String azkar = 'sakina_azkar';
  static const String azkarName = 'أذكار';
  static const String azkarDesc = 'تذكيرات الأذكار الصباحية والمسائية';

  static const String reminder = 'sakina_reminder';
  static const String reminderName = 'تذكيرات';
  static const String reminderDesc = 'تذكيرات الجمعة والصيام وغيرها';

  static const String preAdhan = 'sakina_pre_adhan';
  static const String preAdhanName = 'تنبيه ما قبل الأذان';
  static const String preAdhanDesc = 'تنبيه قبل موعد الأذان بدقائق';
}

// ─── Service ──────────────────────────────────────────────────────────────────

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings(
        '@drawable/ic_notification_moon');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Adhan channel (high importance, allows full-screen intent)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _NChannels.adhan,
        _NChannels.adhanName,
        description: _NChannels.adhanDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF5FB59B),
      ),
    );

    // Pre-adhan channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _NChannels.preAdhan,
        _NChannels.preAdhanName,
        description: _NChannels.preAdhanDesc,
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ),
    );

    // Azkar channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _NChannels.azkar,
        _NChannels.azkarName,
        description: _NChannels.azkarDesc,
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    // Reminder channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _NChannels.reminder,
        _NChannels.reminderName,
        description: _NChannels.reminderDesc,
        importance: Importance.defaultImportance,
      ),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Route to relevant screen based on payload
    debugPrint('[NotificationService] Tapped: ${response.payload}');
  }

  // ─── Prayer Alarms (sent to Kotlin via MethodChannel) ─────────────────────

  /// Schedule native alarms for a full day's prayer times.
  Future<void> schedulePrayerAlarms(
      List<PrayerNotificationConfig> configs) async {
    final maps = configs
        .where((c) => c.type != NotificationType.off)
        .map((c) => c.toMap())
        .toList();
    await AlarmBridge.schedulePrayerAlarms(maps);
  }

  /// Cancel all prayer alarms (called before rescheduling on settings change).
  Future<void> cancelAllPrayerAlarms() async {
    await AlarmBridge.cancelAllAlarms();
  }

  /// Reschedule when settings change (call with the new configs).
  Future<void> rescheduleOnSettingsChange(
      List<PrayerNotificationConfig> configs) async {
    await cancelAllPrayerAlarms();
    await schedulePrayerAlarms(configs);
  }

  // ─── Pre-Adhan Local Notifications ────────────────────────────────────────

  Future<void> schedulePreAdhanReminder({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required int minutesBefore,
  }) async {
    if (minutesBefore <= 0) return;
    final reminderTime =
        prayerTime.subtract(Duration(minutes: minutesBefore));
    if (reminderTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      'تذكير: $prayerName بعد $minutesBefore دقيقة',
      'استعد لصلاة $prayerName',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _NChannels.preAdhan,
          _NChannels.preAdhanName,
          channelDescription: _NChannels.preAdhanDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF5FB59B),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'pre_adhan', 'prayer': prayerName}),
    );
  }

  // ─── Azkar Reminders ──────────────────────────────────────────────────────

  Future<void> scheduleMorningAzkarReminder({
    required TimeOfDay time,
    required bool enabled,
  }) async {
    const id = 2000;
    await _plugin.cancel(id);
    if (!enabled) return;

    final now = DateTime.now();
    var scheduled = DateTime(
        now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      'أذكار الصباح',
      'حان وقت أذكار الصباح، أذكر الله يذكرك',
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _NChannels.azkar,
          _NChannels.azkarName,
          channelDescription: _NChannels.azkarDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFC9A86A),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'azkar', 'period': 'morning'}),
    );
  }

  Future<void> scheduleEveningAzkarReminder({
    required TimeOfDay time,
    required bool enabled,
  }) async {
    const id = 2001;
    await _plugin.cancel(id);
    if (!enabled) return;

    final now = DateTime.now();
    var scheduled = DateTime(
        now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      'أذكار المساء',
      'حان وقت أذكار المساء، أذكر الله يذكرك',
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _NChannels.azkar,
          _NChannels.azkarName,
          channelDescription: _NChannels.azkarDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF5FB59B),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'azkar', 'period': 'evening'}),
    );
  }

  // ─── Friday Reminder ──────────────────────────────────────────────────────

  Future<void> scheduleFridayReminder({
    required TimeOfDay time,
    required bool enabled,
  }) async {
    const id = 3000;
    await _plugin.cancel(id);
    if (!enabled) return;

    // Find next Friday
    final now = DateTime.now();
    int daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
    if (daysUntilFriday == 0) daysUntilFriday = 7;
    final nextFriday = DateTime(now.year, now.month, now.day + daysUntilFriday,
        time.hour, time.minute);

    await _plugin.zonedSchedule(
      id,
      'تذكير يوم الجمعة',
      'أكثر من الصلاة على النبي ﷺ وقراءة سورة الكهف',
      tz.TZDateTime.from(nextFriday, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _NChannels.reminder,
          _NChannels.reminderName,
          channelDescription: _NChannels.reminderDesc,
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFC9A86A),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: jsonEncode({'type': 'friday'}),
    );
  }

  // ─── Fasting Reminder ─────────────────────────────────────────────────────

  Future<void> scheduleFastingReminder({
    required bool suhoorEnabled,
    required int suhoorMinutesBefore,
    required bool iftarEnabled,
  }) async {
    const suhoorId = 4000;
    const iftarId = 4001;
    await _plugin.cancel(suhoorId);
    await _plugin.cancel(iftarId);
    // These are scheduled via native AlarmScheduler after Fajr/Maghrib times
    // are known. Here we simply pass a flag to the native side.
    debugPrint(
        '[NotificationService] Fasting reminders: suhoor=$suhoorEnabled iftarEnabled=$iftarEnabled');
  }

  // ─── Iqama Reminder ───────────────────────────────────────────────────────

  Future<void> scheduleIqamaReminder({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required int iqamaMinutes,
  }) async {
    if (iqamaMinutes <= 0) return;
    final iqamaTime = prayerTime.add(Duration(minutes: iqamaMinutes));
    if (iqamaTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id + 10000, // offset to avoid collision with pre-adhan
      'إقامة صلاة $prayerName',
      'حان وقت الإقامة',
      tz.TZDateTime.from(iqamaTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _NChannels.preAdhan,
          _NChannels.preAdhanName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF5FB59B),
          playSound: false,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'iqama', 'prayer': prayerName}),
    );
  }

  // ─── Cancel all local notifications ───────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
