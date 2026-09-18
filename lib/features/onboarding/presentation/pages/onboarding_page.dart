import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../injection.dart';
import '../../../../localization/app_localizations.dart';
import '../cubit/onboarding_cubit.dart';
import 'calculation_step.dart';
import 'language_step.dart';
import 'location_step.dart';
import 'notification_step.dart';

/// Onboarding shell: a 4-step controller (language → location → notifications
/// → calculation) backed by [OnboardingCubit].
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(getIt<SettingsRepository>()),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<OnboardingCubit>();

    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (p, c) => c.completed && !p.completed,
      listener: (context, state) {
        if (state.completed) {
          context.go(AppRoutes.home);
        }
      },
      builder: (context, state) {
        const steps = [
          LanguageStep(),
          LocationStep(),
          NotificationStep(),
          CalculationStep(),
        ];
        final isLast = state.step == OnboardingCubit.totalSteps - 1;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _ProgressBar(step: state.step),
                Expanded(
                  child: IndexedStack(
                    index: state.step,
                    children: steps,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (state.step > 0)
                        TextButton(
                          onPressed: cubit.previousStep,
                          child: Text(l10n.skip),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () =>
                            isLast ? cubit.complete() : cubit.nextStep(),
                        child: Text(isLast ? l10n.finish : l10n.continueLabel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LinearProgressIndicator(
        value: (step + 1) / OnboardingCubit.totalSteps,
        borderRadius: BorderRadius.circular(8),
        minHeight: 6,
      ),
    );
  }
}
