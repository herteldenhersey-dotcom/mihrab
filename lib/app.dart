import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'domain/enums/language_code.dart';
import 'localization/app_localizations.dart';
import 'localization/cubit/locale_cubit.dart';

/// Root widget of MİHRAB.
///
/// Wires up:
/// * light/dark [ThemeData],
/// * localization delegates and supported locales (tr / en / ar),
/// * the reactive locale via [LocaleCubit] (runtime language switching, RTL for
///   Arabic driven automatically by `MaterialApp.locale`),
/// * the [GoRouter] built at startup.
///
/// The [LocaleCubit] is provided here and drives `MaterialApp.locale`, so a
/// language change rebuilds the whole app (and flips Directionality for Arabic)
/// without a restart.
class MihrabApp extends StatelessWidget {
  const MihrabApp({
    super.key,
    required this.router,
    required this.localeCubit,
    this.themeMode = ThemeMode.system,
  });

  final GoRouter router;
  final LocaleCubit localeCubit;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocaleCubit>.value(
      value: localeCubit,
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            locale: localeState.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales:
                LanguageCode.values.map((c) => c.locale).toList(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
