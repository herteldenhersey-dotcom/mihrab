import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../localization/app_localizations.dart';

/// Quick navigation shortcuts shown on the home dashboard.
class QuickAccessRow extends StatelessWidget {
  const QuickAccessRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <({IconData icon, String label, String route})>[
      (icon: Icons.explore, label: l10n.navQibla, route: AppRoutes.qibla),
      (icon: Icons.mosque, label: l10n.navMosques, route: AppRoutes.mosques),
      (
        icon: Icons.nightlight_round,
        label: l10n.ramadanTitle,
        route: AppRoutes.ramadan
      ),
      (
        icon: Icons.calendar_today,
        label: l10n.jummahTitle,
        route: AppRoutes.jummah
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final item in items)
          Expanded(
            child: InkWell(
              onTap: () => context.push(item.route),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Icon(item.icon,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 6),
                    Text(item.label,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
