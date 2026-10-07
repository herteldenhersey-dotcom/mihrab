import '../../domain/entities/ramadan_info.dart';
import '../../domain/entities/ramadan_settings.dart';
import '../../domain/repositories/ramadan_repository.dart';
import '../datasources/local/shared_prefs_settings.dart';
import '../services/hijri/hijri_calendar_service.dart';

/// [RamadanRepository] backed by [HijriCalendarService] for calendar math and
/// [SharedPrefsSettings] (JSON) for persistence.
///
/// Key: 'ramadan_settings' → JSON-encoded [RamadanSettings].
class RamadanRepositoryImpl implements RamadanRepository {
  static const String _key = 'ramadan_settings';

  final HijriCalendarService _hijri;
  final SharedPrefsSettings _prefs;

  // In-memory cache so getRamadanInfo can apply the persisted adjustment
  // synchronously without an await on every Home rebuild.
  RamadanSettings _cached = RamadanSettings.defaults;

  RamadanRepositoryImpl(this._hijri, this._prefs) {
    // Warm the cache best-effort (synchronous read of prefs JSON).
    try {
      final json = _prefs.getJson(_key);
      if (json != null) _cached = RamadanSettings.fromJson(json);
    } catch (_) {
      _cached = RamadanSettings.defaults;
    }
  }

  @override
  RamadanInfo getRamadanInfo(DateTime date, {int? adjustment}) {
    final adj = adjustment ?? _cached.hijriAdjustment;
    return _hijri.ramadanInfo(date, adjustment: adj);
  }

  @override
  Future<RamadanSettings> loadSettings() async {
    try {
      final json = _prefs.getJson(_key);
      if (json == null) {
        _cached = RamadanSettings.defaults;
        return _cached;
      }
      _cached = RamadanSettings.fromJson(json);
      return _cached;
    } catch (_) {
      _cached = RamadanSettings.defaults;
      return _cached;
    }
  }

  @override
  Future<void> saveSettings(RamadanSettings settings) async {
    _cached = settings;
    await _prefs.setJson(_key, settings.toJson());
  }
}
