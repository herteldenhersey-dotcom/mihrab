import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../localization/app_localizations.dart';
import '../cubit/onboarding_cubit.dart';

class NotificationStep extends StatelessWidget {
  const NotificationStep({super.key});

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
              Text(l10n.onboardingNotificationTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              SwitchListTile(
                value: state.notificationsEnabled,
                onChanged: cubit.setNotificationsEnabled,
                title: Text(l10n.onboardingNotificationBody),
              ),
            ],
          ),
        );
      },
    );
  }
}
