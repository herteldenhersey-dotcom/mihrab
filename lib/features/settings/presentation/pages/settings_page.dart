import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/notification/alarm_permission_service.dart';
import '../../../../data/services/notification/notification_service.dart';
import '../../../../domain/enums/prayer_type.dart';
import '../../../../domain/models/notification_settings_model.dart';
import '../../../../injection.dart';
import '../../../../localization/app_localizations.dart';
import '../cubit/settings_cubit.dart';

/// Full notification settings page (Phase 5).
///
/// Provides:
/// - Master notification switch
/// - Per-prayer notification + adhan toggle + reminder offset
/// - Permission status + request buttons
/// - Test notification
/// - Diagnostics (pending count)
/// - Platform notes (iOS rolling window, adhan placeholder)
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load settings when page is first displayed.
    context.read<SettingsCubit>().load();
    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final cubit = context.read<SettingsCubit>();
    final alarmSvc = getIt<AlarmPermissionService>();
    final notifSvc = getIt<NotificationService>();

    final exactAlarm = await alarmSvc.canScheduleExactAlarms();
    final pending = await notifSvc.pendingCount();

    if (mounted) {
      cubit.updatePermissionStatus(
        notificationGranted: true, // conservative default
        exactAlarmGranted: exactAlarm,
        pendingCount: pending,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settingsNotificationsTitle),
          ),
          body: switch (state) {
            SettingsInitial() || SettingsLoading() =>
              const Center(child: CircularProgressIndicator()),
            SettingsError(:final messageKey) => _buildError(messageKey, l10n),
            SettingsLoaded(:final notificationSettings,
                :final notificationPermissionGranted,
                :final exactAlarmGranted,
                :final pendingCount) =>
              _buildContent(
                context,
                l10n,
                notificationSettings,
                notificationPermissionGranted,
                exactAlarmGranted,
                pendingCount,
              ),
          },
        );
      },
    );
  }

  Widget _buildError(String key, AppLocalizations l10n) {
    return Center(child: Text(key, style: const TextStyle(color: AppColors.error)));
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    NotificationSettings settings,
    bool notifGranted,
    bool exactAlarm,
    int pendingCount,
  ) {
    final cubit = context.read<SettingsCubit>();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ── Master switch ──────────────────────────────────────────────────
        _SectionHeader(l10n.settingsNotifications),
        SwitchListTile(
          title: Text(l10n.settingsNotificationsMasterSwitch),
          subtitle: Text(
            settings.masterEnabled
                ? l10n.settingsNotificationsEnabled
                : l10n.settingsNotificationsMasterSwitchOff,
          ),
          value: settings.masterEnabled,
          onChanged: (v) => cubit.setMasterEnabled(v),
          activeThumbColor: AppColors.primary,
        ),

        const Divider(),

        // ── Per-prayer ─────────────────────────────────────────────────────
        _SectionHeader(l10n.settingsNotificationsPerPrayer),
        ...PrayerType.values
            .where((p) => p.isObligatory)
            .map((prayer) => _PrayerTile(
                  prayer: prayer,
                  l10n: l10n,
                  settings: settings,
                  masterEnabled: settings.masterEnabled,
                  onEnabled: (v) => cubit.setPrayerEnabled(prayer, v),
                  onAdhan: (v) => cubit.setPrayerAdhanEnabled(prayer, v),
                  onOffset: (v) =>
                      cubit.setPrayerReminderOffset(prayer, v),
                )),

        const Divider(),

        // ── Permissions ────────────────────────────────────────────────────
        _SectionHeader(l10n.settingsPermissionStatus),
        ListTile(
          leading: Icon(
            notifGranted ? Icons.notifications_active : Icons.notifications_off,
            color: notifGranted ? AppColors.primary : AppColors.error,
          ),
          title: Text(l10n.settingsPermissionStatus),
          subtitle: Text(notifGranted
              ? l10n.settingsPermissionGranted
              : l10n.settingsPermissionDenied),
          trailing: notifGranted
              ? null
              : TextButton(
                  onPressed: () async {
                    final svc = getIt<NotificationService>();
                    final granted = await svc.requestPermission();
                    if (mounted) {
                      cubit.updatePermissionStatus(
                        notificationGranted: granted,
                        exactAlarmGranted: exactAlarm,
                        pendingCount: pendingCount,
                      );
                    }
                  },
                  child: Text(l10n.settingsPermissionRequest),
                ),
        ),

        if (Platform.isAndroid) ...[
          ListTile(
            leading: Icon(
              exactAlarm ? Icons.alarm_on : Icons.alarm_off,
              color: exactAlarm ? AppColors.primary : AppColors.warning,
            ),
            title: Text(l10n.settingsExactAlarmStatus),
            subtitle: Text(exactAlarm
                ? l10n.settingsExactAlarmGranted
                : l10n.settingsExactAlarmDenied),
            trailing: exactAlarm
                ? null
                : TextButton(
                    onPressed: () async {
                      final svc = getIt<AlarmPermissionService>();
                      await svc.requestExactAlarmPermission();
                      await _refreshPermissions();
                    },
                    child: Text(l10n.settingsExactAlarmRequest),
                  ),
          ),
        ],

        const Divider(),

        // ── Diagnostics ────────────────────────────────────────────────────
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.settingsPendingCount(pendingCount)),
        ),

        // ── Test notification ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FilledButton.icon(
            icon: const Icon(Icons.send_rounded),
            label: Text(l10n.settingsTestNotification),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () async {
              const seconds = 5;
              final notifSvc = getIt<NotificationService>();
              // Capture ScaffoldMessenger before the async gap to satisfy
              // use_build_context_synchronously lint rule.
              final messenger = ScaffoldMessenger.of(context);
              final sentMsg = l10n.settingsTestNotificationSent(seconds);
              await notifSvc.sendTestNotification(
                title: l10n.settingsTestNotificationTitle,
                body: l10n.settingsTestNotificationBody,
                secondsAhead: seconds,
              );
              cubit.testNotificationSent(secondsAhead: seconds);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(sentMsg)),
                );
              }
            },
          ),
        ),

        const Divider(),

        // ── Platform notes ─────────────────────────────────────────────────
        if (Platform.isIOS)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.settingsIosRollingWindowNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            l10n.settingsAdhanPlaceholderNote,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.warning),
          ),
        ),

        if (!notifGranted)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              l10n.settingsNotificationPermissionDeniedWarning,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  final PrayerType prayer;
  final AppLocalizations l10n;
  final NotificationSettings settings;
  final bool masterEnabled;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<bool> onAdhan;
  final ValueChanged<int> onOffset;

  const _PrayerTile({
    required this.prayer,
    required this.l10n,
    required this.settings,
    required this.masterEnabled,
    required this.onEnabled,
    required this.onAdhan,
    required this.onOffset,
  });

  String _prayerName() {
    return switch (prayer) {
      PrayerType.fajr => l10n.prayerFajr,
      PrayerType.sunrise => l10n.prayerSunrise,
      PrayerType.dhuhr => l10n.prayerDhuhr,
      PrayerType.asr => l10n.prayerAsr,
      PrayerType.maghrib => l10n.prayerMaghrib,
      PrayerType.isha => l10n.prayerIsha,
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = settings.prayerConfigs[prayer] ??
        const PrayerNotificationConfig();
    final isActive = masterEnabled && config.enabled;

    // Offset choices: 0, 5, 10, 15, 20, 30 minutes.
    final offsetChoices = [0, 5, 10, 15, 20, 30];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          isActive ? Icons.notifications : Icons.notifications_off_outlined,
          color: isActive ? AppColors.primary : Colors.grey,
        ),
        title: Text(_prayerName()),
        subtitle: Text(
          config.enabled
              ? (config.reminderOffsetMinutes > 0
                  ? l10n.settingsReminderOffsetMinutes(
                      config.reminderOffsetMinutes)
                  : l10n.settingsReminderOffsetAtTime)
              : l10n.settingsNotificationsDisabled,
          style: TextStyle(
            color: config.enabled ? null : Colors.grey,
          ),
        ),
        children: [
          // Enable / Disable notification
          SwitchListTile(
            title: Text(l10n.settingsNotificationsEnabled),
            value: config.enabled,
            onChanged: masterEnabled ? onEnabled : null,
            activeThumbColor: AppColors.primary,
          ),

          // Adhan sound toggle (only for obligatory)
          SwitchListTile(
            title: Text(l10n.settingsAdhanEnabled),
            subtitle: Text(l10n.settingsAdhanPlaceholderNote,
                style: const TextStyle(fontSize: 11)),
            value: config.adhanEnabled,
            onChanged: (masterEnabled && config.enabled) ? onAdhan : null,
            activeThumbColor: AppColors.accent,
          ),

          // Reminder offset
          ListTile(
            title: Text(l10n.settingsReminderOffset),
            trailing: DropdownButton<int>(
              value: config.reminderOffsetMinutes,
              items: offsetChoices
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m == 0
                            ? l10n.settingsReminderOffsetAtTime
                            : l10n.settingsReminderOffsetMinutes(m)),
                      ))
                  .toList(),
              onChanged: (masterEnabled && config.enabled)
                  ? (v) => onOffset(v ?? 0)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
