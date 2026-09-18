import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection.dart';
import '../../../../localization/app_localizations.dart';
import '../cubit/location_onboarding_cubit.dart';
import '../cubit/onboarding_cubit.dart';

/// Onboarding STEP 2: location setup.
///
/// Offers two paths — "Use my location" (device GPS) and "Select manually"
/// (free-text search) — with an explicit, localized state for every permission
/// / service / error outcome. The app is NEVER blocked if GPS is unavailable:
/// manual selection is always reachable.
///
/// All device/geocoder access goes through [LocationOnboardingCubit]; this
/// widget only renders state and dispatches intents. A [BlocListener] mirrors
/// the resolved location into [OnboardingCubit] so the shell's Continue button
/// can gate on it.
class LocationStep extends StatelessWidget {
  const LocationStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocationOnboardingCubit>(
      create: (_) => LocationOnboardingCubit(
        getIt(),
        getIt(),
        getIt(),
      ),
      child: const _LocationStepView(),
    );
  }
}

class _LocationStepView extends StatefulWidget {
  const _LocationStepView();

  @override
  State<_LocationStepView> createState() => _LocationStepViewState();
}

class _LocationStepViewState extends State<_LocationStepView> {
  final TextEditingController _searchController = TextEditingController();
  bool _manualMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    final query = _searchController.text;
    context.read<LocationOnboardingCubit>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocListener<LocationOnboardingCubit, LocationOnboardingState>(
      listenWhen: (p, c) => p.resolved != c.resolved,
      listener: (context, state) {
        // Mirror the confirmed location up to the onboarding shell (drives the
        // Continue gate and the final persistence in complete()).
        context.read<OnboardingCubit>().setLocation(state.resolved);
      },
      child: BlocBuilder<LocationOnboardingCubit, LocationOnboardingState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.locationSetupTitle,
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(l10n.locationSetupSubtitle,
                    style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                if (state.resolved != null)
                  _ResolvedCard(state: state)
                else ...[
                  _RationaleCard(),
                  const SizedBox(height: 20),
                  if (!_manualMode) ...[
                    _UseMyLocationButton(state: state),
                    const SizedBox(height: 12),
                    _DeviceStatusView(state: state),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: state.isBusy
                            ? null
                            : () => setState(() => _manualMode = true),
                        icon: const Icon(Icons.edit_location_alt_outlined),
                        label: Text(l10n.locationSelectManually),
                      ),
                    ),
                  ] else
                    _ManualSearchView(
                      controller: _searchController,
                      onSearch: _runSearch,
                      onBack: () => setState(() => _manualMode = false),
                      state: state,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Localized rationale shown BEFORE any native OS permission dialog.
class _RationaleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.locationRationaleTitle,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(l10n.locationRationaleBody,
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UseMyLocationButton extends StatelessWidget {
  const _UseMyLocationButton({required this.state});
  final LocationOnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loading = state.deviceStatus == DeviceLocationStatus.loading;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        // Disabled while loading → cannot be double-triggered.
        onPressed: loading
            ? null
            : () => context.read<LocationOnboardingCubit>().useMyLocation(),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: Text(loading ? l10n.locationSearching : l10n.locationUseMyLocation),
      ),
    );
  }
}

/// Renders the explicit device-flow error/blocked states with the right action.
class _DeviceStatusView extends StatelessWidget {
  const _DeviceStatusView({required this.state});
  final LocationOnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<LocationOnboardingCubit>();

    switch (state.deviceStatus) {
      case DeviceLocationStatus.serviceDisabled:
        return _StatusMessage(
          icon: Icons.location_disabled,
          title: l10n.locationServicesDisabledTitle,
          body: l10n.locationServicesDisabledBody,
          actionLabel: l10n.openLocationSettings,
          onAction: cubit.openLocationSettings,
        );
      case DeviceLocationStatus.permissionDenied:
        return _StatusMessage(
          icon: Icons.location_off_outlined,
          title: l10n.locationPermissionDeniedTitle,
          body: l10n.locationPermissionDeniedBody,
          actionLabel: l10n.tryAgain,
          onAction: cubit.useMyLocation,
        );
      case DeviceLocationStatus.permissionPermanentlyDenied:
        return _StatusMessage(
          icon: Icons.location_off_outlined,
          title: l10n.locationPermissionPermanentlyDeniedTitle,
          body: l10n.locationPermissionPermanentlyDeniedBody,
          actionLabel: l10n.openAppSettings,
          onAction: cubit.openAppSettings,
        );
      case DeviceLocationStatus.timeout:
        return _StatusMessage(
          icon: Icons.timer_off_outlined,
          title: l10n.errorTimeout,
          body: l10n.locationTimeoutBody,
          actionLabel: l10n.tryAgain,
          onAction: cubit.useMyLocation,
        );
      case DeviceLocationStatus.failure:
        return _StatusMessage(
          icon: Icons.error_outline,
          title: l10n.errorLocation,
          body: l10n.locationErrorBody,
          actionLabel: l10n.tryAgain,
          onAction: cubit.useMyLocation,
        );
      case DeviceLocationStatus.idle:
      case DeviceLocationStatus.loading:
      case DeviceLocationStatus.success:
        return const SizedBox.shrink();
    }
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(body, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => onAction(),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Manual free-text search: field + results list, with explicit empty/error
/// states. Selecting a result confirms and persists it via the cubit.
class _ManualSearchView extends StatelessWidget {
  const _ManualSearchView({
    required this.controller,
    required this.onSearch,
    required this.onBack,
    required this.state,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onBack;
  final LocationOnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final loading = state.searchStatus == ManualSearchStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
            Expanded(
              child: Text(l10n.locationManualTitle,
                  style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: l10n.locationSearchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: loading ? null : onSearch,
                    tooltip: l10n.locationSearch,
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _SearchResults(state: state, onRetry: onSearch),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.state, required this.onRetry});
  final LocationOnboardingState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<LocationOnboardingCubit>();

    switch (state.searchStatus) {
      case ManualSearchStatus.idle:
      case ManualSearchStatus.loading:
        return const SizedBox.shrink();
      case ManualSearchStatus.empty:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(l10n.locationNoResults),
        );
      case ManualSearchStatus.error:
        return _StatusMessage(
          icon: Icons.error_outline,
          title: l10n.errorNetwork,
          body: l10n.locationErrorBody,
          actionLabel: l10n.tryAgain,
          onAction: () async => onRetry(),
        );
      case ManualSearchStatus.results:
        return Column(
          children: [
            for (final r in state.results)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(r.displayName),
                  subtitle: Text(
                    '${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}',
                  ),
                  onTap: () => cubit.selectResult(r),
                ),
              ),
          ],
        );
    }
  }
}

/// Confirmation card shown once a location is resolved (GPS or manual).
class _ResolvedCard extends StatelessWidget {
  const _ResolvedCard({required this.state});
  final LocationOnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final loc = state.resolved!;
    final hasAddress = (loc.city?.trim().isNotEmpty ?? false) ||
        (loc.district?.trim().isNotEmpty ?? false) ||
        (loc.country?.trim().isNotEmpty ?? false);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.locationFound, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(loc.displayName, style: theme.textTheme.bodyLarge),
            if (!hasAddress) ...[
              const SizedBox(height: 4),
              Text(
                l10n.locationUsingCoordinates,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () =>
                    context.read<LocationOnboardingCubit>().reset(),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.locationChange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
