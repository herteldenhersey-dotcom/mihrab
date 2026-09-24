import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';

/// Compact row of future-feature entry points.
///
/// Phase 4 policy (spec §28):
/// Entry points that lead to unimplemented features show a localized
/// "Coming Soon" state rather than pretending the feature works.
/// No fake screen navigation is wired up.
class QuickAccessRow extends StatelessWidget {
  const QuickAccessRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = [
      _QuickItem(
        icon: Icons.explore_outlined,
        label: l10n.homeQibla,
        comingSoon: true,
      ),
      _QuickItem(
        icon: Icons.mosque_outlined,
        label: l10n.homeNearbyMosques,
        comingSoon: true,
      ),
      _QuickItem(
        icon: Icons.nightlight_round_outlined,
        label: l10n.homeRamadan,
        comingSoon: true,
      ),
      _QuickItem(
        icon: Icons.settings_outlined,
        label: l10n.homeSettings,
        comingSoon: true,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items
          .map((item) => Expanded(child: _QuickButton(item: item)))
          .toList(),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final bool comingSoon;
  const _QuickItem({
    required this.icon,
    required this.label,
    this.comingSoon = false,
  });
}

class _QuickButton extends StatelessWidget {
  final _QuickItem item;
  const _QuickButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Semantics(
      label: item.comingSoon
          ? '${item.label} — ${l10n.homeComingSoon}'
          : item.label,
      button: true,
      child: Tooltip(
        message: item.comingSoon ? l10n.homeComingSoon : item.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: item.comingSoon
              ? () => _showComingSoon(context, item.label)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: AlignmentDirectional.topEnd,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item.icon,
                        size: 24,
                        color: cs.onSurface.withOpacity(
                            item.comingSoon ? 0.40 : 0.85),
                      ),
                    ),
                    if (item.comingSoon)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsetsDirectional.only(
                            end: 4, top: 4),
                        decoration: BoxDecoration(
                          color: cs.outline.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(
                        item.comingSoon ? 0.45 : 0.80),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — ${l10n.homeComingSoon}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
