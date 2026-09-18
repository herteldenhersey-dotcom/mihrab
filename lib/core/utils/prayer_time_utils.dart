import '../../domain/enums/prayer_type.dart';
import '../../domain/models/prayer_times_model.dart';
import 'date_utils.dart';

/// Represents the "next prayer" relative to a reference instant.
class NextPrayer {
  final PrayerType type;
  final DateTime time;

  /// True if [time] is on the following day (e.g. after Isha → tomorrow Fajr).
  final bool isTomorrow;

  const NextPrayer({
    required this.type,
    required this.time,
    required this.isTomorrow,
  });
}

/// Pure helpers for "next prayer" and countdown logic, including the midnight
/// edge case (after Isha, the next prayer is the next day's Fajr).
class PrayerTimeUtils {
  PrayerTimeUtils._();

  /// Returns the next upcoming prayer given [today]'s times, an optional
  /// [tomorrow]'s times (needed for the post-Isha window), and [now].
  ///
  /// If [now] is after today's Isha and [tomorrow] is provided, returns
  /// tomorrow's Fajr. If [tomorrow] is null in that window, returns today's
  /// Fajr flagged as [isTomorrow] with the time advanced by one day so callers
  /// can still compute a countdown.
  static NextPrayer getNextPrayer(
    DailyPrayerTimes today,
    DateTime now, {
    DailyPrayerTimes? tomorrow,
  }) {
    for (final entry in today.ordered) {
      if (entry.value.isAfter(now)) {
        return NextPrayer(
          type: entry.key,
          time: entry.value,
          isTomorrow: false,
        );
      }
    }
    // Past Isha → next is tomorrow's Fajr.
    if (tomorrow != null) {
      return NextPrayer(
        type: PrayerType.fajr,
        time: tomorrow.fajr,
        isTomorrow: true,
      );
    }
    // Fallback: advance today's Fajr by a day so a countdown is still valid.
    return NextPrayer(
      type: PrayerType.fajr,
      time: today.fajr.add(const Duration(days: 1)),
      isTomorrow: true,
    );
  }

  /// Returns the currently-active prayer window (the most recent prayer that
  /// has already started), or null if [now] is before Fajr.
  static PrayerType? getCurrentPrayer(DailyPrayerTimes today, DateTime now) {
    PrayerType? current;
    for (final entry in today.ordered) {
      if (!entry.value.isAfter(now)) {
        current = entry.key;
      } else {
        break;
      }
    }
    return current;
  }

  /// Countdown [Duration] from [now] until [target]. Never negative.
  static Duration getCountdown(DateTime target, DateTime now) {
    final diff = target.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Formats a [Duration] as HH:mm:ss.
  static String formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Whether [date] falls in Ramadan (delegates to Hijri calc).
  static bool isRamadan(DateTime date) => AppDateUtils.isRamadan(date);
}
