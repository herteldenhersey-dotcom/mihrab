import '../../domain/enums/language_code.dart';
import '../../domain/models/calculation_settings_model.dart';
import '../../domain/models/location_model.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/shared_prefs_settings.dart';

/// [SettingsRepository] backed by SharedPreferences (via [SharedPrefsSettings]).
///
/// Named "Hive..." per the spec's structure, but preferences are scalar and a
/// better fit for SharedPreferences; structured data (mosque cache, feedback
/// queue) lives in Hive. Kept behind the interface so the backing store is an
/// implementation detail.
class HiveSettingsRepository implements SettingsRepository {
  final SharedPrefsSettings _prefs;

  HiveSettingsRepository(this._prefs);

  static const _kCalc = 'calc_settings';
  static const _kLang = 'language';
  static const _kLocation = 'saved_location';
  static const _kNotif = 'notifications_enabled';
  static const _kOnboarding = 'onboarding_complete';
  static const _kDark = 'dark_mode';

  @override
  Future<CalculationSettings> getCalculationSettings() async {
    final json = _prefs.getJson(_kCalc);
    if (json == null) return CalculationSettings.turkeyDefault;
    return CalculationSettings.fromJson(json);
  }

  @override
  Future<void> saveCalculationSettings(CalculationSettings settings) =>
      _prefs.setJson(_kCalc, settings.toJson());

  @override
  Future<LanguageCode> getLanguage() async =>
      LanguageCode.fromCode(_prefs.getString(_kLang) ?? 'tr');

  @override
  Future<void> saveLanguage(LanguageCode language) =>
      _prefs.setString(_kLang, language.code);

  @override
  Future<AppLocation?> getSavedLocation() async {
    final json = _prefs.getJson(_kLocation);
    return json == null ? null : AppLocation.fromJson(json);
  }

  @override
  Future<void> saveLocation(AppLocation location) =>
      _prefs.setJson(_kLocation, location.toJson());

  @override
  Future<bool> getNotificationsEnabled() async =>
      _prefs.getBool(_kNotif) ?? true;

  @override
  Future<void> saveNotificationsEnabled(bool enabled) =>
      _prefs.setBool(_kNotif, enabled);

  @override
  Future<bool> getOnboardingComplete() async =>
      _prefs.getBool(_kOnboarding) ?? false;

  @override
  Future<void> saveOnboardingComplete(bool complete) =>
      _prefs.setBool(_kOnboarding, complete);

  @override
  Future<bool> getDarkMode() async => _prefs.getBool(_kDark) ?? false;

  @override
  Future<void> saveDarkMode(bool enabled) => _prefs.setBool(_kDark, enabled);
}
