import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/enums/prayer_type.dart';
import '../../../../domain/models/prayer_times_model.dart';
import '../../../../localization/app_localizations.dart';

/// Displays the six daily prayer entries (Fajr → Isha) with visual
/// distinction for the next prayer and a special treatment for Sunrise.
///
/// Design decisions:
/// • Next prayer row gets a teal left border + subtle background tint.
/// • Sunrise row is visually subdued and carries a small label indicating
///   it is not an obligatory prayer — avoids misleading the user.
/// • All spacing uses EdgeInsetsDirectional / AlignmentDirectional for RTL.
class PrayerList extends StatelessWidget {
  final DailyPrayerTimes today;
  final PrayerType? currentPrayer;
  final PrayerType nextPrayerType;

  const PrayerList({
    super.key,
    required this.today,
    required this.currentPrayer,
    required this.nextPrayerType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      children: today.ordered.map((entry) {
        return _PrayerRow(
          prayerType: entry.key,
          time: entry.value,
          isNext: entry.key == nextPrayerType,
          isCurrent: entry.key == currentPrayer,
          l10n: l10n,
          theme: theme,
        );
      }).toList(),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final PrayerType prayerType;
  final DateTime time;
  final bool isNext;
  final bool isCurrent;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _PrayerRow({
    required this.prayerType,
    required this.time,
    required this.isNext,
    required this.isCurrent,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final isSunrise = prayerType == PrayerType.sunrise;

    Color? rowBg;
    Color? borderColor;
    if (isNext) {
      rowBg = cs.primaryContainer.withOpacity(0.18);
      borderColor = AppColors.primary;
    }

    return Semantics(
      label: '${_name(l10n, prayerType)}: ${_formatTime(time)}'
          '${isSunrise ? " (${l10n.homeSunriseNote})" : ""}'
          '${isNext ? " — ${l10n.homeNextPrayer}" : ""}',
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          border: isNext
              ? BorderDirectional(
                  start: BorderSide(color: borderColor!, width: 3),
                )
              : null,
          borderRadius: isNext ? BorderRadius.circular(4) : null,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 16, 12),
          child: Row(
            children: [
              // ── Icon ────────────────────────────────────────────────
              _PrayerIcon(
                type: prayerType,
                isNext: isNext,
                isSunrise: isSunrise,
                cs: cs,
              ),
              const SizedBox(width: 14),

              // ── Name + optional sunrise note ─────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name(l10n, prayerType),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isNext ? FontWeight.w600 : FontWeight.w400,
                        color: isSunrise && !isNext
                            ? cs.onSurface.withOpacity(0.55)
                            : cs.onSurface,
                      ),
                    ),
                    if (isSunrise)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          l10n.homeSunriseNote,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Time ────────────────────────────────────────────────
              Text(
                _formatTime(time),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isSunrise && !isNext
                      ? cs.onSurface.withOpacity(0.50)
                      : cs.onSurface,
                ),
              ),

              // ── "Next" chip ──────────────────────────────────────────
              if (isNext) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    '›',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _name(AppLocalizations l10n, PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return l10n.homePrayerFajr;
      case PrayerType.sunrise:
        return l10n.homePrayerSunrise;
      case PrayerType.dhuhr:
        return l10n.homePrayerDhuhr;
      case PrayerType.asr:
        return l10n.homePrayerAsr;
      case PrayerType.maghrib:
        return l10n.homePrayerMaghrib;
      case PrayerType.isha:
        return l10n.homePrayerIsha;
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _PrayerIcon extends StatelessWidget {
  final PrayerType type;
  final bool isNext;
  final bool isSunrise;
  final ColorScheme cs;

  const _PrayerIcon({
    required this.type,
    required this.isNext,
    required this.isSunrise,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final color = isNext
        ? AppColors.primary
        : isSunrise
            ? cs.onSurface.withOpacity(0.40)
            : cs.onSurface.withOpacity(0.65);

    return SizedBox(
      width: 28,
      height: 28,
      child: Icon(
        _icon(type),
        size: 20,
        color: color,
      ),
    );
  }

  IconData _icon(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return Icons.bedtime_outlined;
      case PrayerType.sunrise:
        return Icons.wb_twilight_outlined;
      case PrayerType.dhuhr:
        return Icons.wb_sunny_outlined;
      case PrayerType.asr:
        return Icons.wb_cloudy_outlined;
      case PrayerType.maghrib:
        return Icons.nights_stay_outlined;
      case PrayerType.isha:
        return Icons.dark_mode_outlined;
    }
  }
}
