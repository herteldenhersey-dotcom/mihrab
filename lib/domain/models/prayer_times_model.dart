import 'package:equatable/equatable.dart';

import '../enums/prayer_type.dart';

/// Per-prayer manual minute offsets.
///
/// This is the primary mechanism the spec requires for reconciling the
/// `adhan` output with the official Diyanet timetable when a small systematic
/// deviation exists. Offsets are applied AFTER the raw calculation.
class ManualOffsets extends Equatable {
  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  const ManualOffsets({
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });

  static const ManualOffsets zero = ManualOffsets();

  /// Offset (in minutes) for a given prayer.
  int forPrayer(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return fajr;
      case PrayerType.sunrise:
        return sunrise;
      case PrayerType.dhuhr:
        return dhuhr;
      case PrayerType.asr:
        return asr;
      case PrayerType.maghrib:
        return maghrib;
      case PrayerType.isha:
        return isha;
    }
  }

  ManualOffsets copyWith({
    int? fajr,
    int? sunrise,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    return ManualOffsets(
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  Map<String, dynamic> toJson() => {
        'fajr': fajr,
        'sunrise': sunrise,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };

  factory ManualOffsets.fromJson(Map<String, dynamic> json) => ManualOffsets(
        fajr: (json['fajr'] as num?)?.toInt() ?? 0,
        sunrise: (json['sunrise'] as num?)?.toInt() ?? 0,
        dhuhr: (json['dhuhr'] as num?)?.toInt() ?? 0,
        asr: (json['asr'] as num?)?.toInt() ?? 0,
        maghrib: (json['maghrib'] as num?)?.toInt() ?? 0,
        isha: (json['isha'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [fajr, sunrise, dhuhr, asr, maghrib, isha];
}

/// Immutable set of the six daily prayer times for a single calendar day.
class DailyPrayerTimes extends Equatable {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  /// The calendar day (local, midnight) these times belong to.
  final DateTime date;

  const DailyPrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// Returns the time for the given [PrayerType].
  DateTime timeFor(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return fajr;
      case PrayerType.sunrise:
        return sunrise;
      case PrayerType.dhuhr:
        return dhuhr;
      case PrayerType.asr:
        return asr;
      case PrayerType.maghrib:
        return maghrib;
      case PrayerType.isha:
        return isha;
    }
  }

  /// All prayers in chronological order as (type, time) pairs.
  List<MapEntry<PrayerType, DateTime>> get ordered => [
        MapEntry(PrayerType.fajr, fajr),
        MapEntry(PrayerType.sunrise, sunrise),
        MapEntry(PrayerType.dhuhr, dhuhr),
        MapEntry(PrayerType.asr, asr),
        MapEntry(PrayerType.maghrib, maghrib),
        MapEntry(PrayerType.isha, isha),
      ];

  DailyPrayerTimes copyWith({
    DateTime? date,
    DateTime? fajr,
    DateTime? sunrise,
    DateTime? dhuhr,
    DateTime? asr,
    DateTime? maghrib,
    DateTime? isha,
  }) {
    return DailyPrayerTimes(
      date: date ?? this.date,
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  /// Returns a new instance with [offsets] (minutes) applied to each prayer.
  DailyPrayerTimes applyOffsets(ManualOffsets offsets) {
    return DailyPrayerTimes(
      date: date,
      fajr: fajr.add(Duration(minutes: offsets.fajr)),
      sunrise: sunrise.add(Duration(minutes: offsets.sunrise)),
      dhuhr: dhuhr.add(Duration(minutes: offsets.dhuhr)),
      asr: asr.add(Duration(minutes: offsets.asr)),
      maghrib: maghrib.add(Duration(minutes: offsets.maghrib)),
      isha: isha.add(Duration(minutes: offsets.isha)),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'fajr': fajr.toIso8601String(),
        'sunrise': sunrise.toIso8601String(),
        'dhuhr': dhuhr.toIso8601String(),
        'asr': asr.toIso8601String(),
        'maghrib': maghrib.toIso8601String(),
        'isha': isha.toIso8601String(),
      };

  factory DailyPrayerTimes.fromJson(Map<String, dynamic> json) =>
      DailyPrayerTimes(
        date: DateTime.parse(json['date'] as String),
        fajr: DateTime.parse(json['fajr'] as String),
        sunrise: DateTime.parse(json['sunrise'] as String),
        dhuhr: DateTime.parse(json['dhuhr'] as String),
        asr: DateTime.parse(json['asr'] as String),
        maghrib: DateTime.parse(json['maghrib'] as String),
        isha: DateTime.parse(json['isha'] as String),
      );

  @override
  List<Object?> get props => [date, fajr, sunrise, dhuhr, asr, maghrib, isha];
}
