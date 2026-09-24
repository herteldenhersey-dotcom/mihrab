import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/prayer_time_utils.dart';
import '../../../../domain/enums/prayer_type.dart';
import '../../../../localization/app_localizations.dart';

/// Hero card displaying the next obligatory prayer and live countdown.
///
/// Design principles:
/// - Countdown is prominent, readable at a glance
/// - Prayer name is large and localized
/// - "Tomorrow" label shown when next prayer crosses midnight
/// - Accessible: Semantics label combines all information
/// - RTL-aware via AlignmentDirectional and EdgeInsetsDirectional
class NextPrayerCard extends StatelessWidget {
  final PrayerType prayerType;
  final DateTime prayerTime;
  final Duration countdown;
  final bool isTomorrow;
  final String timezoneId;

  const NextPrayerCard({
    super.key,
    required this.prayerType,
    required this.prayerTime,
    required this.countdown,
    required this.isTomorrow,
    required this.timezoneId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final prayerName = _prayerName(l10n, prayerType);
    final timeStr = _formatTime(prayerTime);
    final countdownStr = PrayerTimeUtils.formatCountdown(countdown);

    final bg = isDark ? cs.primaryContainer : AppColors.primary;
    final onBg = isDark ? cs.onPrimaryContainer : Colors.white;

    return Semantics(
      label: '${l10n.homeNextPrayer}: $prayerName, $timeStr. '
          '${l10n.homeTimeRemaining}: $countdownStr'
          '${isTomorrow ? " (${l10n.homeTomorrow})" : ""}',
      excludeSemantics: true,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.homeNextPrayer,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: onBg.withOpacity(0.75),
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (isTomorrow)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: onBg.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.homeTomorrow,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: onBg.withOpacity(0.85),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Prayer name + time ─────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      prayerName,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: onBg,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Text(
                    timeStr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onBg.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Countdown ──────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: onBg.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.homeTimeRemaining,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: onBg.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                countdownStr,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: onBg,
                  fontWeight: FontWeight.w300,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _prayerName(AppLocalizations l10n, PrayerType type) {
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
