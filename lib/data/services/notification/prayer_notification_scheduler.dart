import '../../../core/constants/prayer_constants.dart';
import '../../../domain/enums/prayer_type.dart';
import '../../../domain/models/notification_settings_model.dart';
import '../../../domain/models/prayer_times_model.dart';

/// Builds the (title, body) shown for a given prayer notification.
///
/// Injected by the presentation layer so all copy stays localized while the
/// data-layer scheduler remains framework-agnostic.
class PrayerNotificationCopy {
  final String Function(PrayerType type) title;
  final String Function(PrayerType type, DateTime time) body;

  const PrayerNotificationCopy({required this.title, required this.body});
}

/// Abstract rolling scheduler for prayer notifications.
///
/// Implementations schedule a bounded window of upcoming prayers (see
/// [PrayerConstants.scheduleWindowDays]) and are expected to be re-invoked
/// whenever the app is foregrounded so the window keeps rolling forward.
abstract class PrayerNotificationScheduler {
  /// Schedules notifications for the provided [days] (chronological).
  ///
  /// [notificationSettings] drives per-prayer enable/disable, adhan channel
  /// selection and reminder offset.  When null the scheduler uses defaults
  /// (all obligatory prayers, no adhan, 0-minute offset).
  ///
  /// [enabledPrayers] is a legacy override kept for backward-compatibility.
  /// If both [notificationSettings] and [enabledPrayers] are supplied,
  /// [notificationSettings] takes precedence.
  ///
  /// [locationTzId] is the IANA timezone of the selected location (e.g.
  /// `"Europe/Istanbul"`).  Passed through to [NotificationService.scheduleAt]
  /// so notifications fire at the correct wall-clock time in the selected
  /// city regardless of where the physical device is located.
  Future<void> scheduleWeek({
    required List<DailyPrayerTimes> days,
    required PrayerNotificationCopy copy,
    String? locationTzId,
    NotificationSettings? notificationSettings,
    Set<PrayerType>? enabledPrayers,
  });

  Future<void> cancelAll();

  Future<int> pendingCount();
}

/// Shared helpers for concrete schedulers.
mixin PrayerSchedulerIdMixin {
  /// Deterministic, collision-free id per (dayIndex, prayer) so re-scheduling
  /// overwrites the same slot instead of duplicating.
  int notificationId(int dayIndex, PrayerType prayer) {
    return PrayerConstants.notificationIdBase +
        dayIndex * 10 +
        prayer.index;
  }

  /// Default enabled prayers: the five obligatory prayers (sunrise excluded).
  Set<PrayerType> defaultEnabled() =>
      PrayerType.values.where((p) => p.isObligatory).toSet();

  /// Resolve the effective enabled prayers from [settings] or [fallback].
  ///
  /// Sunrise is ALWAYS excluded as an obligatory adhan source regardless of
  /// the config value stored in [settings].
  Set<PrayerType> resolveEnabledPrayers(
    NotificationSettings? settings,
    Set<PrayerType>? fallback,
  ) {
    if (settings != null) return settings.effectiveEnabledPrayers;
    if (fallback != null) return fallback.where((p) => p.isObligatory).toSet();
    return defaultEnabled();
  }

  /// Returns the adjusted fire time for a prayer given its [config].
  ///
  /// A [reminderOffsetMinutes] > 0 fires BEFORE the prayer time.
  /// 0 fires AT the prayer time.
  DateTime adjustedFireTime(DateTime prayerTime, PrayerNotificationConfig config) {
    if (config.reminderOffsetMinutes == 0) return prayerTime;
    return prayerTime.subtract(Duration(minutes: config.reminderOffsetMinutes));
  }

  /// Whether this prayer should use the adhan sound channel.
  ///
  /// Sunrise is never routed to the adhan channel.
  bool useAdhanChannel(PrayerType prayer, PrayerNotificationConfig config) {
    if (!prayer.isObligatory) return false;
    return config.adhanEnabled;
  }

  /// Returns ALL notification IDs that could be scheduled in a 7-day window.
  ///
  /// Used for SCOPED cancellation — cancels only the prayer schedule IDs so
  /// unrelated notifications (test notification, future reminder categories)
  /// are NOT accidentally removed.
  ///
  /// Formula: [PrayerConstants.notificationIdBase] + dayIndex × 10 + prayer.index
  /// Range: base + 0 .. base + scheduleWindowDays×10 - 1 (no collision with
  ///        [PrayerConstants.testNotificationId] which is always 0).
  List<int> allScheduleIds() {
    return [
      for (var d = 0; d < PrayerConstants.scheduleWindowDays; d++)
        for (final p in PrayerType.values) notificationId(d, p),
    ];
  }
}
