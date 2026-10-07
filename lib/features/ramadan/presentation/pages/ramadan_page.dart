import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/ramadan_settings.dart';
import '../../../../injection.dart';
import '../../../../localization/app_localizations.dart';
import '../cubit/ramadan_countdown_service.dart';
import '../cubit/ramadan_cubit.dart';
import '../widgets/ramadan_countdown.dart';

/// Ramadan page: live countdown header (when active) + Sahur/Iftar reminder,
/// Hijri adjustment and card-visibility settings (spec §12).
class RamadanPage extends StatelessWidget {
  const RamadanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RamadanCubit>(
      create: (_) => getIt<RamadanCubit>()..load(),
      child: const _RamadanPageView(),
    );
  }
}

class _RamadanPageView extends StatelessWidget {
  const _RamadanPageView();

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ramadanTitle)),
      body: BlocBuilder<RamadanCubit, RamadanState>(
        builder: (context, state) {
          if (state is RamadanLoading || state is RamadanInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RamadanMissingLocation) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.ramadanNotActiveMessage,
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (state is RamadanFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.ramadanNotActiveMessage,
                    textAlign: TextAlign.center),
              ),
            );
          }
          final loaded = state as RamadanLoaded;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(context, l10n, loaded),
              const Divider(height: 32),
              _settings(context, l10n, loaded),
            ],
          );
        },
      ),
    );
  }

  Widget _header(
      BuildContext context, AppLocalizations l10n, RamadanLoaded state) {
    final theme = Theme.of(context);
    if (!state.info.isRamadan) {
      String fmt(DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.ramadanNextRamadan,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${fmt(state.info.firstDay)} – ${fmt(state.info.lastDay)}'),
              const SizedBox(height: 4),
              Text(l10n.officialDateDisclaimer,
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      );
    }
    final countdownLabel = switch (state.countdown.phase) {
      RamadanCountdownPhase.beforeImsak => l10n.ramadanUntilImsak,
      RamadanCountdownPhase.fasting => l10n.ramadanUntilIftar,
      RamadanCountdownPhase.afterIftar => l10n.tomorrowImsak,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.ramadanDayLabel} ${state.info.dayNumber}/${state.info.totalDays}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timeColumn(theme, l10n.imsakLabel, _hhmm(state.imsak)),
                _timeColumn(theme, l10n.iftarLabel, _hhmm(state.iftar)),
              ],
            ),
            const SizedBox(height: 12),
            RamadanCountdownView(
                countdown: state.countdown, label: countdownLabel),
          ],
        ),
      ),
    );
  }

  Widget _timeColumn(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text(value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _settings(
      BuildContext context, AppLocalizations l10n, RamadanLoaded state) {
    final cubit = context.read<RamadanCubit>();
    final s = state.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.ramadanSettingsTitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Sahur reminder
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.ramadanSahurReminder),
          value: s.sahurEnabled,
          onChanged: (v) =>
              cubit.updateSettings(s.copyWith(sahurEnabled: v)),
        ),
        if (s.sahurEnabled)
          _offsetDropdown(
            context,
            l10n.sahurReminderOffset,
            s.sahurOffsetMinutes,
            RamadanSettings.sahurOffsetOptions,
            (v) => cubit.updateSettings(s.copyWith(sahurOffsetMinutes: v)),
            (m) => '$m ${l10n.ramadanMinutesBefore}',
          ),
        // Iftar reminder
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.ramadanIftarReminder),
          value: s.iftarEnabled,
          onChanged: (v) =>
              cubit.updateSettings(s.copyWith(iftarEnabled: v)),
        ),
        if (s.iftarEnabled)
          _offsetDropdown(
            context,
            l10n.iftarReminderOffset,
            s.iftarOffsetMinutes,
            RamadanSettings.iftarOffsetOptions,
            (v) => cubit.updateSettings(s.copyWith(iftarOffsetMinutes: v)),
            (m) => m == 0
                ? l10n.ramadanAtIftar
                : '$m ${l10n.ramadanMinutesBefore}',
          ),
        const Divider(height: 24),
        // Hijri adjustment
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.hijriAdjustment),
          subtitle: Text(l10n.officialDateDisclaimer),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: s.hijriAdjustment > -3
                    ? () => cubit.updateSettings(s.copyWith(
                        hijriAdjustment: s.hijriAdjustment - 1))
                    : null,
              ),
              Text(
                s.hijriAdjustment > 0
                    ? '+${s.hijriAdjustment}'
                    : '${s.hijriAdjustment}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: s.hijriAdjustment < 3
                    ? () => cubit.updateSettings(s.copyWith(
                        hijriAdjustment: s.hijriAdjustment + 1))
                    : null,
              ),
            ],
          ),
        ),
        const Divider(height: 24),
        // Card visibility
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.ramadanCardVisibility),
          value: s.cardVisible,
          onChanged: (v) =>
              cubit.updateSettings(s.copyWith(cardVisible: v)),
        ),
      ],
    );
  }

  Widget _offsetDropdown(
    BuildContext context,
    String label,
    int value,
    List<int> options,
    ValueChanged<int> onChanged,
    String Function(int) formatOption,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label)),
          DropdownButton<int>(
            value: value,
            items: options
                .map((o) => DropdownMenuItem<int>(
                    value: o, child: Text(formatOption(o))))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
