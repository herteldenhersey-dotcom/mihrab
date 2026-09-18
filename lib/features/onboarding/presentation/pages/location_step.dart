import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';

class LocationStep extends StatelessWidget {
  const LocationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingLocationTitle,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(l10n.onboardingLocationBody,
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
