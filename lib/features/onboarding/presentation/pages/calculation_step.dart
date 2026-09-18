import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/enums/prayer_calculation_method.dart';
import '../../../../localization/app_localizations.dart';
import '../cubit/onboarding_cubit.dart';

class CalculationStep extends StatelessWidget {
  const CalculationStep({super.key});

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
              Text(l10n.onboardingCalculationTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(l10n.onboardingCalculationBody,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              DropdownButtonFormField<PrayerCalculationMethod>(
                initialValue: state.method,
                items: [
                  for (final m in PrayerCalculationMethod.values)
                    DropdownMenuItem(value: m, child: Text(m.name)),
                ],
                onChanged: (v) => v != null ? cubit.setMethod(v) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
