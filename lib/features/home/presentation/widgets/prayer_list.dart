import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';

/// Skeleton list of the day's six prayer times (Phase 2 populates it).
class PrayerList extends StatelessWidget {
  const PrayerList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final names = [
      l10n.prayerFajr,
      l10n.prayerSunrise,
      l10n.prayerDhuhr,
      l10n.prayerAsr,
      l10n.prayerMaghrib,
      l10n.prayerIsha,
    ];
    return Card(
      child: Column(
        children: [
          for (final name in names)
            ListTile(
              title: Text(name),
              trailing: const Text('--:--'),
            ),
        ],
      ),
    );
  }
}
