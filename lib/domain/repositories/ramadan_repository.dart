import '../entities/ramadan_info.dart';
import '../entities/ramadan_settings.dart';

/// Abstraction over Ramadan calendar + settings (spec §3, §12).
///
/// Keeping this as an interface lets the Hijri calculation engine be swapped
/// (e.g. an online Diyanet calendar) without touching the presentation layer.
abstract class RamadanRepository {
  /// Computes Ramadan info for [date] (civil wall-clock date of the selected
  /// location), applying the persisted/overridden Hijri [adjustment].
  RamadanInfo getRamadanInfo(DateTime date, {int? adjustment});

  /// Loads persisted Ramadan settings (defaults when none saved).
  Future<RamadanSettings> loadSettings();

  /// Persists Ramadan settings locally.
  Future<void> saveSettings(RamadanSettings settings);
}
