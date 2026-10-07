part of 'ramadan_cubit.dart';

/// Sealed state hierarchy for [RamadanCubit].
sealed class RamadanState extends Equatable {
  const RamadanState();

  @override
  List<Object?> get props => [];
}

class RamadanInitial extends RamadanState {
  const RamadanInitial();
}

class RamadanLoading extends RamadanState {
  const RamadanLoading();
}

/// No valid saved location — cannot compute Imsak/Iftar.
class RamadanMissingLocation extends RamadanState {
  const RamadanMissingLocation();
}

class RamadanFailure extends RamadanState {
  final String messageKey;
  const RamadanFailure(this.messageKey);

  @override
  List<Object?> get props => [messageKey];
}

/// Happy path: Ramadan info + Imsak/Iftar + live countdown + settings.
class RamadanLoaded extends RamadanState {
  final RamadanInfo info;
  final RamadanSettings settings;

  /// Imsak (= Fajr) for the current civil day in the selected location.
  final DateTime imsak;

  /// Iftar (= Maghrib) for the current civil day.
  final DateTime iftar;

  /// Tomorrow's Imsak — needed for the after-Iftar countdown.
  final DateTime tomorrowImsak;

  /// Live countdown (recomputed each tick from the real clock).
  final RamadanCountdown countdown;

  /// "Now" in the selected location's timezone.
  final DateTime locationNow;

  final String timezoneId;

  const RamadanLoaded({
    required this.info,
    required this.settings,
    required this.imsak,
    required this.iftar,
    required this.tomorrowImsak,
    required this.countdown,
    required this.locationNow,
    required this.timezoneId,
  });

  RamadanLoaded copyWith({
    RamadanInfo? info,
    RamadanSettings? settings,
    DateTime? imsak,
    DateTime? iftar,
    DateTime? tomorrowImsak,
    RamadanCountdown? countdown,
    DateTime? locationNow,
    String? timezoneId,
  }) {
    return RamadanLoaded(
      info: info ?? this.info,
      settings: settings ?? this.settings,
      imsak: imsak ?? this.imsak,
      iftar: iftar ?? this.iftar,
      tomorrowImsak: tomorrowImsak ?? this.tomorrowImsak,
      countdown: countdown ?? this.countdown,
      locationNow: locationNow ?? this.locationNow,
      timezoneId: timezoneId ?? this.timezoneId,
    );
  }

  @override
  List<Object?> get props => [
        info,
        settings,
        imsak,
        iftar,
        tomorrowImsak,
        countdown.phase,
        countdown.remaining,
        countdown.target,
        locationNow,
        timezoneId,
      ];
}
