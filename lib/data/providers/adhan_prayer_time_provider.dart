import 'package:adhan/adhan.dart' as adhan;

import '../../domain/enums/asr_calculation_method.dart';
import '../../domain/enums/prayer_calculation_method.dart';
import '../../domain/models/prayer_times_model.dart';
import '../../domain/providers/prayer_time_provider.dart';

/// Offline prayer-time provider backed by the `adhan` package (Dart port of
/// the battle-tested Adhan JS library).
///
/// Turkey/Diyanet is mapped to `CalculationMethod.turkey`, which the `adhan`
/// package configures as: Fajr 18°, Isha 17°, with method adjustments
/// (sunrise -7, dhuhr +5, asr +4, maghrib +7 minutes). Any residual delta vs.
/// the official Diyanet timetable is reconciled via [ManualOffsets] at the
/// usecase layer — see `adhan_prayer_time_provider_test.dart`.
class AdhanPrayerTimeProvider implements PrayerTimeProvider {
  const AdhanPrayerTimeProvider();

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerCalculationMethod method,
    required AsrCalculationMethod asrMethod,
  }) async {
    final coordinates = adhan.Coordinates(latitude, longitude);
    final dateComponents =
        adhan.DateComponents(date.year, date.month, date.day);

    final params = _mapMethod(method).getParameters()
      ..madhab = _mapMadhab(asrMethod);

    final pt = adhan.PrayerTimes(coordinates, dateComponents, params);

    return DailyPrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      fajr: pt.fajr,
      sunrise: pt.sunrise,
      dhuhr: pt.dhuhr,
      asr: pt.asr,
      maghrib: pt.maghrib,
      isha: pt.isha,
    );
  }

  @override
  double getQiblaDirection({
    required double latitude,
    required double longitude,
  }) {
    return adhan.Qibla(adhan.Coordinates(latitude, longitude)).direction;
  }

  /// Maps the domain calculation method to the `adhan` package enum.
  adhan.CalculationMethod _mapMethod(PrayerCalculationMethod method) {
    switch (method) {
      case PrayerCalculationMethod.diyanet:
        return adhan.CalculationMethod.turkey;
      case PrayerCalculationMethod.mwl:
        return adhan.CalculationMethod.muslim_world_league;
      case PrayerCalculationMethod.isna:
      case PrayerCalculationMethod.northAmerica:
        return adhan.CalculationMethod.north_america;
      case PrayerCalculationMethod.egypt:
        return adhan.CalculationMethod.egyptian;
      case PrayerCalculationMethod.karachi:
        return adhan.CalculationMethod.karachi;
      case PrayerCalculationMethod.ummAlQura:
        return adhan.CalculationMethod.umm_al_qura;
      case PrayerCalculationMethod.kuwait:
        return adhan.CalculationMethod.kuwait;
      case PrayerCalculationMethod.qatar:
        return adhan.CalculationMethod.qatar;
      case PrayerCalculationMethod.singapore:
        return adhan.CalculationMethod.singapore;
      case PrayerCalculationMethod.tehran:
        return adhan.CalculationMethod.tehran;
    }
  }

  adhan.Madhab _mapMadhab(AsrCalculationMethod asrMethod) {
    switch (asrMethod) {
      case AsrCalculationMethod.standard:
        return adhan.Madhab.shafi;
      case AsrCalculationMethod.hanafi:
        return adhan.Madhab.hanafi;
    }
  }
}
