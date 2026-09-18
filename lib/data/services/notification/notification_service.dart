import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Low-level notification abstraction.
///
/// Hides `flutter_local_notifications` + `timezone` behind a small surface so
/// the schedulers stay testable and platform-agnostic.
abstract class NotificationService {
  /// Initializes plugins, timezone DB and channels. Call once at startup.
  Future<void> init();

  /// Requests OS notification permission (iOS + Android 13+). Returns granted.
  Future<bool> requestPermission();

  /// Schedules a single notification at an absolute local [when].
  ///
  /// [exact] selects exact vs. inexact alarm scheduling on Android. On iOS the
  /// OS always treats these as best-effort local notifications.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
    bool exact = true,
  });

  /// Cancels every scheduled notification.
  Future<void> cancelAll();

  /// Cancels a single notification by id.
  Future<void> cancel(int id);

  /// Number of currently pending (scheduled) notifications.
  Future<int> pendingCount();
}

/// Concrete [NotificationService] using `flutter_local_notifications`.
class FlutterLocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  FlutterLocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'prayer_times_channel';
  static const String _channelName = 'Namaz Vakitleri';
  static const String _channelDesc =
      'Namaz vakti hatırlatma bildirimleri';

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    // Best-effort: keep the device's local zone. A full implementation can
    // resolve the IANA name via flutter_timezone; UTC is a safe fallback that
    // still fires at the correct wall-clock because we schedule TZDateTime in
    // the resolved local zone below.
    try {
      tz.setLocalLocation(tz.getLocation(tz.local.name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(initSettings);

    // Create the Android channel up-front.
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
      ),
    );

    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true; // pre-Android 13 returns null (implicitly granted)
    }
    return false;
  }

  @override
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
    bool exact = true,
  }) async {
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    // Don't schedule times in the past.
    if (tzWhen.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<int> pendingCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }
}
