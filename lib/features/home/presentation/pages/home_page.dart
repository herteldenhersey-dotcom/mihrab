import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/prayer_time_utils.dart';
import '../../../../localization/app_localizations.dart';
import '../cubit/home_cubit.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_list.dart';
import '../widgets/quick_access_row.dart';

/// Production Home screen — the central destination of MİHRAB.
///
/// Layout hierarchy (spec §18):
/// ┌─────────────────────────────────────────┐
/// │ MİHRAB header  |  location  |  dates    │  ← AppBar-style header
/// │─────────────────────────────────────────│
/// │           NEXT PRAYER HERO CARD          │
/// │─────────────────────────────────────────│
/// │         TODAY'S PRAYER TIMES LIST        │
/// │─────────────────────────────────────────│
/// │         QUICK ACCESS ROW                 │
/// └─────────────────────────────────────────┘
///
/// States handled:
/// • HomeInitial / HomeLoading → loading indicator
/// • HomeLoaded               → full UI + live countdown
/// • HomeMissingLocation      → prompt with "Set Location" action
/// • HomeFailure              → error message + retry
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<HomeCubit>().load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeCubit>().onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return switch (state) {
            HomeInitial() || HomeLoading() => _buildLoading(context),
            HomeLoaded s => _buildLoaded(context, s),
            HomeMissingLocation() => _buildMissingLocation(context),
            HomeFailure s => _buildFailure(context, s.message),
          };
        },
      ),
    );
  }

  // ── Loading ─────────────────────────────────────────────────────────────
  Widget _buildLoading(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            l10n.homeLoading,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loaded ──────────────────────────────────────────────────────────────
  Widget _buildLoaded(BuildContext context, HomeLoaded state) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final currentPrayer =
        PrayerTimeUtils.getCurrentPrayer(state.today, state.locationNow);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<HomeCubit>().refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── App-bar style header ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            floating: true,
            snap: true,
            pinned: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarBrightness: theme.brightness == Brightness.dark
                  ? Brightness.dark
                  : Brightness.light,
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _HomeHeader(state: state, l10n: l10n),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 4),

                // ── Next prayer hero card ────────────────────────────
                NextPrayerCard(
                  prayerType: state.nextPrayer.type,
                  prayerTime: state.nextPrayer.time,
                  countdown: state.countdown,
                  isTomorrow: state.nextPrayer.isTomorrow,
                  timezoneId: state.timezoneId,
                ),

                const SizedBox(height: 24),

                // ── Prayer times section ─────────────────────────────
                Text(
                  l10n.homePrayerTimes,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.55),
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: cs.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: cs.outline.withOpacity(0.12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: PrayerList(
                      today: state.today,
                      currentPrayer: currentPrayer,
                      nextPrayerType: state.nextPrayer.type,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Quick access ─────────────────────────────────────
                Text(
                  l10n.homeComingSoon,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.40),
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const QuickAccessRow(),

                // ── Bottom safe area ─────────────────────────────────
                SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + 16,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Missing location ─────────────────────────────────────────────────────
  Widget _buildMissingLocation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.homeErrorMissingLocation,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.location_on_outlined),
              label: Text(l10n.homeSetLocation),
              onPressed: () => context.go(AppRoutes.locationSetup),
            ),
          ],
        ),
      ),
    );
  }

  // ── Failure ─────────────────────────────────────────────────────────────
  Widget _buildFailure(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final displayMsg = switch (message) {
      'homeTimezoneUnavailable' => l10n.homeErrorTimezone,
      'homePrayerCalcError' => l10n.homeErrorPrayerCalc,
      _ => l10n.homeErrorPrayerCalc,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              displayMsg,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.homeRetry),
              onPressed: () => context.read<HomeCubit>().refresh(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header widget ────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final HomeLoaded state;
  final AppLocalizations l10n;

  const _HomeHeader({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ── Brand name ─────────────────────────────────────────────────
          Text(
            'MİHRAB',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 4),

          // ── Location ────────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: cs.onSurface.withOpacity(0.55),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  state.location.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Dates ────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  state.gregorianFormatted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                state.hijriFormatted,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
