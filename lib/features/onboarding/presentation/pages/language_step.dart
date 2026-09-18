import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/enums/language_code.dart';
import '../../../../localization/app_localizations.dart';
import '../cubit/onboarding_cubit.dart';

class LanguageStep extends StatelessWidget {
  const LanguageStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<OnboardingCubit>();
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.onboardingLanguageTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              RadioGroup<LanguageCode>(
                groupValue: state.language,
                onChanged: (v) {
                  if (v != null) cubit.setLanguage(v);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final lang in LanguageCode.values)
                      RadioListTile<LanguageCode>(
                        value: lang,
                        title: Text(_label(lang)),
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

  String _label(LanguageCode code) {
    switch (code) {
      case LanguageCode.tr:
        return 'Türkçe';
      case LanguageCode.en:
        return 'English';
      case LanguageCode.ar:
        return 'العربية';
    }
  }
}
