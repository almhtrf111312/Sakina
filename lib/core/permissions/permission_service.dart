import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission categories managed by Sakina.
enum AppPermissionType {
  notifications,
  exactAlarms,
  batteryOptimization,
  location,
  fullScreenIntent,
  drawOverApps,
}

/// Normalized status for any platform permission.
enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  notApplicable,
}

/// Comprehensive report of all permission statuses.
class PermissionReport {
  final Map<AppPermissionType, AppPermissionStatus> statuses;

  const PermissionReport({required this.statuses});

  AppPermissionStatus operator [](AppPermissionType type) =>
      statuses[type] ?? AppPermissionStatus.denied;

  bool get isAllCriticalGranted =>
      this[AppPermissionType.notifications] == AppPermissionStatus.granted &&
      this[AppPermissionType.exactAlarms] == AppPermissionStatus.granted;

  bool get hasAnyDenied =>
      statuses.values.any((s) => s != AppPermissionStatus.granted && s != AppPermissionStatus.notApplicable);

  int get grantedCount =>
      statuses.values.where((s) => s == AppPermissionStatus.granted).length;

  int get totalCount => statuses.length;

  double get completionPercentage =>
      totalCount == 0 ? 1.0 : (grantedCount / totalCount);
}

/// Service managing all permission checks, requests, and deep settings navigation.
class PermissionService {
  PermissionService._();

  static const MethodChannel _nativeChannel =
      MethodChannel('com.sakina.app/permissions');

  // ---------------------------------------------------------------------------
  // Check All Permissions
  // ---------------------------------------------------------------------------

  static Future<PermissionReport> checkAllPermissions() async {
    final map = <AppPermissionType, AppPermissionStatus>{};

    map[AppPermissionType.notifications] = await checkNotifications();
    map[AppPermissionType.location] = await checkLocation();
    map[AppPermissionType.exactAlarms] = await checkExactAlarms();
    map[AppPermissionType.batteryOptimization] = await checkBatteryOptimization();
    map[AppPermissionType.fullScreenIntent] = await checkFullScreenIntent();
    map[AppPermissionType.drawOverApps] = await checkDrawOverApps();

    return PermissionReport(statuses: map);
  }

  // ---------------------------------------------------------------------------
  // Individual Checks
  // ---------------------------------------------------------------------------

  static Future<AppPermissionStatus> checkNotifications() async {
    try {
      final status = await Permission.notification.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      debugPrint('[PermissionService] notification check error: $e');
      return AppPermissionStatus.denied;
    }
  }

  static Future<AppPermissionStatus> checkLocation() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      debugPrint('[PermissionService] location check error: $e');
      return AppPermissionStatus.denied;
    }
  }

  static Future<AppPermissionStatus> checkExactAlarms() async {
    if (!Platform.isAndroid) return AppPermissionStatus.notApplicable;

    try {
      final status = await Permission.scheduleExactAlarm.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      // Fallback via method channel
      try {
        final bool isAllowed =
            await _nativeChannel.invokeMethod('canScheduleExactAlarms') ?? false;
        return isAllowed
            ? AppPermissionStatus.granted
            : AppPermissionStatus.denied;
      } catch (_) {
        return AppPermissionStatus.granted; // Pre-Android 12 default granted
      }
    }
  }

  static Future<AppPermissionStatus> checkBatteryOptimization() async {
    if (!Platform.isAndroid) return AppPermissionStatus.notApplicable;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      try {
        final bool isIgnoring = await _nativeChannel
                .invokeMethod('isIgnoringBatteryOptimizations') ??
            false;
        return isIgnoring
            ? AppPermissionStatus.granted
            : AppPermissionStatus.denied;
      } catch (_) {
        return AppPermissionStatus.denied;
      }
    }
  }

  static Future<AppPermissionStatus> checkFullScreenIntent() async {
    if (!Platform.isAndroid) return AppPermissionStatus.notApplicable;

    try {
      final bool canUse =
          await _nativeChannel.invokeMethod('canUseFullScreenIntent') ?? true;
      return canUse
          ? AppPermissionStatus.granted
          : AppPermissionStatus.denied;
    } catch (_) {
      return AppPermissionStatus.granted; // Default granted on most versions
    }
  }

  static Future<AppPermissionStatus> checkDrawOverApps() async {
    if (!Platform.isAndroid) return AppPermissionStatus.notApplicable;

    try {
      final status = await Permission.systemAlertWindow.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      return AppPermissionStatus.denied;
    }
  }

  // ---------------------------------------------------------------------------
  // Request Methods
  // ---------------------------------------------------------------------------

  static Future<AppPermissionStatus> requestNotifications() async {
    final status = await Permission.notification.request();
    return _mapPermissionStatus(status);
  }

  static Future<AppPermissionStatus> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return _mapPermissionStatus(status);
  }

  static Future<AppPermissionStatus> requestExactAlarms() async {
    if (!Platform.isAndroid) return AppPermissionStatus.notApplicable;

    try {
      final status = await Permission.scheduleExactAlarm.request();
      if (!status.isGranted) {
        // Direct intent to Android Settings
        await _nativeChannel.invokeMethod('openExactAlarmSettings');
      }
      return _mapPermissionStatus(status);
    } catch (_) {
      await openExactAlarmSettings();
      return AppPermissionStatus.denied;
    }
  }

  static Future<AppPermissionStatus> requestBatteryOptimization() async {
    if (!Platform.isAndroid) return AppPermissionStatus.notApplicable;

    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (!status.isGranted) {
        await _nativeChannel.invokeMethod('openBatteryOptimizationSettings');
      }
      return _mapPermissionStatus(status);
    } catch (_) {
      await openAppSettings();
      return AppPermissionStatus.denied;
    }
  }

  static Future<AppPermissionStatus> requestDrawOverApps() async {
    if (!Platform.isAndroid) return AppPermissionStatus.notApplicable;

    final status = await Permission.systemAlertWindow.request();
    return _mapPermissionStatus(status);
  }

  // ---------------------------------------------------------------------------
  // Open Settings Deep Links
  // ---------------------------------------------------------------------------

  static Future<bool> openAppSettingsPage() async {
    return await openAppSettings();
  }

  static Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _nativeChannel.invokeMethod('openExactAlarmSettings');
    } catch (_) {
      await openAppSettings();
    }
  }

  static Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _nativeChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {
      await openAppSettings();
    }
  }

  // ---------------------------------------------------------------------------
  // Helper Mapper
  // ---------------------------------------------------------------------------

  static AppPermissionStatus _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return AppPermissionStatus.granted;
      case PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
      default:
        return AppPermissionStatus.denied;
    }
  }
}
