import '../../data/datasources/local/shared_prefs_settings.dart';
import '../../domain/models/notification_settings_model.dart';
import '../../domain/repositories/notification_settings_repository.dart';

/// [NotificationSettingsRepository] backed by [SharedPrefsSettings] (JSON).
///
/// Key: 'notification_settings'
/// Value: JSON-encoded [NotificationSettings]
class SharedPrefsNotificationSettingsRepository
    implements NotificationSettingsRepository {
  static const String _key = 'notification_settings';

  final SharedPrefsSettings _prefs;

  SharedPrefsNotificationSettingsRepository(this._prefs);

  @override
  Future<NotificationSettings> load() async {
    try {
      final json = _prefs.getJson(_key);
      if (json == null) return NotificationSettings.defaults();
      return NotificationSettings.fromJson(json);
    } catch (_) {
      // Corrupted or incompatible data — silently return defaults.
      return NotificationSettings.defaults();
    }
  }

  @override
  Future<void> save(NotificationSettings settings) =>
      _prefs.setJson(_key, settings.toJson());
}
