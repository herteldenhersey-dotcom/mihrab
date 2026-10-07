import 'package:flutter/material.dart';

import '../cubit/ramadan_countdown_service.dart';

/// Displays a live HH:mm:ss countdown with a contextual label.
///
/// Pure presentation — the [countdown] is recomputed each second by
/// [RamadanCubit] (clock-based, never drifts). This widget only formats.
class RamadanCountdownView extends StatelessWidget {
  final RamadanCountdown countdown;
  final String label;

  const RamadanCountdownView({
    super.key,
    required this.countdown,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          RamadanCountdownService.format(countdown.remaining),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
