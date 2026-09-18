import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'domain/enums/language_code.dart';
import 'localization/app_localizations.dart';

/// Root widget of MİHRAB.
///
/// Wires up:
/// * light/dark [ThemeData] (system-driven via [ThemeMode.system]),
/// * localization delegates and supported locales (tr / en / ar),
/// * the [GoRouter] built at startup.
///
/// [locale] and [themeMode] are provided at construction time from persisted
/// settings; Phase 2 will make these reactive through a settings cubit.
class MihrabApp extends StatelessWidget {
  const MihrabApp({
    super.key,
    required this.router,
    this.locale,
    this.themeMode = ThemeMode.system,
  });

  final GoRouter router;
  final Locale? locale;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: LanguageCode.values.map((c) => c.locale).toList(),
      routerConfig: router,
    );
  }
}
