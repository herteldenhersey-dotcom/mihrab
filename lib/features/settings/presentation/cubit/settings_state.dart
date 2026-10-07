part of 'settings_cubit.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no data loaded yet.
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Settings are being loaded from SharedPreferences.
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Notification settings loaded and ready for display.
class SettingsLoaded extends SettingsState {
  final NotificationSettings notificationSettings;
  final bool notificationPermissionGranted;
  final bool exactAlarmGranted;
  final int pendingCount;

  const SettingsLoaded({
    required this.notificationSettings,
    this.notificationPermissionGranted = false,
    this.exactAlarmGranted = false,
    this.pendingCount = 0,
  });

  SettingsLoaded copyWith({
    NotificationSettings? notificationSettings,
    bool? notificationPermissionGranted,
    bool? exactAlarmGranted,
    int? pendingCount,
  }) =>
      SettingsLoaded(
        notificationSettings:
            notificationSettings ?? this.notificationSettings,
        notificationPermissionGranted:
            notificationPermissionGranted ?? this.notificationPermissionGranted,
        exactAlarmGranted: exactAlarmGranted ?? this.exactAlarmGranted,
        pendingCount: pendingCount ?? this.pendingCount,
      );

  @override
  List<Object?> get props => [
        notificationSettings,
        notificationPermissionGranted,
        exactAlarmGranted,
        pendingCount,
      ];
}

/// A test notification was scheduled (ephemeral — resets to SettingsLoaded).
class SettingsTestNotificationSent extends SettingsLoaded {
  final int secondsAhead;

  const SettingsTestNotificationSent({
    required super.notificationSettings,
    required this.secondsAhead,
    super.notificationPermissionGranted,
    super.exactAlarmGranted,
    super.pendingCount,
  });

  @override
  List<Object?> get props => [...super.props, secondsAhead];
}

/// An error occurred while loading or saving settings.
class SettingsError extends SettingsState {
  final String messageKey;

  const SettingsError(this.messageKey);

  @override
  List<Object?> get props => [messageKey];
}
