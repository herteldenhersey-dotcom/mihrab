part of 'home_cubit.dart';

/// Sealed state hierarchy for [HomeCubit].
///
/// States:
/// • [HomeInitial]          — cubit just created, not yet loaded
/// • [HomeLoading]          — prayer times being fetched/calculated
/// • [HomeLoaded]           — happy path: all data available, countdown running
/// • [HomeMissingLocation]  — no valid saved location exists
/// • [HomeFailure]          — unexpected error (calculation or repo failure)
sealed class HomeState extends Equatable {
  const HomeState();
}

/// Cubit freshly instantiated, [HomeCubit.load] not yet called.
class HomeInitial extends HomeState {
  const HomeInitial();
  @override
  List<Object?> get props => [];
}

/// Calculating/fetching prayer times.
class HomeLoading extends HomeState {
  const HomeLoading();
  @override
  List<Object?> get props => [];
}

/// All data is ready and the countdown is running.
class HomeLoaded extends HomeState {
  /// The location whose times are being displayed.
  final AppLocation location;

  /// IANA timezone ID used for this location (e.g. "Europe/Istanbul").
  final String timezoneId;

  /// "Now" expressed in the selected location's timezone.
  /// Used to derive the displayed Gregorian/Hijri date and prayer day.
  final DateTime locationNow;

  /// Today's prayer times (in selected-location time).
  final DailyPrayerTimes today;

  /// Tomorrow's prayer times — needed for the after-Isha → Fajr countdown.
  final DailyPrayerTimes tomorrow;

  /// The next *obligatory* prayer (Sunrise excluded from "Next Prayer").
  final NextPrayer nextPrayer;

  /// Remaining time until [nextPrayer.time].  Recalculated each tick from
  /// the real clock so sleep/background drift is impossible.
  final Duration countdown;

  /// Gregorian date formatted for the active locale (e.g. "18 Eylül 2026").
  final String gregorianFormatted;

  /// Hijri date formatted for the active locale (e.g. "15 Ramazan 1447").
  final String hijriFormatted;

  /// Whether timezone was resolved from cache (vs. live resolution).
  /// Informational — used by analytics/debug, not the UI.
  final bool timezoneFromCache;

  const HomeLoaded({
    required this.location,
    required this.timezoneId,
    required this.locationNow,
    required this.today,
    required this.tomorrow,
    required this.nextPrayer,
    required this.countdown,
    required this.gregorianFormatted,
    required this.hijriFormatted,
    this.timezoneFromCache = false,
  });

  HomeLoaded copyWithCountdown(Duration countdown) => HomeLoaded(
        location: location,
        timezoneId: timezoneId,
        locationNow: locationNow,
        today: today,
        tomorrow: tomorrow,
        nextPrayer: nextPrayer,
        countdown: countdown,
        gregorianFormatted: gregorianFormatted,
        hijriFormatted: hijriFormatted,
        timezoneFromCache: timezoneFromCache,
      );

  @override
  List<Object?> get props => [
        location,
        timezoneId,
        locationNow,
        today,
        tomorrow,
        nextPrayer.type,
        nextPrayer.time,
        countdown,
        gregorianFormatted,
        hijriFormatted,
        timezoneFromCache,
      ];
}

/// No valid saved location — user must set one.
class HomeMissingLocation extends HomeState {
  const HomeMissingLocation();
  @override
  List<Object?> get props => [];
}

/// A recoverable failure occurred (calculation error, repository error, etc.).
class HomeFailure extends HomeState {
  final String message;
  const HomeFailure(this.message);
  @override
  List<Object?> get props => [message];
}
