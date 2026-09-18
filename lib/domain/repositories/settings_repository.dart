import '../enums/language_code.dart';
import '../models/calculation_settings_model.dart';
import '../models/location_model.dart';

/// Abstraction over persisted user preferences.
abstract class SettingsRepository {
  Future<CalculationSettings> getCalculationSettings();
  Future<void> saveCalculationSettings(CalculationSettings settings);

  Future<LanguageCode> getLanguage();
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
