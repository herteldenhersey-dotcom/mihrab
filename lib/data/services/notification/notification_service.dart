import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/prayer_constants.dart';

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
  /// [useAdhanChannel] routes to the adhan sound channel when true.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
    bool exact = true,
    bool useAdhanChannel = false,
  });

  /// Cancels every scheduled notification.
  Future<void> cancelAll();

  /// Cancels a single notification by id.
  Future<void> cancel(int id);

  /// Number of currently pending (scheduled) notifications.
  Future<int> pendingCount();

  /// Schedules a test notification [secondsAhead] seconds from now.
  ///
  /// Uses a fixed ID of [PrayerConstants.testNotificationId] so it does NOT
  /// interfere with the regular prayer schedule. Fires only once and is
  /// cancellable via [cancel].
  Future<void> sendTestNotification({
    required String title,
    required String body,
    int secondsAhead = 5,
  });

  /// Returns a human-readable diagnostics string (pending count, next
  /// scheduled notification). Useful for the settings page debug tile.
  Future<NotificationDiagnostics> getDiagnostics();
}

/// Snapshot of notification scheduling state for diagnostic display.
class NotificationDiagnostics {
  final int pendingCount;
  final String? nextScheduledTitle;
  final DateTime? nextScheduledTime;

  const NotificationDiagnostics({
    required this.pendingCount,
    this.nextScheduledTitle,
    this.nextScheduledTime,
  });
}

/// Concrete [NotificationService] using `flutter_local_notifications`.
class FlutterLocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  FlutterLocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  // ── Channel: plain prayer times (existing, unchanged) ─────────────────
  static const String _channelId = 'prayer_times_channel';
  static const String _channelName = 'Namaz Vakitleri';
  static const String _channelDesc = 'Namaz vakti hatırlatma bildirimleri';

  // ── Channel: adhan sound (Phase 5 addition) ───────────────────────────
  //
  // Production usage:
  //   Replace adhan_placeholder.wav in android/app/src/main/res/raw/ with a
  //   properly licensed adhan recording.  The iOS equivalent lives at
  //   ios/Runner/adhan_placeholder.wav (must be < 30 s, .caf or .wav).
  //   Both are currently minimal-valid WAV placeholders.
  static const String _adhanChannelId = PrayerConstants.adhanChannelId;
  static const String _adhanChannelName = 'Ezan Sesi';
  static const String _adhanChannelDesc = 'Namaz vakti ezan bildirimleri';

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(tz.local.name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Plain prayer-time channel (unchanged from previous phases).
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
      ),
    );

    // Adhan channel with placeholder sound asset.
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _adhanChannelId,
        _adhanChannelName,
        description: _adhanChannelDesc,
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('adhan_placeholder'),
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
      return granted ?? true;
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
    bool useAdhanChannel = false,
  }) async {
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    if (tzWhen.isBefore(tz.TZDateTime.now(tz.local))) return;

    final AndroidNotificationDetails androidDetails;
    final DarwinNotificationDetails darwinDetails;

    if (useAdhanChannel) {
      androidDetails = const AndroidNotificationDetails(
        _adhanChannelId,
        _adhanChannelName,
        channelDescription: _adhanChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        sound: RawResourceAndroidNotificationSound('adhan_placeholder'),
        playSound: true,
      );
      darwinDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'adhan_placeholder.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      );
      darwinDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
    }

    final details = NotificationDetails(
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

  @override
  Future<void> sendTestNotification({
    required String title,
    required String body,
    int secondsAhead = 5,
  }) async {
    final when = DateTime.now().add(Duration(seconds: secondsAhead));
    await scheduleAt(
      id: PrayerConstants.testNotificationId,
      title: title,
      body: body,
      when: when,
      exact: true,
      useAdhanChannel: false,
    );
  }

  @override
  Future<NotificationDiagnostics> getDiagnostics() async {
    final pending = await _plugin.pendingNotificationRequests();
    if (pending.isEmpty) {
      return const NotificationDiagnostics(pendingCount: 0);
    }

    // The plugin doesn't expose scheduled times directly in pending requests
    // (they're stored internally). We return the count and first title found.
    final first = pending.first;
    return NotificationDiagnostics(
      pendingCount: pending.length,
      nextScheduledTitle: first.title,
    );
  }
}
