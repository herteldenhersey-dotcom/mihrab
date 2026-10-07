import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/enums/prayer_type.dart';
import '../../../../domain/models/notification_settings_model.dart';
import '../../../../domain/repositories/notification_settings_repository.dart';

part 'settings_state.dart';

/// Cubit for the Notification Settings feature (Phase 5).
///
/// Loads [NotificationSettings] from [NotificationSettingsRepository] and
/// exposes mutations for the Settings page UI.
class SettingsCubit extends Cubit<SettingsState> {
  final NotificationSettingsRepository _notifRepo;

  SettingsCubit(this._notifRepo) : super(const SettingsInitial());

  // ── Load ────────────────────────────────────────────────────────────────

  Future<void> load() async {
    emit(const SettingsLoading());
    try {
      final settings = await _notifRepo.load();
      emit(SettingsLoaded(notificationSettings: settings));
    } catch (_) {
      emit(const SettingsError('settingsLoadError'));
    }
  }

  // ── Mutations ────────────────────────────────────────────────────────────

  /// Toggles the master notification switch.
  Future<void> setMasterEnabled(bool enabled) async {
    final current = _currentSettings;
    if (current == null) return;
    final updated = current.copyWith(masterEnabled: enabled);
    await _saveAndEmit(updated);
  }

  /// Toggles the notification enabled flag for a specific prayer.
  Future<void> setPrayerEnabled(PrayerType prayer, bool enabled) async {
    final current = _currentSettings;
    if (current == null) return;
    final config = (current.prayerConfigs[prayer] ??
            const PrayerNotificationConfig())
        .copyWith(enabled: enabled);
    final updated = current.withPrayerConfig(prayer, config);
    await _saveAndEmit(updated);
  }

  /// Toggles the adhan channel for a specific prayer.
  ///
  /// Sunrise is silently rejected (adhan not valid for sunrise).
  Future<void> setPrayerAdhanEnabled(PrayerType prayer, bool enabled) async {
    if (!prayer.isObligatory) return; // sunrise guard
    final current = _currentSettings;
    if (current == null) return;
    final config = (current.prayerConfigs[prayer] ??
            const PrayerNotificationConfig())
        .copyWith(adhanEnabled: enabled);
    final updated = current.withPrayerConfig(prayer, config);
    await _saveAndEmit(updated);
  }

  /// Sets the reminder offset (minutes before prayer) for a specific prayer.
  Future<void> setPrayerReminderOffset(
      PrayerType prayer, int offsetMinutes) async {
    final current = _currentSettings;
    if (current == null) return;
    final config = (current.prayerConfigs[prayer] ??
            const PrayerNotificationConfig())
        .copyWith(reminderOffsetMinutes: offsetMinutes.clamp(0, 60));
    final updated = current.withPrayerConfig(prayer, config);
    await _saveAndEmit(updated);
  }

  // ── Permission helpers (UI feedback only) ────────────────────────────────

  void updatePermissionStatus({
    required bool notificationGranted,
    required bool exactAlarmGranted,
    required int pendingCount,
  }) {
    if (state is SettingsLoaded) {
      emit((state as SettingsLoaded).copyWith(
        notificationPermissionGranted: notificationGranted,
        exactAlarmGranted: exactAlarmGranted,
        pendingCount: pendingCount,
      ));
    }
  }

  // ── Test notification ────────────────────────────────────────────────────

  void testNotificationSent({int secondsAhead = 5}) {
    final current = state;
    if (current is SettingsLoaded) {
      emit(SettingsTestNotificationSent(
        notificationSettings: current.notificationSettings,
        secondsAhead: secondsAhead,
        notificationPermissionGranted: current.notificationPermissionGranted,
        exactAlarmGranted: current.exactAlarmGranted,
        pendingCount: current.pendingCount,
      ));
      // Revert to SettingsLoaded after the ephemeral signal.
      emit(current);
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  NotificationSettings? get _currentSettings {
    final s = state;
    if (s is SettingsLoaded) return s.notificationSettings;
    return null;
  }

  Future<void> _saveAndEmit(NotificationSettings updated) async {
    await _notifRepo.save(updated);
    if (state is SettingsLoaded) {
      emit((state as SettingsLoaded).copyWith(
        notificationSettings: updated,
      ));
    }
  }
}
