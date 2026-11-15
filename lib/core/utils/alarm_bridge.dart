import 'dart:convert';
import 'package:flutter/services.dart';

/// Flutter MethodChannel wrapper for calling Kotlin AlarmScheduler and AodActivity.
class AlarmBridge {
  static const MethodChannel _alarmChannel =
      MethodChannel('com.sakina.app/alarm');
  static const MethodChannel _aodChannel = MethodChannel('com.sakina.app/aod');
  static const EventChannel _alarmEventChannel =
      EventChannel('com.sakina.app/alarm_events');

  // ─── Alarm / Scheduler Methods ───────────────────────────────────────────

  /// Schedule prayer alarms for a list of prayer times.
  /// [prayers] is a list of maps with keys: name, timeMs, notificationType,
  /// soundId, volume, gradualVolume, preAdhanMinutes, iqamaMinutes.
  static Future<void> schedulePrayerAlarms(
      List<Map<String, dynamic>> prayers) async {
    try {
      await _alarmChannel.invokeMethod(
          'schedulePrayerAlarms', {'prayerTimes': jsonEncode(prayers)});
    } on PlatformException catch (e) {
      throw AlarmBridgeException('schedulePrayerAlarms failed: ${e.message}');
    }
  }

  /// Cancel all scheduled alarms.
  static Future<void> cancelAllAlarms() async {
    try {
      await _alarmChannel.invokeMethod('cancelAllAlarms');
    } on PlatformException catch (e) {
      throw AlarmBridgeException('cancelAllAlarms failed: ${e.message}');
    }
  }

  /// Cancel a specific alarm by prayer name.
  static Future<void> cancelAlarm(String prayerName) async {
    try {
      await _alarmChannel
          .invokeMethod('cancelAlarm', {'prayerName': prayerName});
    } on PlatformException catch (e) {
      throw AlarmBridgeException('cancelAlarm failed: ${e.message}');
    }
  }

  /// Check all alarm-related permissions, returns a map of permission → bool.
  static Future<Map<String, bool>> checkPermissions() async {
    try {
      final result = await _alarmChannel.invokeMethod('checkPermissions');
      return Map<String, bool>.from(result as Map);
    } on PlatformException catch (e) {
      throw AlarmBridgeException('checkPermissions failed: ${e.message}');
    }
  }

  /// Request SCHEDULE_EXACT_ALARM permission (opens system settings on Android 12+).
  static Future<void> requestExactAlarmPermission() async {
    try {
      await _alarmChannel.invokeMethod('requestExactAlarmPermission');
    } on PlatformException catch (e) {
      throw AlarmBridgeException(
          'requestExactAlarmPermission failed: ${e.message}');
    }
  }

  /// Request battery optimization exemption (opens system settings).
  static Future<void> requestBatteryOptimizationExemption() async {
    try {
      await _alarmChannel
          .invokeMethod('requestBatteryOptimizationExemption');
    } on PlatformException catch (e) {
      throw AlarmBridgeException(
          'requestBatteryOptimizationExemption failed: ${e.message}');
    }
  }

  /// Play a test adhan sound.
  /// Short tap sound and/or vibration (played natively, independent of the
  /// system "touch sounds" setting).
  static Future<void> tapFeedback({bool sound = true, bool haptic = true}) async {
    try {
      await _alarmChannel
          .invokeMethod('tapFeedback', {'sound': sound, 'haptic': haptic});
    } catch (_) {}
  }

  static Future<void> testAdhan(
      {required String soundId, required double volume}) async {
    try {
      await _alarmChannel
          .invokeMethod('testAdhan', {'soundId': soundId, 'volume': volume});
    } catch (_) {
      // Preview is best-effort.
    }
  }

  /// Stop any currently playing adhan/test sound.
  static Future<void> stopTestAdhan() async {
    try {
      await _alarmChannel.invokeMethod('stopTestAdhan');
    } catch (_) {}
  }

  /// Stream of alarm events from native (e.g. alarm fired, error).
  static Stream<AlarmEvent> get alarmEvents {
    return _alarmEventChannel.receiveBroadcastStream().map((dynamic event) {
      final map = Map<String, dynamic>.from(event as Map);
      return AlarmEvent(
        type: map['type'] as String,
        prayerName: map['prayerName'] as String?,
        message: map['message'] as String?,
      );
    });
  }

  // ─── AOD Methods ─────────────────────────────────────────────────────────

  /// Show the native AOD screen (AodActivity), passing prayer data.
  static Future<void> showAodScreen(Map<String, dynamic> prayerData) async {
    try {
      await _aodChannel
          .invokeMethod('showAodScreen', {'data': jsonEncode(prayerData)});
    } on PlatformException catch (e) {
      throw AlarmBridgeException('showAodScreen failed: ${e.message}');
    }
  }

  /// Hide/finish the AOD screen.
  static Future<void> hideAodScreen() async {
    try {
      await _aodChannel.invokeMethod('hideAodScreen');
    } on PlatformException catch (e) {
      throw AlarmBridgeException('hideAodScreen failed: ${e.message}');
    }
  }

  /// Returns true if the device supports AOD (can draw over lock screen).
  static Future<bool> isAodSupported() async {
    try {
      final result = await _aodChannel.invokeMethod('isAodSupported');
      return result as bool;
    } on PlatformException catch (e) {
      throw AlarmBridgeException('isAodSupported failed: ${e.message}');
    }
  }

  /// Push updated data (prayer times, settings) to the running AOD screen.
  static Future<void> updateAodData(Map<String, dynamic> data) async {
    try {
      await _aodChannel
          .invokeMethod('updateAodData', {'data': jsonEncode(data)});
    } on PlatformException catch (e) {
      throw AlarmBridgeException('updateAodData failed: ${e.message}');
    }
  }

  /// Open DRAW_OVER_OTHER_APPS system settings for the app.
  static Future<void> requestDrawOverApps() async {
    try {
      await _aodChannel.invokeMethod('requestDrawOverApps');
    } on PlatformException catch (e) {
      throw AlarmBridgeException('requestDrawOverApps failed: ${e.message}');
    }
  }

  // ─── Always-on screen ──────────────────────────────────────────────────────

  static Future<void> setAlwaysOn(Map<String, dynamic> cfg) async {
    try {
      await _aodChannel.invokeMethod('setAlwaysOn', cfg);
    } catch (_) {}
  }

  static Future<Map<String, bool>> alwaysOnStatus() async {
    try {
      final r = await _aodChannel.invokeMethod('alwaysOnStatus');
      if (r is Map) {
        return r.map((k, v) => MapEntry(k.toString(), v == true));
      }
    } catch (_) {}
    return const {};
  }

  static Future<void> openSetting(String method) async {
    try {
      await _aodChannel.invokeMethod(method);
    } catch (_) {}
  }

  static Future<void> previewAlwaysOn() async {
    try {
      await _aodChannel.invokeMethod('showAodScreen', {});
    } catch (_) {}
  }

  // ─── Widgets / persistent notification ─────────────────────────────────────

  /// Push the prayer schedule to home-screen widgets, the always-on screen and
  /// the persistent "next prayer" notification.
  static Future<void> updateWidgetData(String json) async {
    try {
      await _alarmChannel.invokeMethod('updateWidgetData', {'json': json});
    } catch (_) {}
  }
}

class AlarmBridgeException implements Exception {
  final String message;
  AlarmBridgeException(this.message);

  @override
  String toString() => 'AlarmBridgeException: $message';
}

class AlarmEvent {
  final String type;
  final String? prayerName;
  final String? message;

  const AlarmEvent({
    required this.type,
    this.prayerName,
    this.message,
  });
}
