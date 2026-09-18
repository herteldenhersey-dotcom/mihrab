import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';

/// Skeleton card that will show the next prayer + live countdown (Phase 2).
class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.nextPrayer,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('—',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(color: scheme.primary)),
            const SizedBox(height: 4),
            Text(l10n.phase1Placeholder,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
