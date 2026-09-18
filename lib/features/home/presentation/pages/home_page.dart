import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_list.dart';
import '../widgets/quick_access_row.dart';

/// Home dashboard. Phase 1 wires the layout with skeleton widgets; live data
/// binding lands in Phase 2.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          NextPrayerCard(),
          SizedBox(height: 8),
          Card(child: Padding(padding: EdgeInsets.all(8), child: QuickAccessRow())),
          SizedBox(height: 8),
          PrayerList(),
        ],
      ),
    );
  }
}
