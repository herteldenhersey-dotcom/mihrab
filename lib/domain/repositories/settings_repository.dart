import '../enums/language_code.dart';
import '../models/calculation_settings_model.dart';
import '../models/location_model.dart';

/// Abstraction over persisted user preferences.
abstract class SettingsRepository {
  Future<CalculationSettings> getCalculationSettings();
  Future<void> saveCalculationSettings(CalculationSettings settings);

  Future<LanguageCode> getLanguage();

  /// The explicitly-saved language, or `null` if the user has never chosen one
  /// (fresh install). Lets callers apply device-locale detection instead of a
  /// hardcoded default. [getLanguage] keeps returning a non-null fallback.
  Future<LanguageCode?> getStoredLanguage();

  Future<void> saveLanguage(LanguageCode language);

  Future<AppLocation?> getSavedLocation();
  Future<void> saveLocation(AppLocation location);

  Future<bool> getNotificationsEnabled();
  Future<void> saveNotificationsEnabled(bool enabled);

  Future<bool> getOnboardingComplete();
  Future<void> saveOnboardingComplete(bool complete);

  Future<bool> getDarkMode();
  Future<void> saveDarkMode(bool enabled);
}
