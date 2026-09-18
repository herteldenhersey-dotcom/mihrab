/// Constants governing prayer scheduling and notification limits.
class PrayerConstants {
  PrayerConstants._();

  /// iOS hard limit on pending local notifications (OS-enforced).
  static const int iosMaxPendingNotifications = 64;

  /// Number of days ahead we schedule prayer notifications in one pass.
  /// 7 days × 6 prayers = 42 notifications, safely under the iOS 64 cap and
  /// leaving headroom for other reminders (Jummah, Ramadan).
  static const int scheduleWindowDays = 7;

  /// Prayers eligible for notification (sunrise reminder optional).
  static const int prayersPerDay = 6;

  /// Overpass request timeout.
  static const Duration overpassTimeout = Duration(seconds: 10);

  /// Max retries for Overpass requests (in addition to the first attempt).
  static const int overpassMaxRetries = 2;

  /// How long mosque results are considered fresh in the cache.
  static const Duration mosqueCacheTtl = Duration(hours: 24);

  /// Base backoff used for exponential retry (×2^attempt).
  static const Duration retryBaseDelay = Duration(milliseconds: 800);

  /// Notification id ranges. Each day/prayer maps to a deterministic id so
  /// re-scheduling overwrites rather than duplicates.
  static const int notificationIdBase = 1000;
}
