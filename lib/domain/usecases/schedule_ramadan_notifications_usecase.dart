import '../../data/services/ramadan/ramadan_notification_scheduler.dart';
import '../entities/ramadan_settings.dart';
import '../models/calculation_settings_model.dart';
import '../models/prayer_times_model.dart';
import 'get_prayer_times_usecase.dart';

/// Computes the next [RamadanNotificationScheduler.horizonDays] of prayer times
/// (reusing [GetPrayerTimesUseCase] — no duplicated calculation, spec) and
/// hands them to the [RamadanNotificationScheduler].
class ScheduleRamadanNotificationsUseCase {
  final GetPrayerTimesUseCase _getPrayerTimes;
  final RamadanNotificationScheduler _scheduler;

  const ScheduleRamadanNotificationsUseCase(
      this._getPrayerTimes, this._scheduler);

  Future<void> call({
    required double latitude,
    required double longitude,
    required CalculationSettings settings,
    required RamadanSettings ramadanSettings,
    required RamadanNotificationCopy copy,
    String? locationTzId,
    bool exact = true,
    DateTime? from,
  }) async {
    if (!ramadanSettings.sahurEnabled && !ramadanSettings.iftarEnabled) {
      // Nothing enabled → clear any lingering Ramadan notifications (scoped).
      await _scheduler.cancel();
      return;
    }

    final start = from ?? DateTime.now();
    final days = <DailyPrayerTimes>[];
    for (var i = 0; i < RamadanNotificationScheduler.horizonDays; i++) {
      days.add(await _getPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: start.add(Duration(days: i)),
        settings: settings,
      ));
    }

    await _scheduler.scheduleWeek(
      days: days,
      settings: ramadanSettings,
      copy: copy,
      locationTzId: locationTzId,
      exact: exact,
      now: start,
    );
  }

  Future<void> cancel() => _scheduler.cancel();
}
