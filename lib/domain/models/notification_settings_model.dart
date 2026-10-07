import 'package:equatable/equatable.dart';

import '../enums/prayer_type.dart';

/// Per-prayer notification configuration.
///
/// [enabled]               – should a notification fire for this prayer?
/// [adhanEnabled]          – use the adhan sound channel instead of the plain
///                           silent-alarm channel?  (placeholder in Phase 5)
/// [reminderOffsetMinutes] – fire the notification this many minutes BEFORE
///                           the prayer time.  Negative values are not used;
///                           0 means "at prayer time".
class PrayerNotificationConfig extends Equatable {
  final bool enabled;
  final bool adhanEnabled;
  final int reminderOffsetMinutes;

  const PrayerNotificationConfig({
    this.enabled = true,
    this.adhanEnabled = false,
    this.reminderOffsetMinutes = 0,
  });

  PrayerNotificationConfig copyWith({
    bool? enabled,
    bool? adhanEnabled,
    int? reminderOffsetMinutes,
  }) =>
      PrayerNotificationConfig(
        enabled: enabled ?? this.enabled,
        adhanEnabled: adhanEnabled ?? this.adhanEnabled,
        reminderOffsetMinutes:
            reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'adhanEnabled': adhanEnabled,
        'reminderOffsetMinutes': reminderOffsetMinutes,
      };

  factory PrayerNotificationConfig.fromJson(Map<String, dynamic> json) =>
      PrayerNotificationConfig(
        enabled: json['enabled'] as bool? ?? true,
        adhanEnabled: json['adhanEnabled'] as bool? ?? false,
        reminderOffsetMinutes: json['reminderOffsetMinutes'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [enabled, adhanEnabled, reminderOffsetMinutes];
}

/// App-wide notification preferences.
///
/// [masterEnabled]  – global on/off.  When false, NO notification fires even
///                    if a per-prayer config is enabled.
/// [prayerConfigs]  – keyed by [PrayerType].  Sunrise is persisted but is
///                    NEVER scheduled as an obligatory adhan (it may have an
///                    informational notification in a future phase).
class NotificationSettings extends Equatable {
  final bool masterEnabled;
  final Map<PrayerType, PrayerNotificationConfig> prayerConfigs;

  const NotificationSettings({
    this.masterEnabled = true,
    Map<PrayerType, PrayerNotificationConfig>? prayerConfigs,
  }) : prayerConfigs = prayerConfigs ?? const {};

  /// Factory that creates defaults: master on, all obligatory prayers
  /// enabled with adhan off and 0-minute offset.
  factory NotificationSettings.defaults() {
    final configs = <PrayerType, PrayerNotificationConfig>{};
    for (final p in PrayerType.values) {
      configs[p] = PrayerNotificationConfig(
        enabled: p.isObligatory, // sunrise off by default
        adhanEnabled: false,
        reminderOffsetMinutes: 0,
      );
    }
    return NotificationSettings(masterEnabled: true, prayerConfigs: configs);
  }

  NotificationSettings copyWith({
    bool? masterEnabled,
    Map<PrayerType, PrayerNotificationConfig>? prayerConfigs,
  }) =>
      NotificationSettings(
        masterEnabled: masterEnabled ?? this.masterEnabled,
        prayerConfigs: prayerConfigs ?? Map.unmodifiable(this.prayerConfigs),
      );

  NotificationSettings withPrayerConfig(
          PrayerType prayer, PrayerNotificationConfig config) =>
      copyWith(
        prayerConfigs: {...prayerConfigs, prayer: config},
      );

  /// Resolved set of prayers that should receive notifications.
  ///
  /// Returns empty when [masterEnabled] is false.  Sunrise is ALWAYS excluded
  /// as an obligatory adhan source regardless of its config entry.
  Set<PrayerType> get effectiveEnabledPrayers {
    if (!masterEnabled) return {};
    return prayerConfigs.entries
        .where((e) => e.value.enabled && e.key.isObligatory)
        .map((e) => e.key)
        .toSet();
  }

  Map<String, dynamic> toJson() => {
        'masterEnabled': masterEnabled,
        'prayerConfigs': prayerConfigs.map(
          (k, v) => MapEntry(k.key, v.toJson()),
        ),
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final configsJson =
        json['prayerConfigs'] as Map<String, dynamic>? ?? {};
    final configs = <PrayerType, PrayerNotificationConfig>{};
    for (final p in PrayerType.values) {
      final raw = configsJson[p.key];
      if (raw != null) {
        configs[p] =
            PrayerNotificationConfig.fromJson(raw as Map<String, dynamic>);
      } else {
        configs[p] = PrayerNotificationConfig(
          enabled: p.isObligatory,
        );
      }
    }
    return NotificationSettings(
      masterEnabled: json['masterEnabled'] as bool? ?? true,
      prayerConfigs: configs,
    );
  }

  @override
  List<Object?> get props => [masterEnabled, prayerConfigs];
}
