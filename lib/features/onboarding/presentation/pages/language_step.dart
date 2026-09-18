import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/enums/language_code.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../localization/cubit/locale_cubit.dart';
import '../cubit/onboarding_cubit.dart';

/// First onboarding step: language selection.
///
/// Selecting a language calls [LocaleCubit.changeLocale] immediately, so the
/// entire UI (including this screen and its text direction for Arabic) updates
/// live with no app restart. The choice is also recorded in [OnboardingCubit]
/// so it persists when onboarding completes.
class LanguageStep extends StatelessWidget {
  const LanguageStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onboarding = context.read<OnboardingCubit>();
    final localeCubit = context.read<LocaleCubit>();

    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, localeState) {
        return Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.onboardingLanguageTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingLanguageSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              RadioGroup<LanguageCode>(
                groupValue: localeState.language,
                onChanged: (v) {
                  if (v == null) return;
                  // Live UI change + persist.
                  localeCubit.changeLocale(v);
                  onboarding.setLanguage(v);
                },
                child: Column(
                  children: [
                    for (final lang in LanguageCode.values)
                      Card(
                        margin: const EdgeInsetsDirectional.only(bottom: 12),
                        child: RadioListTile<LanguageCode>(
                          value: lang,
                          title: Text(_nativeLabel(lang)),
                          secondary: Text(
                            _flag(lang),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Native language names are intentionally NOT localized — each option shows
  /// its own language so users can recognise it regardless of current locale.
  String _nativeLabel(LanguageCode code) {
    switch (code) {
      case LanguageCode.tr:
        return 'Türkçe';
      case LanguageCode.en:
        return 'English';
      case LanguageCode.ar:
        return 'العربية';
    }
  }

  String _flag(LanguageCode code) {
    switch (code) {
      case LanguageCode.tr:
        return '🇹🇷';
      case LanguageCode.en:
        return '🇬🇧';
      case LanguageCode.ar:
        return '🇸🇦';
    }
  }
}
