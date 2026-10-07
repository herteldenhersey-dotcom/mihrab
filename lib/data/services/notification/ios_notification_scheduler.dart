import '../../../core/constants/prayer_constants.dart';
import '../../../domain/enums/prayer_type.dart';
import '../../../domain/models/notification_settings_model.dart';
import '../../../domain/models/prayer_times_model.dart';
import 'notification_service.dart';
import 'prayer_notification_scheduler.dart';

/// iOS rolling scheduler.
///
/// iOS caps PENDING local notifications at 64 (OS-enforced) and does NOT
/// guarantee background execution. Strategy & documented limitations:
///
///  * We schedule at most [PrayerConstants.iosMaxPendingNotifications] (64)
///    notifications per pass, prioritising the soonest prayers first.
///  * With 5 obligatory prayers × 7 days = 35 notifications, well under the
///    64 cap. Re-scheduled every time the app is foregrounded.
///  * LIMITATION: if the user does NOT open the app for longer than the
///    scheduled window, iOS will run out of pending notifications and prayers
///    beyond the window will NOT fire. iOS provides no reliable way to
///    re-arm notifications purely in the background. This is an OS constraint,
///    not an app bug, and is surfaced to the user in Settings.
///  * LIMITATION: iOS does not allow custom notification sounds to bypass
///    Silent Mode / Focus. Time-sensitive interruption level is requested to
///    improve delivery, but silent-mode behaviour remains user/OS-controlled.
///
/// Phase 5 additions:
///  * [NotificationSettings] drives per-prayer enable/adhan/offset config.
///  * Reminder offset: fire notification N minutes BEFORE prayer time.
///  * Adhan channel hint passed to [NotificationService.scheduleAt].
class IosPrayerNotificationScheduler
    with PrayerSchedulerIdMixin
    implements PrayerNotificationScheduler {
  final NotificationService _service;

  IosPrayerNotificationScheduler(this._service);

  @override
  Future<void> scheduleWeek({
    required List<DailyPrayerTimes> days,
    required PrayerNotificationCopy copy,
    NotificationSettings? notificationSettings,
    Set<PrayerType>? enabledPrayers,
  }) async {
    final enabled = resolveEnabledPrayers(notificationSettings, enabledPrayers);
    await _service.cancelAll();

    if (enabled.isEmpty) return; // master switch off or nothing enabled

    final now = DateTime.now();

    // Flatten to a chronological list of future (dayIndex, prayer, fireTime).
    final slots = <({
      int dayIndex,
      PrayerType prayer,
      DateTime prayerTime,
      DateTime fireTime,
      bool adhan,
    })>[];

    for (var d = 0;
        d < days.length && d < PrayerConstants.scheduleWindowDays;
        d++) {
      for (final entry in days[d].ordered) {
        final prayer = entry.key;
        if (!enabled.contains(prayer)) continue;

        final config = notificationSettings?.prayerConfigs[prayer] ??
            const PrayerNotificationConfig();

        final fireTime = adjustedFireTime(entry.value, config);
        if (!fireTime.isAfter(now)) continue;

        slots.add((
          dayIndex: d,
          prayer: prayer,
          prayerTime: entry.value,
          fireTime: fireTime,
          adhan: useAdhanChannel(prayer, config),
        ));
      }
    }

    slots.sort((a, b) => a.fireTime.compareTo(b.fireTime));

    // Respect the iOS 64-pending cap.
    final capped = slots.take(PrayerConstants.iosMaxPendingNotifications);

    for (final slot in capped) {
      await _service.scheduleAt(
        id: notificationId(slot.dayIndex, slot.prayer),
        title: copy.title(slot.prayer),
        body: copy.body(slot.prayer, slot.prayerTime),
        when: slot.fireTime,
        payload: 'prayer:${slot.prayer.key}',
        exact: true,
        useAdhanChannel: slot.adhan,
      );
    }
  }

  @override
  Future<void> cancelAll() => _service.cancelAll();

  @override
  Future<int> pendingCount() => _service.pendingCount();
}
