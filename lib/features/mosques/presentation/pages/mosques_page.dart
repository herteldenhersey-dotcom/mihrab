import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';

/// Mosques page — Phase 1 skeleton (placeholder only).
class MosquesPage extends StatelessWidget {
  const MosquesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMosques)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.phase1Placeholder,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
