import 'package:mihrab/domain/enums/language_code.dart';
import 'package:mihrab/domain/models/calculation_settings_model.dart';
import 'package:mihrab/domain/models/location_model.dart';
import 'package:mihrab/domain/repositories/settings_repository.dart';

/// Full in-memory [SettingsRepository] fake for tests — no SharedPreferences,
/// no platform channels. Records everything written so tests can assert
/// persistence.
class FakeSettingsRepository implements SettingsRepository {
  CalculationSettings _calc = CalculationSettings.turkeyDefault;
  LanguageCode? _language;
  AppLocation? _location;
  bool _notifications = true;
  bool _onboardingComplete = false;
  bool _darkMode = false;

  /// Number of times [saveLocation] was called (guards idempotency tests).
  int saveLocationCount = 0;

  @override
  Future<CalculationSettings> getCalculationSettings() async => _calc;

  @override
  Future<void> saveCalculationSettings(CalculationSettings settings) async =>
      _calc = settings;

  @override
  Future<LanguageCode> getLanguage() async => _language ?? LanguageCode.tr;

  @override
  Future<LanguageCode?> getStoredLanguage() async => _language;

  @override
  Future<void> saveLanguage(LanguageCode language) async =>
      _language = language;

  @override
  Future<AppLocation?> getSavedLocation() async => _location;

  @override
  Future<void> saveLocation(AppLocation location) async {
    saveLocationCount++;
    _location = location;
  }

  @override
  Future<bool> getNotificationsEnabled() async => _notifications;

  @override
  Future<void> saveNotificationsEnabled(bool enabled) async =>
      _notifications = enabled;

  @override
  Future<bool> getOnboardingComplete() async => _onboardingComplete;

  @override
  Future<void> saveOnboardingComplete(bool complete) async =>
      _onboardingComplete = complete;

  @override
  Future<bool> getDarkMode() async => _darkMode;

  @override
  Future<void> saveDarkMode(bool enabled) async => _darkMode = enabled;
}
