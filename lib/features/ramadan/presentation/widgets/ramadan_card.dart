import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../injection.dart';
import '../../../../localization/app_localizations.dart';
import '../cubit/ramadan_countdown_service.dart';
import '../cubit/ramadan_cubit.dart';
import 'ramadan_countdown.dart';

/// Home-screen Ramadan card.
///
/// Self-contained: creates its own [RamadanCubit] from the DI container so the
/// existing Home widget tree does not need to provide it. During Ramadan it
/// shows the day counter, Imsak/Iftar and a live countdown; outside Ramadan it
/// shows a compact estimate of the next Ramadan (clearly labelled as an
/// estimate — never an official date, spec §3).
///
/// Honours [RamadanSettings.cardVisible]: renders nothing when hidden.
class RamadanCard extends StatelessWidget {
  const RamadanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RamadanCubit>(
      create: (_) => getIt<RamadanCubit>()..load(),
      child: const _RamadanCardView(),
    );
  }
}

class _RamadanCardView extends StatelessWidget {
  const _RamadanCardView();

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RamadanCubit, RamadanState>(
      builder: (context, state) {
        if (state is! RamadanLoaded) {
          return const SizedBox.shrink();
        }
        if (!state.settings.cardVisible) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);

        return Card(
          margin: const EdgeInsets.only(top: 16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(AppRoutes.ramadan),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: state.info.isRamadan
                  ? _buildActive(context, l10n, theme, state)
                  : _buildEstimate(context, l10n, theme, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActive(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    RamadanLoaded state,
  ) {
    final countdownLabel = switch (state.countdown.phase) {
      RamadanCountdownPhase.beforeImsak => l10n.ramadanUntilImsak,
      RamadanCountdownPhase.fasting => l10n.ramadanUntilIftar,
      RamadanCountdownPhase.afterIftar => l10n.tomorrowImsak,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.nightlight_round, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.ramadanTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${l10n.ramadanDayLabel} ${state.info.dayNumber}/${state.info.totalDays}',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
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
          countdown: state.countdown,
          label: countdownLabel,
        ),
      ],
    );
  }

  Widget _buildEstimate(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    RamadanLoaded state,
  ) {
    final first = state.info.firstDay;
    final last = state.info.lastDay;
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.nightlight_outlined,
                color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.ramadanNextRamadan,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${fmt(first)} – ${fmt(last)}',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.ramadanEstimateLabel,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.officialDateDisclaimer,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _timeColumn(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text(
          value,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
