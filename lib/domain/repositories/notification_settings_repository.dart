import '../models/notification_settings_model.dart';

/// Domain contract for persisting and loading [NotificationSettings].
abstract class NotificationSettingsRepository {
  /// Loads the saved settings, or [NotificationSettings.defaults()] if none.
  Future<NotificationSettings> load();

  /// Persists the given [settings].
  Future<void> save(NotificationSettings settings);
}
