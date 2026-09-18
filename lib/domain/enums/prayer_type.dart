/// The canonical set of daily prayer events MİHRAB tracks.
///
/// [sunrise] is not an obligatory prayer but is required for the UI
/// (end of Fajr / countdown) and for scheduling the "imsak/sunrise" reminder.
enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha;

  /// Stable key used for persistence, notification ids and ARB lookups.
  String get key => name;

  /// Whether this event is one of the 5 obligatory prayers.
  bool get isObligatory => this != PrayerType.sunrise;

  static PrayerType fromKey(String key) =>
      PrayerType.values.firstWhere((e) => e.name == key,
          orElse: () => PrayerType.fajr);
}
