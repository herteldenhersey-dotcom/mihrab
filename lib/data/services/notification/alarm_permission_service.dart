import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages the Android 12+ (API 31+) exact-alarm permission.
///
/// Policy background (documented for maintainers):
///  * `SCHEDULE_EXACT_ALARM` — on Android 12/13 the user may revoke it; on
///    Android 14+ it is NOT granted by default for general apps and must be
///    requested (opens system settings). We use THIS permission because prayer
///    reminders are a legitimate exact-timing use case but MİHRAB is not a
///    clock/calendar app.
///  * `USE_EXACT_ALARM` — auto-granted but Google Play only allows it for
///    alarm-clock / calendar apps. We declare it in the manifest guarded by a
///    comment but rely on SCHEDULE_EXACT_ALARM at runtime to stay policy-safe.
///
/// Fallback: when exact alarms are unavailable, callers must schedule INEXACT
/// alarms (see [AndroidPrayerNotificationScheduler]); a WorkManager periodic
/// task then re-verifies/refreshes the schedule so reminders still fire, just
/// without to-the-second precision.
class AlarmPermissionService {
  final FlutterLocalNotificationsPlugin _plugin;

  AlarmPermissionService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Whether exact alarms can currently be scheduled.
  ///
  /// Returns true on non-Android platforms (iOS handles this differently).
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    final result = await _android?.canScheduleExactNotifications();
    // Older Android (<12) returns null → exact alarms allowed implicitly.
    return result ?? true;
  }

  /// Requests exact-alarm permission (opens system settings on Android 12+).
  /// Returns whether exact alarms are usable after the request.
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    if (await canScheduleExactAlarms()) return true;
    final granted = await _android?.requestExactAlarmsPermission();
    if (granted == true) return true;
    // Re-check in case the user granted it via the settings screen.
    return canScheduleExactAlarms();
  }
}
